"""Pydantic request/response models for the HTTP API."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, model_validator

VerificationStatus = Literal["verified", "failed", "unverified"]


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
    verified: bool | None = Field(
        default=None,
        description=(
            "True only if an automated mathematical check passed. False if a check ran and failed. "
            "None if verification was disabled, or no reliable automated check ran (see verification_status)."
        ),
    )
    verification_status: VerificationStatus | None = Field(
        default=None,
        description='Outcome of verification: "verified", "failed", or "unverified". None when use_verification is false.',
    )
    verification_method: str | None = Field(
        default=None,
        description="How verification was done, e.g. sympy_substitute, numeric_plugin, skipped_non_algebraic.",
    )
    verification_message: str | None = Field(
        default=None,
        description="Detail from the verification layer (SymPy, numeric fallback, or skip reason).",
    )
    verification_critique: str | None = Field(
        default=None,
        description="Optional second-pass LLM consistency note when verification was unverified (if enabled via env).",
    )
    correction_note: str | None = None
