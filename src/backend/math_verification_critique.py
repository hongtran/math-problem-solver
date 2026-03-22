"""
Optional second-pass LLM critique when automated verification is unverified.
Enabled with MATH_VERIFICATION_CRITIQUE=1 (or true/yes).
"""

from __future__ import annotations

import json
import logging
import os

from openai import OpenAI

logger = logging.getLogger(__name__)

CRITIQUE_SYSTEM = """You review a math solution for basic consistency only. You do NOT re-solve the problem from scratch.
Rules:
- Check whether the stated answer plausibly matches the problem type and the steps shown.
- Flag clear contradictions (e.g. arithmetic errors in displayed work, answer unrelated to question).
- If you cannot tell without solving fully, say uncertain.

Respond with ONLY a JSON object:
{"assessment": "plausible" | "uncertain" | "problematic", "notes": "one or two short sentences"}"""


def critique_enabled() -> bool:
    return os.getenv("MATH_VERIFICATION_CRITIQUE", "").strip().lower() in (
        "1",
        "true",
        "yes",
        "on",
    )


def run_verification_critique(
    client: OpenAI,
    problem_text: str,
    answer: str,
    solution_excerpt: str,
    max_excerpt_chars: int = 2500,
) -> str | None:
    if not critique_enabled():
        return None
    excerpt = (solution_excerpt or "").strip()
    if len(excerpt) > max_excerpt_chars:
        excerpt = excerpt[:max_excerpt_chars] + "…"

    user = json.dumps(
        {
            "problem": (problem_text or "").strip()[:4000],
            "claimed_answer": (answer or "").strip()[:500],
            "solution_excerpt": excerpt,
        },
        ensure_ascii=False,
    )

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": CRITIQUE_SYSTEM},
                {"role": "user", "content": user},
            ],
            max_tokens=300,
            temperature=0.2,
            response_format={"type": "json_object"},
        )
        raw = (response.choices[0].message.content or "").strip()
        data = json.loads(raw)
        assessment = data.get("assessment", "uncertain")
        notes = data.get("notes", "")
        return f"[{assessment}] {notes}".strip()
    except Exception:
        logger.exception("verification critique LLM call failed")
        return None
