"""
LangGraph Studio / `langgraph dev` entrypoint.

Run from the repository root (see README "LangGraph dev"):
  langgraph dev

The exported `graph` must be a compiled LangGraph graph (same as production agent).
"""

from math_agent import build_math_agent_graph

# Used by langgraph.json: "./src/backend/langgraph_app.py:graph"
graph = build_math_agent_graph()
