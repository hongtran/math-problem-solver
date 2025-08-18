from fastapi import FastAPI, File, UploadFile, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
import base64
import io
from PIL import Image
from openai import OpenAI
from typing import Optional
import firebase_admin
from firebase_admin import credentials, auth, firestore
from pydantic import BaseModel
import json
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="Math Problem Solver API",
    description="AI-powered math homework solver using OpenAI and Firebase",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your Flutter app domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
try:
    # Get Firebase credentials from environment variables
    firebase_config = {
        "type": os.getenv("FIREBASE_TYPE", "service_account"),
        "project_id": os.getenv("FIREBASE_PROJECT_ID"),
        "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
        "private_key": os.getenv("FIREBASE_PRIVATE_KEY", "").replace('\\n', '\n'),
        "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
        "client_id": os.getenv("FIREBASE_CLIENT_ID"),
        "auth_uri": os.getenv("FIREBASE_AUTH_URI", "https://accounts.google.com/o/oauth2/auth"),
        "token_uri": os.getenv("FIREBASE_TOKEN_URI", "https://oauth2.googleapis.com/token"),
        "auth_provider_x509_cert_url": os.getenv("FIREBASE_AUTH_PROVIDER_X509_CERT_URL", "https://www.googleapis.com/oauth2/v1/certs"),
        "client_x509_cert_url": os.getenv("FIREBASE_CLIENT_X509_CERT_URL")
    }
    
    # Check if required Firebase environment variables are set
    required_vars = ["FIREBASE_PROJECT_ID", "FIREBASE_PRIVATE_KEY", "FIREBASE_CLIENT_EMAIL"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"Missing required Firebase environment variables: {missing_vars}")
        print("Firebase will be disabled. Set these variables to enable Firebase functionality.")
        db = None
    else:
        cred = credentials.Certificate(firebase_config)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Firebase initialized successfully")
        
except Exception as e:
    print(f"Firebase initialization error: {e}")
    db = None
    # Continue without Firebase for development

# OpenAI configuration
api_key = os.getenv("OPENAI_API_KEY")
client = OpenAI(api_key=api_key)

class MathProblemRequest(BaseModel):
    image_base64: str
    user_id: Optional[str] = None
    problem_description: Optional[str] = None

class MathProblemResponse(BaseModel):
    solution: str
    steps: list[str]
    answer: str
    confidence: float
    processing_time: float

@app.get("/")
async def root():
    return {"message": "Math Problem Solver API is running!"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/solve-math-problem", response_model=MathProblemResponse)
async def solve_math_problem(request: MathProblemRequest):
    """
    Solve a math problem from an uploaded image using OpenAI's vision capabilities
    """
    try:
        start_time = datetime.now()
        
        # Decode base64 image
        image_data = base64.b64decode(request.image_base64)
        image = Image.open(io.BytesIO(image_data))
        
        # Convert image to base64 for OpenAI API
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode()
        # Prepare prompt for OpenAI
        system_prompt = """You are an expert mathematics tutor."""
        
        # Call OpenAI API with vision
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Please solve this math problem."
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{img_base64}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=1000,
            temperature=0.3
        )
        
        # Parse OpenAI response
        solution_text = response.choices[0].message.content
        # Extract solution components (simplified parsing)
        steps = solution_text.split('\n\n') if '\n\n' in solution_text else [solution_text]
        answer = steps[-1] if steps else solution_text
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds()
        
        # Save to Firebase if available
        if request.user_id and db is not None:
            try:
                problem_data = {
                    "user_id": request.user_id,
                    "timestamp": datetime.now(),
                    "problem_description": request.problem_description,
                    "solution": solution_text,
                    "steps": steps,
                    "processing_time": processing_time
                }
                db.collection("math_problems").add(problem_data)
            except Exception as e:
                print(f"Firebase save error: {e}")
        
        return MathProblemResponse(
            solution=solution_text,
            steps=steps,
            answer=answer,
            confidence=0.85,  # Placeholder confidence score
            processing_time=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error solving math problem: {str(e)}")

@app.post("/upload-image")
async def upload_image(file: UploadFile = File(...)):
    """
    Alternative endpoint for direct file upload
    """
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Read and process image
        image_data = await file.read()
        image = Image.open(io.BytesIO(image_data))
        
        # Convert to base64
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_base64 = base64.b64encode(buffered.getvalue()).decode()
        
        return {"image_base64": img_base64, "filename": file.filename}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")

@app.get("/user-problems/{user_id}")
async def get_user_problems(user_id: str):
    """
    Retrieve math problems solved by a specific user
    """
    try:
        if db is None:
            return {"message": "Firebase not configured", "problems": []}
        
        problems = db.collection("math_problems").where("user_id", "==", user_id).order_by("timestamp", direction=firestore.Query.DESCENDING).limit(20).stream()
        
        problem_list = []
        for problem in problems:
            problem_data = problem.to_dict()
            problem_data["id"] = problem.id
            problem_list.append(problem_data)
        
        return {"problems": problem_list}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving problems: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 
