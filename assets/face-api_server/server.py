from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64, cv2, numpy as np, tempfile
from deepface import DeepFace
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os, re
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class Images(BaseModel):
    img1: str  # profile image data:image/jpeg;base64,...
    img2: str  # login image data:image/jpeg;base64,...
    filename: str  # profile_UID.jpg format

app = FastAPI()

# Initialize Firebase Admin
try:
    cred = credentials.Certificate("firebase-service-account.json")
    firebase_admin.initialize_app(cred)
    logger.info(f"✅ Firebase Admin initialized successfully - SDK version: {firebase_admin.__version__}")
except Exception as e:
    logger.error(f"❌ Firebase initialization failed: {e}")
    raise

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def extract_uid_from_filename(filename: str) -> str:
    """Extract UID from filename with better error handling"""
    logger.info(f"📁 Processing filename: {filename}")

    base_filename = os.path.basename(filename)
    logger.info(f"📋 Base filename: {base_filename}")

    # Pattern: profile_UID.jpg
    match = re.match(r'profile_(.+)\.jpg$', base_filename)
    if not match:
        error_msg = f"Invalid filename format. Expected 'profile_UID.jpg', got '{base_filename}'"
        logger.error(f"❌ {error_msg}")
        raise ValueError(error_msg)

    uid = match.group(1)
    logger.info(f"✅ Extracted UID: {uid}")
    return uid

def b64_to_rgb_array(data_url: str):
    """Convert base64 image to RGB array with better error handling"""
    try:
        if data_url.startswith('data:image/'):
            header, b64data = data_url.split(",", 1)
        else:
            b64data = data_url

        raw = base64.b64decode(b64data)
        arr = np.frombuffer(raw, np.uint8)
        bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)

        if bgr is None:
            raise ValueError("Could not decode image - invalid image data")

        rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        logger.info(f"✅ Image decoded successfully - shape: {rgb.shape}")
        return rgb

    except Exception as e:
        logger.error(f"❌ Image decoding failed: {e}")
        raise ValueError(f"Image decoding error: {e}")

def create_firebase_token(uid: str, verification_data: dict = None) -> str:
    """
    Create Firebase custom token using developer_claims parameter (SDK 7.1.0)
    """
    logger.info(f"🔑 Creating Firebase token for UID: {uid}")

    try:
        # First, verify the user exists
        user_record = auth.get_user(uid)
        logger.info(f"✅ Firebase user found: {user_record.email}")
    except auth.UserNotFoundError:
        logger.warning(f"⚠️ UID {uid} not found in Firebase Auth, but proceeding with token generation")
    except Exception as e:
        logger.error(f"❌ Error verifying user: {e}")
        raise

    try:
        # Use developer_claims parameter (correct for SDK 7.1.0)
        developer_claims = {
            "authMethod": "face_recognition"
        }

        if verification_data:
            developer_claims.update({
                "verification_distance": verification_data.get("distance", 0.0),
                "verification_model": verification_data.get("model", "unknown")
            })

        custom_token = auth.create_custom_token(
            uid=uid,
            developer_claims=developer_claims
        )
        logger.info("✅ Token created using developer_claims parameter")

    except Exception as e:
        logger.error(f"❌ Token creation failed: {e}")
        logger.info("🔄 Falling back to basic token generation...")

        # Fallback: Basic token without claims
        try:
            custom_token = auth.create_custom_token(uid)
            logger.info("✅ Basic token created successfully")
        except Exception as e2:
            logger.error(f"❌ Basic token creation also failed: {e2}")
            raise Exception(f"All token creation methods failed: {e2}")

    # Convert bytes to string if necessary
    if isinstance(custom_token, bytes):
        token_str = custom_token.decode('utf-8')
    else:
        token_str = str(custom_token)

    logger.info(f"✅ Custom token generated successfully (length: {len(token_str)})")
    logger.info(f"🔑 Token preview: {token_str[:50]}...")

    return token_str

@app.post("/verify")
async def verify(images: Images):
    logger.info("🔍 Starting face verification request")
    logger.info(f"📋 Request data - filename: {images.filename}")

    try:
        # Extract UID from filename
        uid = extract_uid_from_filename(images.filename)
        logger.info(f"👤 Processing verification for UID: {uid}")

        # Convert images
        img1 = b64_to_rgb_array(images.img1)
        img2 = b64_to_rgb_array(images.img2)

    except Exception as e:
        error_msg = f"Invalid request data: {e}"
        logger.error(f"❌ {error_msg}")
        raise HTTPException(status_code=400, detail=error_msg)

    # Create temporary files for DeepFace
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f1, \
         tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f2:

        try:
            # Save images
            cv2.imwrite(f1.name, cv2.cvtColor(img1, cv2.COLOR_RGB2BGR))
            cv2.imwrite(f2.name, cv2.cvtColor(img2, cv2.COLOR_RGB2BGR))
            logger.info(f"💾 Saved temp images: {f1.name}, {f2.name}")

            # Run DeepFace verification
            logger.info("🔬 Running DeepFace verification...")
            result = DeepFace.verify(
                img1_path=f1.name,
                img2_path=f2.name,
                model_name="VGG-Face"
            )

#             result = DeepFace.verify(
#                 img1_path=f1.name,
#                 img2_path=f2.name,
#                 model_name="VGG-Face",
#                 distance_metric="cosine",
#                 enforce_detection=False
#             )
            logger.info(f"📊 DeepFace result: verified={result['verified']}, distance={result['distance']}")

        except Exception as e:
            error_msg = f"DeepFace verification error: {e}"
            logger.error(f"❌ {error_msg}")
            raise HTTPException(status_code=500, detail=error_msg)
        finally:
            # Clean up temp files
            try:
                os.unlink(f1.name)
                os.unlink(f2.name)
                logger.info("🧹 Cleaned up temporary files")
            except:
                pass

    custom_token = None

    # If faces match, generate Firebase custom token
    if bool(result["verified"]):
        try:
            verification_data = {
                "distance": float(result["distance"]),
                "model": result["model"]
            }
            custom_token = create_firebase_token(uid, verification_data)

        except Exception as e:
            error_msg = f"Firebase token generation error: {e}"
            logger.error(f"❌ {error_msg}")
            raise HTTPException(status_code=500, detail=error_msg)
    else:
        logger.info("❌ Faces did not match - no token generated")

    response_data = {
        "verified": bool(result["verified"]),
        "distance": float(result["distance"]),
        "model": result["model"],
        "uid": uid,
        "customToken": custom_token
    }

    logger.info(f"📤 Sending response: verified={response_data['verified']}, uid={uid}, has_token={custom_token is not None}")
    return response_data

@app.get("/health")
async def health():
    return {
        "status": "OK",
        "message": "Face verification API with Firebase tokens",
        "firebase_sdk_version": firebase_admin.__version__
    }

@app.get("/test/{uid}")
async def test_token_generation(uid: str):
    """Test endpoint to verify token generation works for a specific UID"""
    try:
        logger.info(f"🧪 Testing token generation for UID: {uid}")

        # Check if user exists
        user_record = auth.get_user(uid)
        logger.info(f"✅ User found: {user_record.email}")

        # Generate token using our compatible function
        custom_token = create_firebase_token(uid)

        return {
            "uid": uid,
            "email": user_record.email,
            "token_length": len(custom_token),
            "token_preview": custom_token[:50] + "...",
            "firebase_sdk_version": firebase_admin.__version__,
            "status": "success"
        }
    except Exception as e:
        logger.error(f"❌ Test failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)