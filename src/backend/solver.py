"""Core math solving logic (blocking); run from async routes via asyncio.to_thread."""

from __future__ import annotations

import logging
from datetime import datetime
from typing import Any

from image_utils import normalize_base64_image_to_png_base64
from math_agent import run_math_agent_langgraph
from math_response_format import (
    SYSTEM_JSON_SOLVER_PROMPT,
    parse_solution_with_text_fallback,
)
from math_verification_critique import run_verification_critique
from openai import OpenAI
from schemas import MathProblemRequest, MathProblemResponse

logger = logging.getLogger(__name__)


def _persist_problem(
    db: Any,
    request: MathProblemRequest,
    problem_text: str,
    steps: list[str],
    processing_time: float,
    verified: bool | None,
    verification_status: str | None = None,
) -> None:
    if not request.user_email or db is None:
        return
    try:
        problem_data = {
            "user_email": request.user_email,
            "timestamp": datetime.now(),
            "problem_description": problem_text or request.problem_description,
            "steps": steps,
            "processing_time": processing_time,
        }
        if request.image_base64:
            problem_data["image_base64"] = request.image_base64
        if request.use_verification:
            problem_data["verified"] = verified
            if verification_status is not None:
                problem_data["verification_status"] = verification_status
        db.collection("math_problems").add(problem_data)
    except Exception:
        logger.exception("Firebase save failed")


def solve_math_problem_sync(
    request: MathProblemRequest,
    client: OpenAI,
    db: Any,
) -> MathProblemResponse:
    start_time = datetime.now()

    img_base64 = normalize_base64_image_to_png_base64(request.image_base64)
    problem_text = (request.problem_text or request.problem_description or "").strip()

    verification_status: str | None = None
    verification_method: str | None = None
    verification_message: str | None = None
    verification_critique: str | None = None

    if request.use_verification:
        image_url = f"data:image/png;base64,{img_base64}" if img_base64 else None
        (
            solution_text,
            steps,
            answer,
            verified,
            correction_note,
            verification_status,
            verification_method,
            verification_message,
        ) = run_math_agent_langgraph(
            image_url=image_url,
            problem_text=problem_text if problem_text else None,
        )

        if verification_status == "unverified":
            verification_critique = run_verification_critique(
                client,
                problem_text,
                answer,
                solution_text,
            )
        if verified is True:
            if verification_method and verification_method.startswith("sympy"):
                confidence = 0.97
            elif verification_method == "numeric_plugin":
                confidence = 0.91
            else:
                confidence = 0.95
        elif verified is False:
            confidence = 0.78
        else:
            confidence = 0.82
    else:
        user_json_instruction = (
            problem_text or "Please solve this math problem."
        ) + " Return your response as JSON matching the schema described in the system message."
        if img_base64:
            user_content = [
                {"type": "text", "text": user_json_instruction},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_base64}"}},
            ]
        else:
            user_content = user_json_instruction
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_JSON_SOLVER_PROMPT},
                {"role": "user", "content": user_content},
            ],
            max_tokens=1000,
            temperature=0.3,
            response_format={"type": "json_object"},
        )
        raw = (response.choices[0].message.content or "").strip()
        solution_text, steps, answer = parse_solution_with_text_fallback(raw)
        verified = None
        correction_note = None
        confidence = 0.85

    processing_time = (datetime.now() - start_time).total_seconds()
    _persist_problem(
        db,
        request,
        problem_text,
        steps,
        processing_time,
        verified,
        verification_status=verification_status if request.use_verification else None,
    )

    return MathProblemResponse(
        solution=solution_text,
        steps=steps,
        answer=answer,
        confidence=confidence,
        processing_time=processing_time,
        verified=verified if request.use_verification else None,
        verification_status=verification_status if request.use_verification else None,
        verification_method=verification_method if request.use_verification else None,
        verification_message=verification_message if request.use_verification else None,
        verification_critique=verification_critique if request.use_verification else None,
        correction_note=correction_note if request.use_verification else None,
    )


def list_user_problems_sync(db: Any, user_email: str, limit: int = 20) -> list[dict]:
    if db is None:
        return []
    from firebase_admin import firestore

    problems = (
        db.collection("math_problems")
        .where("user_email", "==", user_email)
        .order_by("timestamp", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )
    out: list[dict] = []
    for problem in problems:
        problem_data = problem.to_dict()
        problem_data["id"] = problem.id
        out.append(problem_data)
    return out
