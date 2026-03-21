"""
Safe math verification tool for the Fact-Checker agent.
Runs equation verification in a subprocess with timeout; no arbitrary code execution.
"""

import json
import subprocess
import sys

VERIFY_SCRIPT = """
import json
import math
import sys

def main():
    data = json.load(sys.stdin)
    equation_expression = data["equation_expression"]
    variable = data["variable"]
    proposed_value_str = data["proposed_value"]

    try:
        if "." in proposed_value_str:
            value = float(proposed_value_str)
        else:
            try:
                value = int(proposed_value_str)
            except ValueError:
                value = float(proposed_value_str)
    except (ValueError, TypeError) as e:
        print(json.dumps({
            "verified": False,
            "message": f"Could not parse proposed value: {e}"
        }))
        return

    restricted_globals = {"math": math, "__builtins__": {}}
    restricted_globals[variable] = value

    try:
        result = eval(equation_expression, restricted_globals)
    except Exception as e:
        print(json.dumps({
            "verified": False,
            "message": f"Error evaluating expression: {e}"
        }))
        return

    if isinstance(result, (int, float)):
        verified = abs(result) < 1e-9
    else:
        verified = bool(result)

    print(json.dumps({
        "verified": verified,
        "message": "Equation satisfied." if verified else "Equation not satisfied."
    }))

if __name__ == "__main__":
    main()
"""

TIMEOUT_SECONDS = 5


def run_verify_solution(
    equation_expression: str,
    variable: str,
    proposed_value: str,
) -> dict:
    """
    Verify that plugging proposed_value into the equation satisfies it
    (expression evaluates to zero or True within tolerance).
    Runs in a subprocess with timeout; returns {"verified": bool, "message": str}.
    """
    if not equation_expression or not variable or not proposed_value:
        return {
            "verified": False,
            "message": "Missing equation_expression, variable, or proposed_value.",
        }

    payload = {
        "equation_expression": equation_expression,
        "variable": variable,
        "proposed_value": str(proposed_value).strip(),
    }
    try:
        result = subprocess.run(
            [sys.executable, "-c", VERIFY_SCRIPT],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return {"verified": False, "message": "Verification timed out."}

    if result.returncode != 0:
        stderr = result.stderr or "Unknown error"
        return {"verified": False, "message": f"Verification failed: {stderr[:200]}"}

    try:
        out = json.loads(result.stdout.strip())
        return {"verified": bool(out.get("verified", False)), "message": out.get("message", "")}
    except (json.JSONDecodeError, TypeError):
        return {"verified": False, "message": "Invalid verification output."}
