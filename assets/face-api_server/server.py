from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import base64, cv2, numpy as np, tempfile
from deepface import DeepFace

class Images(BaseModel):
    img1: str  # data:image/jpeg;base64,...
    img2: str

app = FastAPI()

# allow all origins for dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def b64_to_rgb_array(data_url: str):
    # strip off header if present
    header, b64data = data_url.split(",", 1) if "," in data_url else (None, data_url)
    raw = base64.b64decode(b64data)
    arr = np.frombuffer(raw, np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError("Could not decode image")
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)

@app.post("/verify")
async def verify(images: Images):
    try:
        img1 = b64_to_rgb_array(images.img1)
        img2 = b64_to_rgb_array(images.img2)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image data: {e}")

    # Write to temp files because DeepFace.verify expects file paths
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f1, \
         tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as f2:
        # convert back to BGR for imwrite
        cv2.imwrite(f1.name, cv2.cvtColor(img1, cv2.COLOR_RGB2BGR))
        cv2.imwrite(f2.name, cv2.cvtColor(img2, cv2.COLOR_RGB2BGR))
        
        try:
            result = DeepFace.verify(
                img1_path=f1.name,
                img2_path=f2.name,
                model_name="VGG-Face"
            )
        except Exception as e:
            print("DeepFace: ")
            print(e)
            raise HTTPException(status_code=500, detail=f"DeepFace error: {e}")

    return {
        "verified": result["verified"],
        "distance": result["distance"],
        "model": result["model"]
    }
