"""
Shared structured math solution format (JSON: solution, steps, answer).
OpenAI json_object mode cannot be combined with tools in the same request; the agent
uses a follow-up LLM call without tools to coerce the final narrative into JSON.
"""

from __future__ import annotations

import json

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

# OpenAI requires the word "json" in messages when using response_format json_object.
SYSTEM_JSON_SOLVER_PROMPT = (
    "You are an expert mathematics tutor. "
    "Respond with a single valid JSON object only (no markdown). "
    "Use this exact shape: "
    '{"solution": "<full explanation as one string>", '
    '"steps": ["<step 1>", "<step 2>", ...], '
    '"answer": "<final answer>"}. '
    "The steps array should be the step-by-step breakdown."
)

SYSTEM_JSON_COERCE_PROMPT = (
    "You convert math solutions into structured JSON only. "
    "Output a single valid JSON object (no markdown). "
    "Use this exact shape: "
    '{"solution": "<full explanation as one string>", '
    '"steps": ["<step 1>", "<step 2>", ...], '
    '"answer": "<final answer>"}. '
    "Preserve all reasoning from the input in solution and steps."
)


def try_parse_structured_json(raw: str) -> tuple[str, list[str], str] | None:
    """If raw is valid JSON with solution/steps/answer, return tuple; else None."""
    if not (raw or "").strip():
        return None
    try:
        payload = json.loads(raw.strip())
        if not isinstance(payload, dict):
            return None
        solution_text = str(payload.get("solution", ""))
        steps = payload.get("steps")
        if isinstance(steps, list):
            steps = [str(s) for s in steps]
        else:
            steps = solution_text.split("\n\n") if "\n\n" in solution_text else [solution_text]
        answer = str(payload.get("answer", "")) or (steps[-1] if steps else solution_text)
        return solution_text, steps, answer
    except (json.JSONDecodeError, TypeError, KeyError):
        return None


def parse_solution_with_text_fallback(raw: str) -> tuple[str, list[str], str]:
    """Try JSON first; on failure split plain text (for responses that are not JSON)."""
    parsed = try_parse_structured_json(raw)
    if parsed is not None:
        return parsed
    solution_text = (raw or "").strip()
    steps = solution_text.split("\n\n") if "\n\n" in solution_text else [solution_text]
    answer = steps[-1] if steps else solution_text
    return solution_text, steps, answer


def coerce_narrative_to_json_solution(narrative: str) -> tuple[str, list[str], str]:
    """
    One LLM call without tools, with response_format json_object.
    Use after agent/tool flow when the final message is not already valid JSON.
    """
    narrative = (narrative or "").strip()
    if not narrative:
        return "Unable to produce a final solution.", ["Unable to produce a final solution."], ""

    formatter = ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0,
        max_tokens=2000,
        model_kwargs={"response_format": {"type": "json_object"}},
    )
    user_msg = (
        "Convert the following math solution into the JSON object described in the system message. "
        "Include every step in the steps array.\n\n"
        f"{narrative}"
    )
    response = formatter.invoke(
        [
            SystemMessage(content=SYSTEM_JSON_COERCE_PROMPT),
            HumanMessage(content=user_msg),
        ]
    )
    raw = (response.content or "").strip()
    parsed = try_parse_structured_json(raw)
    if parsed is not None:
        return parsed
    return parse_solution_with_text_fallback(raw)
