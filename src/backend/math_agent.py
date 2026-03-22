"""
Math Fact-Checker agent using LangGraph and LangChain.
Controls tool calls (verify_solution) and responds to the client.
"""

import json
from typing import Annotated, TypedDict

from langchain_core.messages import (
    AIMessage,
    BaseMessage,
    HumanMessage,
    SystemMessage,
    ToolMessage,
)
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.graph import END, StateGraph
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode
from math_response_format import (
    coerce_narrative_to_json_solution,
    try_parse_structured_json,
)
from math_tools import run_verify_solution


@tool
def verify_solution(
    equation_expression: str,
    variable: str,
    proposed_value: str,
    additional_answers: str = "",
    problem_kind: str = "algebraic_equation",
) -> str:
    """
    Verify that proposed answer(s) satisfy the equation (symbolic SymPy check when possible, else safe numeric plug-in).

    Args:
        equation_expression: For f(x)=0 form use one expression (e.g. "x**2 - 25"). For a==b use "a == b" with SymPy syntax (** for powers).
        variable: Unknown symbol, e.g. "x".
        proposed_value: Primary answer as string, e.g. "5" or "3/4".
        additional_answers: Optional extra roots/values: comma-separated ("-5, 5") or JSON list string '["-5","5"]'.
        problem_kind: One of:
            - "algebraic_equation" (default): equation / expression verification.
            - "multi_answer": same as algebraic but you MUST list every distinct solution in proposed_value + additional_answers.
            - "non_algebraic" (or "proof", "geometry", "word_problem"): skips mechanical check; use for proofs, "show that", intervals only described in text, etc.

    Returns:
        JSON with keys: verified (bool), status ("verified"|"failed"|"unverified"), method (str), message (str).
    """
    result = run_verify_solution(
        equation_expression=equation_expression,
        variable=variable,
        proposed_value=proposed_value,
        additional_answers=additional_answers,
        problem_kind=problem_kind,
    )
    return json.dumps(result)


MATH_AGENT_SYSTEM_PROMPT = """You are an expert mathematics tutor. Solve the math problem step by step.

After solving, call verify_solution:
- For standard equations: equation_expression with ** for powers (SymPy). Use `log(x)` not `math.log(x)`. Prefer "lhs == rhs" or single expression equal to zero.
- If there are multiple solutions (e.g. x^2=25 gives x=5 and x=-5), pass proposed_value as one root and additional_answers as the others (comma-separated or JSON list), and use problem_kind "multi_answer".
- For proofs, geometry "show that", word problems with no clean equation, inequalities described without a single plug-in, or vectors/matrices where scalar plug-in does not apply: use problem_kind "non_algebraic" and set equation_expression to a brief placeholder like "0" (verification will honestly skip).

Interpret tool JSON:
- status "verified": your answer passed automated check; finish with JSON only (no more tool calls).
- status "failed": say "Wait, my first calculation was wrong. Let me re-evaluate." Then fix and call verify_solution again.
- status "unverified": automated verification did not apply or could not run; give your final JSON solution and briefly note that the answer was not mechanically verified.

When finishing successfully, your final assistant message (no tool calls) must be ONLY valid JSON with keys:
"solution" (string), "steps" (array of strings), "answer" (string).
Do not wrap the JSON in markdown code fences."""


class AgentState(TypedDict):
    """State for the math agent graph."""

    messages: Annotated[list[BaseMessage], add_messages]
    verified: bool
    correction_note: str | None
    verification_status: str | None
    verification_method: str | None
    verification_message: str | None


def _tools_node(state: AgentState) -> dict:
    """Execute tool calls from the last AIMessage and track verification fields."""
    last_message = state["messages"][-1]
    if not isinstance(last_message, AIMessage) or not getattr(last_message, "tool_calls", None):
        return {
            "verified": state.get("verified", False),
            "correction_note": state.get("correction_note"),
            "verification_status": state.get("verification_status"),
            "verification_method": state.get("verification_method"),
            "verification_message": state.get("verification_message"),
        }

    tool_node = ToolNode([verify_solution])
    result = tool_node.invoke(state)
    verified = state.get("verified", False)
    correction_note = state.get("correction_note")
    verification_status = state.get("verification_status")
    verification_method = state.get("verification_method")
    verification_message = state.get("verification_message")

    for msg in result.get("messages", []):
        if isinstance(msg, ToolMessage) and msg.content:
            try:
                data = json.loads(msg.content)
                verification_status = data.get("status")
                verification_method = data.get("method")
                verification_message = data.get("message")
                st = verification_status
                if st == "verified" and data.get("verified") is True:
                    verified = True
                elif st == "failed":
                    verified = False
                    if not correction_note:
                        correction_note = "Corrected after verification failed."
                elif st == "unverified":
                    verified = False
            except (json.JSONDecodeError, TypeError):
                pass

    return {
        "messages": result.get("messages", []),
        "verified": verified,
        "correction_note": correction_note,
        "verification_status": verification_status,
        "verification_method": verification_method,
        "verification_message": verification_message,
    }


def _should_continue(state: AgentState) -> str:
    """Route to tools or END based on whether the last message has tool_calls."""
    last_message = state["messages"][-1]
    if isinstance(last_message, AIMessage) and getattr(last_message, "tool_calls", None):
        return "tools"
    return "end"


def build_math_agent_graph():
    """Build the LangGraph agent graph: agent -> (tools -> agent)* -> end."""
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        temperature=0.3,
        max_tokens=1500,
    ).bind_tools([verify_solution])

    def agent_node(state: AgentState) -> dict:
        response = llm.invoke(state["messages"])
        return {"messages": [response]}

    graph = StateGraph(AgentState)

    graph.add_node("agent", agent_node)
    graph.add_node("tools", _tools_node)

    graph.set_entry_point("agent")
    graph.add_conditional_edges("agent", _should_continue, {"tools": "tools", "end": END})
    graph.add_edge("tools", "agent")

    return graph.compile()


_agent_graph = None


def get_agent_graph():
    global _agent_graph
    if _agent_graph is None:
        _agent_graph = build_math_agent_graph()
    return _agent_graph


def run_math_agent_langgraph(
    image_url: str | None = None,
    problem_text: str | None = None,
    system_prompt: str | None = None,
) -> tuple[str, list[str], str, bool | None, str | None, str | None, str | None, str | None]:
    """
    Run the LangGraph math agent with optional vision and/or text problem.

    Returns:
        solution_text, steps, answer,
        verified (API): True if check passed, False if failed, None if unverified / inconclusive,
        correction_note,
        verification_status: "verified" | "failed" | "unverified" | None,
        verification_method, verification_message
    """
    if not image_url and not (problem_text or "").strip():
        raise ValueError("At least one of image_url or problem_text is required.")

    system_prompt = system_prompt or MATH_AGENT_SYSTEM_PROMPT
    instruction = "Solve this math problem. Use the verify_solution tool to check your answer when applicable."
    if (problem_text or "").strip():
        instruction = (
            f"Solve this math problem:\n\n{problem_text.strip()}\n\n"
            "Use verify_solution when an algebraic check applies; otherwise use problem_kind non_algebraic."
        )

    if image_url:
        user_content = [
            {"type": "text", "text": instruction},
            {"type": "image_url", "image_url": {"url": image_url}},
        ]
    else:
        user_content = instruction

    initial_messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=user_content),
    ]

    initial_state: AgentState = {
        "messages": initial_messages,
        "verified": False,
        "correction_note": None,
        "verification_status": None,
        "verification_method": None,
        "verification_message": None,
    }

    graph = get_agent_graph()
    config = {"recursion_limit": 10}
    final_state = graph.invoke(initial_state, config=config)
    print("final_state", final_state)
    messages = final_state.get("messages", [])
    raw_status = final_state.get("verification_status")
    verification_method = final_state.get("verification_method")
    verification_message = final_state.get("verification_message")
    correction_note = final_state.get("correction_note")

    if raw_status == "verified":
        verified_api: bool | None = True
        verification_status = "verified"
    elif raw_status == "failed":
        verified_api = False
        verification_status = "failed"
    elif raw_status == "unverified":
        verified_api = None
        verification_status = "unverified"
    else:
        verified_api = None
        verification_status = "unverified"
        if verification_message is None:
            verification_message = "No verification result (tool not used or incomplete)."
        verification_method = verification_method or "none"

    solution_text = ""
    fallback_content = ""
    for m in reversed(messages):
        if isinstance(m, AIMessage):
            if not getattr(m, "tool_calls", None):
                solution_text = (m.content or "").strip()
                break
            if m.content:
                fallback_content = (m.content or "").strip()
    if not solution_text and fallback_content:
        solution_text = fallback_content
    if not solution_text:
        solution_text = "Unable to produce a final solution."

    structured = try_parse_structured_json(solution_text)
    if structured is not None:
        solution_text, steps, answer = structured
    else:
        solution_text, steps, answer = coerce_narrative_to_json_solution(solution_text)
    print("verification_status", verification_status)
    print("verification_method", verification_method)
    print("verification_message", verification_message)
    return (
        solution_text,
        steps,
        answer,
        verified_api,
        correction_note,
        verification_status,
        verification_method,
        verification_message,
    )
