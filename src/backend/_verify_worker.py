"""
Subprocess entry: read JSON from stdin, write verification JSON to stdout.
Isolated from the API process for timeout and to contain parsing/eval.
"""

from __future__ import annotations

import json
import math
import re
import sys


TOL = 1e-9


def _emit(obj: dict) -> None:
    print(json.dumps(obj))
    sys.stdout.flush()


def _parse_value_list(proposed: str, additional_raw: str) -> tuple[list, str | None]:
    """Return list of parsed numeric/sympy values and error message if any."""
    from sympy import sympify
    from sympy.core.sympify import SympifyError

    raw_parts: list[str] = []
    proposed = (proposed or "").strip()
    if proposed:
        raw_parts.append(proposed)

    ar = (additional_raw or "").strip()
    if ar:
        if ar.startswith("["):
            try:
                decoded = json.loads(ar)
                if isinstance(decoded, list):
                    raw_parts.extend(str(x).strip() for x in decoded)
                else:
                    raw_parts.append(str(decoded))
            except json.JSONDecodeError:
                raw_parts.extend(p.strip() for p in ar.split(",") if p.strip())
        else:
            raw_parts.extend(p.strip() for p in ar.split(",") if p.strip())

    if not raw_parts:
        return [], "No proposed value(s) to verify."

    values = []
    for s in raw_parts:
        try:
            values.append(sympify(s))
        except (SympifyError, TypeError, ValueError) as e:
            return [], f"Could not parse value {s!r}: {e}"
    return values, None


def _build_sympy_expr(equation_expression: str, variable: str):
    """Parse LHS-RHS if '==' present, else whole expression as f(var)=0."""
    from sympy import Symbol
    from sympy.parsing.sympy_parser import (
        implicit_multiplication,
        parse_expr,
        standard_transformations,
    )

    eq = (equation_expression or "").strip()
    if not eq:
        return None, "Empty equation expression."

    var_sym = Symbol(variable.strip())
    transformations = standard_transformations + (implicit_multiplication,)
    from sympy import E as sympy_E
    from sympy import cos, exp, log, pi, sin, sqrt, tan

    local_dict = {
        variable.strip(): var_sym,
        "log": log,
        "ln": log,
        "exp": exp,
        "sin": sin,
        "cos": cos,
        "tan": tan,
        "sqrt": sqrt,
        "pi": pi,
        "E": sympy_E,
    }

    def _parse_side(side: str):
        return parse_expr(
            side.strip(),
            local_dict=local_dict,
            transformations=transformations,
            evaluate=True,
        )

    if "==" in eq:
        parts = eq.split("==", 1)
        if len(parts) != 2:
            return None, "Invalid equality format."
        try:
            lhs = _parse_side(parts[0])
            rhs = _parse_side(parts[1])
            return lhs - rhs, None
        except Exception as e:
            return None, f"SymPy parse (equality) failed: {e}"

    try:
        return _parse_side(eq), None
    except Exception as e:
        return None, f"SymPy parse failed: {e}"


def _residual_zero(res) -> bool:
    from sympy import N, simplify
    from sympy.logic.boolalg import BooleanFalse, BooleanTrue

    if res is True or isinstance(res, BooleanTrue):
        return True
    if res is False or isinstance(res, BooleanFalse):
        return False

    if getattr(res, "is_Relational", False):
        s = simplify(res)
        if s is True or isinstance(s, BooleanTrue):
            return True
        if s is False or isinstance(s, BooleanFalse):
            return False

    s = simplify(res)
    if s == 0:
        return True
    try:
        if s.is_number:
            c = complex(N(s))
            if abs(c.imag) < TOL and abs(c.real) < TOL:
                return True
    except (TypeError, ValueError):
        pass
    return False


def _verify_sympy(expr, var_sym, values: list) -> tuple[bool, str]:
    from sympy import simplify

    for v in values:
        try:
            subbed = expr.subs(var_sym, v)
            subbed = simplify(subbed)
            if not _residual_zero(subbed):
                return False, f"SymPy check failed for value {v!s}: residual {subbed!s}."
        except Exception as e:
            return False, f"SymPy substitution error for {v!s}: {e}"
    return True, "Equation satisfied (symbolic check)."


def _verify_numeric_eval(
    equation_expression: str, variable: str, values: list
) -> tuple[bool, str, str]:
    """Legacy Python eval check; returns (ok, message, method_label)."""
    restricted_globals = {"math": math, "__builtins__": {}}

    eq = (equation_expression or "").strip()
    if "==" in eq:
        return (
            False,
            "Numeric fallback does not support '==' in expression; use SymPy-friendly form.",
            "numeric_plugin",
        )

    for v in values:
        if hasattr(v, "evalf"):
            try:
                num = float(v.evalf())
            except (TypeError, ValueError):
                return False, f"Numeric fallback cannot use non-real value {v!s}.", "numeric_plugin"
        else:
            try:
                num = float(v)
            except (TypeError, ValueError):
                return False, f"Numeric fallback cannot parse {v!s}.", "numeric_plugin"

        restricted_globals[variable] = num
        try:
            result = eval(eq, restricted_globals)
        except Exception as e:
            return False, f"Error evaluating expression: {e}", "numeric_plugin"

        if isinstance(result, (int, float)):
            if abs(result) >= TOL:
                return False, "Equation not satisfied (numeric plug-in).", "numeric_plugin"
        elif not bool(result):
            return False, "Equation not satisfied (numeric plug-in).", "numeric_plugin"

    return True, "Equation satisfied (numeric plug-in).", "numeric_plugin"


def main():
    data = json.load(sys.stdin)
    equation_expression = data.get("equation_expression") or ""
    variable = (data.get("variable") or "").strip()
    proposed_value = data.get("proposed_value") or ""
    additional_answers = data.get("additional_answers") or ""
    problem_kind = (data.get("problem_kind") or "algebraic_equation").strip().lower()

    base = {
        "verified": False,
        "status": "failed",
        "method": "none",
        "message": "",
    }

    if problem_kind in ("non_algebraic", "proof", "geometry", "word_problem", "inequality_chain"):
        base.update(
            {
                "status": "unverified",
                "method": "skipped_non_algebraic",
                "message": (
                    "Automatic symbolic/numeric verification was not applied for this problem type. "
                    "Review the reasoning manually."
                ),
            }
        )
        _emit(base)
        return

    if not variable:
        base.update(
            {
                "status": "unverified",
                "method": "none",
                "message": "Missing variable name.",
            }
        )
        _emit(base)
        return

    if not re.match(r"^[a-zA-Z_][a-zA-Z0-9_]*$", variable):
        base.update(
            {
                "status": "unverified",
                "method": "none",
                "message": f"Unsafe or invalid variable name: {variable!r}.",
            }
        )
        _emit(base)
        return

    values, verr = _parse_value_list(proposed_value, additional_answers)
    if verr:
        base.update({"status": "unverified", "method": "none", "message": verr})
        _emit(base)
        return

    expr, perr = _build_sympy_expr(equation_expression, variable)
    if expr is not None and perr is None:
        from sympy import Symbol

        var_sym = Symbol(variable)
        ok, msg = _verify_sympy(expr, var_sym, values)
        if ok:
            method = "sympy_multi" if len(values) > 1 else "sympy_substitute"
            base.update(
                {
                    "verified": True,
                    "status": "verified",
                    "method": method,
                    "message": msg,
                }
            )
            _emit(base)
            return
        base.update(
            {
                "verified": False,
                "status": "failed",
                "method": "sympy_substitute",
                "message": msg,
            }
        )
        _emit(base)
        return

    sympy_failed = perr or "SymPy parse failed."

    ok, msg, method = _verify_numeric_eval(equation_expression, variable, values)
    if ok:
        base.update(
            {
                "verified": True,
                "status": "verified",
                "method": method,
                "message": msg + f" (Note: {sympy_failed})",
            }
        )
    else:
        base.update(
            {
                "verified": False,
                "status": "failed",
                "method": method,
                "message": msg + f" | {sympy_failed}",
            }
        )
    _emit(base)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        _emit(
            {
                "verified": False,
                "status": "unverified",
                "method": "none",
                "message": f"Verification internal error: {e}",
            }
        )
