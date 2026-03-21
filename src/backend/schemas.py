"""Pydantic request/response models for the HTTP API."""

from __future__ import annotations

from pydantic import BaseModel, model_validator


class MathProblemRequest(BaseModel):
    image_base64: str | None = None
    problem_text: str | None = None
    user_email: str | None = None
    problem_description: str | None = None  # backward compatibility; prefer problem_text
    use_verification: bool = True

    @model_validator(mode="after")
    def require_image_or_text(self):
        text = (self.problem_text or "").strip() or (self.problem_description or "").strip()
        if not self.image_base64 and not text:
            raise ValueError(
                "At least one of image_base64 or problem_text (or problem_description) is required."
            )
        return self


class MathProblemResponse(BaseModel):
    solution: str
    steps: list[str]
    answer: str
    confidence: float
    processing_time: float
    verified: bool | None = None
    correction_note: str | None = None
