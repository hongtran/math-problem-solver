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


# LangChain tool for verify_solution (used by the agent to decide when to call it)
@tool
def verify_solution(
    equation_expression: str,
    variable: str,
    proposed_value: str,
) -> str:
    """
    Verify that a proposed answer satisfies the given equation.
    Call this after solving: plug the variable with the proposed value into the equation (should equal zero or True).
    Args:
        equation_expression: Python expression that should equal zero when correct, e.g. 'x**2 - 25' for x^2 = 25
        variable: Variable name used in the equation, e.g. 'x'
        proposed_value: The answer to verify, e.g. '5'
    Returns:
        JSON string with keys 'verified' (bool) and 'message' (str).
    """
    result = run_verify_solution(
        equation_expression=equation_expression,
        variable=variable,
        proposed_value=proposed_value,
    )
    return json.dumps(result)


MATH_AGENT_SYSTEM_PROMPT = """You are an expert mathematics tutor. Solve the math problem step by step.

After solving, you MUST call the verify_solution tool with:
- equation_expression: the equation rearranged so the right-hand side is 0 (e.g. for x^2 = 25 use "x**2 - 25")
- variable: the unknown variable (e.g. "x")
- proposed_value: your numerical answer as a string (e.g. "5")

If the tool returns verified: false, you MUST say: "Wait, my first calculation was wrong. Let me re-evaluate." Then solve again and call verify_solution again.
When the tool returns verified: true, your final assistant message (with no further tool calls) must be ONLY a valid JSON object with keys:
"solution" (string, full explanation), "steps" (array of strings), "answer" (string).
Do not wrap the JSON in markdown code fences. Do not make further tool calls after verification succeeds.

Note: OpenAI tool calls cannot use strict JSON mode in the same request; if your final message is not valid JSON, the server will convert it to JSON in a follow-up step."""


class AgentState(TypedDict):
    """State for the math agent graph."""

    messages: Annotated[list[BaseMessage], add_messages]
    verified: bool
    correction_note: str | None


def _tools_node(state: AgentState) -> dict:
    """Execute tool calls from the last AIMessage and track verified/correction_note."""
    last_message = state["messages"][-1]
    if not isinstance(last_message, AIMessage) or not getattr(last_message, "tool_calls", None):
        return {
            "verified": state.get("verified", False),
            "correction_note": state.get("correction_note"),
        }

    tool_node = ToolNode([verify_solution])
    result = tool_node.invoke(state)
    verified = state.get("verified", False)
    correction_note = state.get("correction_note")

    # Update verified and correction_note from verify_solution results
    for msg in result.get("messages", []):
        if isinstance(msg, ToolMessage) and msg.content:
            try:
                data = json.loads(msg.content)
                if data.get("verified") is True:
                    verified = True
                elif data.get("verified") is False and not correction_note:
                    correction_note = "Corrected after verification failed."
            except (json.JSONDecodeError, TypeError):
                pass

    return {
        "messages": result.get("messages", []),
        "verified": verified,
        "correction_note": correction_note,
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


# Compiled graph instance (lazy init to avoid import-time env requirements)
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
) -> tuple[str, list[str], str, bool, str | None]:
    """
    Run the LangGraph math agent with optional vision and/or text problem.
    At least one of image_url or problem_text must be provided.
    Returns (solution_text, steps, answer, verified, correction_note).
    """
    if not image_url and not (problem_text or "").strip():
        raise ValueError("At least one of image_url or problem_text is required.")

    system_prompt = system_prompt or MATH_AGENT_SYSTEM_PROMPT
    instruction = "Solve this math problem. Use the verify_solution tool to check your answer."
    if (problem_text or "").strip():
        instruction = f"Solve this math problem:\n\n{problem_text.strip()}\n\nUse the verify_solution tool to check your answer."

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
    }

    graph = get_agent_graph()
    config = {"recursion_limit": 5}
    final_state = graph.invoke(initial_state, config=config)

    messages = final_state.get("messages", [])
    verified = final_state.get("verified", False)
    correction_note = final_state.get("correction_note")

    # Last AIMessage with no tool_calls is the final solution; else use last AIMessage content as fallback
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

    # Same structured shape as non-agent path: try parse JSON from model; else coerce via json_object LLM (no tools).
    structured = try_parse_structured_json(solution_text)
    if structured is not None:
        solution_text, steps, answer = structured
    else:
        solution_text, steps, answer = coerce_narrative_to_json_solution(solution_text)

    return solution_text, steps, answer, verified, correction_note
