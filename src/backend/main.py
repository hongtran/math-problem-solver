import asyncio
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Annotated

from config import get_settings
from fastapi import FastAPI, File, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from firebase_app import get_firestore_client
from image_utils import normalize_image_bytes_to_png_base64
from openai import OpenAI
from schemas import MathProblemRequest, MathProblemResponse
from solver import list_user_problems_sync, solve_math_problem_sync

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.settings = settings
    app.state.db = get_firestore_client()
    if settings.openai_api_key:
        app.state.openai_client = OpenAI(api_key=settings.openai_api_key)
    else:
        app.state.openai_client = None
        logger.warning("OPENAI_API_KEY is not set; /solve-math-problem will return 503.")
    yield


_settings = get_settings()
app = FastAPI(
    title="Math Problem Solver API",
    description="AI-powered math homework solver using OpenAI and Firebase",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_origins,
    allow_credentials=_settings.cors_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {"message": "Math Problem Solver API is running!"}


@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


@app.post("/solve-math-problem", response_model=MathProblemResponse)
async def solve_math_problem(request: MathProblemRequest, req: Request):
    """
    Solve a math problem from an uploaded image and/or text. Provide at least one of
    image_base64 or problem_text (or problem_description). When use_verification is True (default),
    uses an agent that verifies the answer with verify_solution and re-evaluates if needed.
    """
    client = req.app.state.openai_client
    if client is None:
        raise HTTPException(status_code=503, detail="OpenAI API is not configured.")

    try:
        return await asyncio.to_thread(
            solve_math_problem_sync,
            request,
            client,
            req.app.state.db,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e
    except Exception as e:
        logger.exception("solve-math-problem failed")
        raise HTTPException(status_code=500, detail="Error solving math problem.") from e


@app.post("/upload-image")
async def upload_image(request: Request, file: Annotated[UploadFile, File()]):
    """Accept a direct image upload and return PNG base64 for use with /solve-math-problem."""
    max_bytes = request.app.state.settings.max_upload_bytes
    try:
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")

        chunk = await file.read(max_bytes + 1)
        if len(chunk) > max_bytes:
            raise HTTPException(
                status_code=413,
                detail=f"File too large (max {max_bytes // (1024 * 1024)} MB).",
            )

        img_base64 = await asyncio.to_thread(normalize_image_bytes_to_png_base64, chunk)
        return {"image_base64": img_base64, "filename": file.filename}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("upload-image failed")
        raise HTTPException(status_code=500, detail="Error processing image.") from e


@app.get("/user-problems/{user_email}")
async def get_user_problems(user_email: str, req: Request):
    """
    Retrieve recent math problems for a user (Firestore).

    Note: This endpoint is not authenticated in this template; protect it in production
    (e.g. Firebase ID token + match email claim) before exposing user data.
    """
    try:
        if req.app.state.db is None:
            return {"message": "Firebase not configured", "problems": []}

        problems = await asyncio.to_thread(list_user_problems_sync, req.app.state.db, user_email)
        return {"problems": problems}
    except Exception as e:
        logger.exception("get_user_problems failed")
        raise HTTPException(status_code=500, detail="Error retrieving problems.") from e


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
