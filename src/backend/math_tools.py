"""
Layered math verification: SymPy symbolic checks in a subprocess (timeout),
with numeric plug-in fallback; explicit non-algebraic / skip paths.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

TIMEOUT_SECONDS = 8

_WORKER = Path(__file__).resolve().parent / "_verify_worker.py"


def run_verify_solution(
    equation_expression: str,
    variable: str,
    proposed_value: str,
    additional_answers: str = "",
    problem_kind: str = "algebraic_equation",
) -> dict:
    """
    Verify proposed value(s) against an equation.

    Returns:
        verified: True only if an automated check succeeded.
        status: "verified" | "failed" | "unverified"
        method: e.g. sympy_substitute, sympy_multi, numeric_plugin, skipped_non_algebraic
        message: human-readable detail

    Semantics:
        - status "verified": check ran and passed.
        - status "failed": check ran and did not pass (wrong candidate).
        - status "unverified": no reliable automated check (problem type, parse error, etc.).
    """
    payload = {
        "equation_expression": equation_expression or "",
        "variable": (variable or "").strip(),
        "proposed_value": str(proposed_value).strip() if proposed_value else "",
        "additional_answers": str(additional_answers or "").strip(),
        "problem_kind": (problem_kind or "algebraic_equation").strip(),
    }

    if not _WORKER.is_file():
        return {
            "verified": False,
            "status": "unverified",
            "method": "none",
            "message": "Verification worker is missing from deployment.",
        }

    try:
        result = subprocess.run(
            [sys.executable, str(_WORKER)],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return {
            "verified": False,
            "status": "unverified",
            "method": "none",
            "message": "Verification timed out.",
        }

    if result.returncode != 0:
        stderr = result.stderr or "Unknown error"
        return {
            "verified": False,
            "status": "unverified",
            "method": "none",
            "message": f"Verification process failed: {stderr[:200]}",
        }

    try:
        out = json.loads((result.stdout or "").strip())
    except (json.JSONDecodeError, TypeError):
        return {
            "verified": False,
            "status": "unverified",
            "method": "none",
            "message": "Invalid verification output.",
        }

    status = out.get("status", "unverified")
    if status not in ("verified", "failed", "unverified"):
        status = "unverified"

    return {
        "verified": bool(out.get("verified", False)) and status == "verified",
        "status": status,
        "method": str(out.get("method") or "none"),
        "message": str(out.get("message") or ""),
    }
