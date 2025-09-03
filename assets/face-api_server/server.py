from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64, cv2, numpy as np, re, os, logging

from deepface import DeepFace
from deepface.detectors import FaceDetector

import firebase_admin
from firebase_admin import credentials, auth

# -------------------------------
# Logging Setup
# -------------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("face-api")

# -------------------------------
# Request Model
# -------------------------------
class Images(BaseModel):
    img1: str  # profile image data:image/jpeg;base64,...
    img2: str  # login image data:image/jpeg;base64,...
    filename: str  # profile_UID.jpg format

# -------------------------------
# FastAPI app
# -------------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------
# Firebase Initialization
# -------------------------------
try:
    cred = credentials.Certificate("firebase-service-account.json")
    firebase_admin.initialize_app(cred)
    logger.info("✅ Firebase Admin initialized successfully")
except Exception as e:
    logger.error(f"❌ Firebase initialization failed: {e}")
    raise

# -------------------------------
# DeepFace Detector (load once)
# -------------------------------
DETECTOR_BACKEND = "mtcnn"  # change to "retinaface" for stronger accuracy
face_detector = FaceDetector.build_model(DETECTOR_BACKEND)
logger.info(f"✅ Face detector loaded: {DETECTOR_BACKEND}")

# -------------------------------
# Helpers
# -------------------------------
def extract_uid_from_filename(filename: str) -> str:
    """Extract UID from filename profile_UID.jpg"""
    base_filename = os.path.basename(filename)
    match = re.match(r'profile_(.+)\.jpg$', base_filename)
    if not match:
        raise ValueError(f"Invalid filename format. Expected 'profile_UID.jpg', got '{base_filename}'")
    return match.group(1)

def b64_to_rgb_array(data_url: str):
    """Convert base64 image to RGB numpy array"""
    if data_url.startswith('data:image/'):
        _, b64data = data_url.split(",", 1)
    else:
        b64data = data_url

    raw = base64.b64decode(b64data)
    arr = np.frombuffer(raw, np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)

    if bgr is None:
        raise ValueError("Could not decode image - invalid image data")

    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)

def validate_faces(image: np.ndarray, detector_backend: str = DETECTOR_BACKEND) -> None:
    """Ensure exactly one face is present in the image"""
    faces = FaceDetector.detect_faces(face_detector, detector_backend, image, align=False)
    if len(faces) == 0:
        raise ValueError("No face detected in the image")
    elif len(faces) > 1:
        raise ValueError(f"Multiple faces detected ({len(faces)})")

def create_firebase_token(uid: str, verification_data: dict = None) -> str:
    """Create Firebase custom token with optional verification claims"""
    try:
        auth.get_user(uid)  # verify user exists
    except auth.UserNotFoundError:
        logger.warning(f"⚠️ UID {uid} not found in Firebase Auth, continuing...")
    except Exception as e:
        raise Exception(f"Error verifying user: {e}")

    claims = {"authMethod": "face_recognition"}
    if verification_data:
        claims.update({
            "verification_distance": verification_data.get("distance", 0.0),
            "verification_model": verification_data.get("model", "unknown")
        })

    try:
        token = auth.create_custom_token(uid, developer_claims=claims)
    except Exception as e:
        logger.error(f"❌ Token creation with claims failed: {e}, falling back")
        token = auth.create_custom_token(uid)

    return token.decode("utf-8") if isinstance(token, bytes) else str(token)

# -------------------------------
# Routes
# -------------------------------
@app.post("/verify")
async def verify(images: Images):
    logger.info("🔍 New verification request")

    try:
        uid = extract_uid_from_filename(images.filename)
        img1 = b64_to_rgb_array(images.img1)
        img2 = b64_to_rgb_array(images.img2)

        # ✅ Ensure only one face in each
        validate_faces(img1)
        validate_faces(img2)

    except Exception as e:
        logger.error(f"❌ Request validation failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))

    try:
        result = DeepFace.verify(
            img1_path=img1,  # numpy arrays allowed
            img2_path=img2,
            model_name="Facenet512",
            detector_backend=DETECTOR_BACKEND,
            enforce_detection=False  # we already validated
        )
        logger.info(f"📊 DeepFace: verified={result['verified']} distance={result['distance']:.4f}")
    except Exception as e:
        logger.error(f"❌ DeepFace error: {e}")
        raise HTTPException(status_code=500, detail=f"DeepFace error: {e}")

    custom_token = None
    if bool(result["verified"]):
        try:
            verification_data = {
                "distance": float(result["distance"]),
                "model": result.get("model", "unknown")
            }
            custom_token = create_firebase_token(uid, verification_data)
        except Exception as e:
            logger.error(f"❌ Firebase token generation failed: {e}")
            raise HTTPException(status_code=500, detail=str(e))

    return {
        "verified": bool(result["verified"]),
        "distance": float(result["distance"]),
        "model": result.get("model", "unknown"),
        "uid": uid,
        "customToken": custom_token
    }

@app.get("/health")
async def health():
    return {
        "status": "OK",
        "message": "Face verification API with Firebase tokens",
        "firebase_sdk_version": firebase_admin.__version__
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
