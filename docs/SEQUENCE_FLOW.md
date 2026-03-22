# Math Problem Solver — Sequence Flow

This document describes the sequence from **user submits problem (image and/or text)** to **user gets response**, including the **layered verification** path (SymPy, multi-answer, non-algebraic skip, optional LLM critique).

---

## 1. High-level flow (end-to-end)

```mermaid
sequenceDiagram
  participant User
  participant Frontend
  participant API
  participant LangGraph as LangGraph_Agent
  participant OpenAI
  participant VerifyTool as verify_solution_tool
  participant Worker as _verify_worker_subprocess
  participant Critique as verification_critique_optional
  participant Firebase

  User->>Frontend: Upload image and/or enter problem text
  Frontend->>Frontend: Encode image to base64 (if any)
  Frontend->>API: POST /solve-math-problem (image_base64, problem_text, use_verification)
  API->>API: Normalize image to PNG base64, build data URL if image present

  alt use_verification is True
    API->>LangGraph: run_math_agent_langgraph(image_url, problem_text)
    loop Agent loop until last AIMessage has no tool_calls
      LangGraph->>OpenAI: Chat with vision + tools (optional image + text)
      OpenAI-->>LangGraph: AIMessage (content and/or tool_calls)
      alt AIMessage has verify_solution tool_calls
        LangGraph->>VerifyTool: verify_solution(equation, variable, value, additional_answers, problem_kind)
        VerifyTool->>Worker: run_verify_solution, subprocess _verify_worker.py JSON stdin
        Worker-->>VerifyTool: status, method, message, verified
        VerifyTool-->>LangGraph: ToolMessage JSON
        LangGraph->>LangGraph: Update verification fields, correction_note if failed
      end
    end
    LangGraph-->>API: solution, steps, answer, verified, correction_note, verification fields
    opt verification_status is unverified and critique env enabled
      API->>Critique: run_verification_critique OpenAI JSON plausible or notes
      Critique-->>API: verification_critique string or None
    end
  else use_verification is False
    API->>OpenAI: One-shot completion (JSON schema response)
    OpenAI-->>API: solution JSON
    API->>API: Parse steps, answer, verification fields null
  end

  API->>API: Build MathProblemResponse and confidence from outcome
  opt user_email present and Firebase configured
    API->>Firebase: Save problem_data verified verification_status etc
  end
  API-->>Frontend: MathProblemResponse JSON with solution steps answer confidence
  Frontend->>User: Show solution, verification UI, critique when applicable
```

---

## 2. Verification path — LangGraph agent loop (detail)

When `use_verification` is **True**, the API uses a LangGraph agent that can call the `verify_solution` tool. Agent state tracks **`verification_status`**, **`verification_method`**, **`verification_message`**, plus internal **`verified`** / **`correction_note`**.

```mermaid
sequenceDiagram
  participant API as API_Endpoint
  participant Graph as LangGraph_Graph
  participant AgentNode as Agent_Node
  participant LLM as ChatOpenAI
  participant ToolsNode as Tools_Node
  participant MathTools as math_tools_verify

  API->>Graph: invoke SystemMessage HumanMessage optional image and text
  Graph->>AgentNode: agent node

  loop Until last message has no tool_calls
    AgentNode->>LLM: invoke(messages) with bind_tools(verify_solution)
    LLM-->>AgentNode: AIMessage (content and/or tool_calls)
    AgentNode-->>Graph: state with new AIMessage appended

    alt AIMessage has tool_calls
      Graph->>ToolsNode: tools node (ToolNode)
      ToolsNode->>MathTools: run_verify_solution payload
      MathTools-->>ToolsNode: verified, status, method, message
      ToolsNode->>ToolsNode: ToolMessage JSON merge state from tool result
      ToolsNode-->>Graph: updated state
      Graph->>AgentNode: agent node again
    else AIMessage has no tool_calls
      Graph->>Graph: END
    end
  end

  Graph-->>API: final_state messages verification fields
  API->>API: Map verification_status to verified true false or null
  API->>API: Parse final AIMessage JSON to solution steps answer
```

**API mapping of `verified` (honest semantics):**

| `verification_status` from last tool | `verified` in HTTP response |
|----------------------------------------|-----------------------------|
| `verified`                             | `true`                      |
| `failed`                               | `false`                     |
| `unverified` or tool never ran         | `null`                      |

---

## 3. verify_solution tool → `_verify_worker.py` (detail)

The tool runs in an **isolated subprocess** (`_verify_worker.py`) with timeout (~8s). No arbitrary code execution in the API process.

```mermaid
sequenceDiagram
  participant Agent as LangGraph_Tools_Node
  participant Tool as verify_solution
  participant MathTools as math_tools_run_verify
  participant Subprocess as verify_worker_py

  Agent->>Tool: verify_solution equation variable values problem_kind
  Tool->>MathTools: run_verify_solution JSON payload
  MathTools->>Subprocess: stdin JSON payload
  alt skip kinds non_algebraic proof geometry word etc
    Subprocess-->>MathTools: unverified skipped_non_algebraic
  else algebraic
    Note over Subprocess: SymPy parse substitute simplify, or numeric fallback if parse fails
    Subprocess->>Subprocess: evaluate all proposed values
    Subprocess-->>MathTools: verified failed or sympy or numeric_plugin
  end
  MathTools-->>Tool: result dict
  Tool-->>Agent: JSON string ToolMessage
```

**Tool parameters (summary):**

| Parameter | Role |
|-----------|------|
| `equation_expression` | SymPy string: `f(var)=0` or `lhs == rhs`; use `**` for powers, `log(x)` not `math.log(x)`. |
| `variable` | Symbol name, e.g. `x`. |
| `proposed_value` | Primary answer string. |
| `additional_answers` | Extra roots: comma-separated or JSON array string. |
| `problem_kind` | `algebraic_equation`, `multi_answer`, or skip family: `non_algebraic`, `proof`, `geometry`, `word_problem`, `inequality_chain`. |

---

## 4. Optional LLM critique (unverified only)

When **`verification_status == "unverified"`** after the agent run, the solver may call **`run_verification_critique`** if the environment variable **`MATH_VERIFICATION_CRITIQUE`** is set to a truthy value (`1`, `true`, `yes`, `on`). That issues a separate **JSON-object** completion (consistency / plausible / notes). The result is exposed as **`verification_critique`** on the HTTP response.

---

## 5. Response shape back to client

After the flow completes, the API returns a **MathProblemResponse**:

| Field | Description |
|-------|-------------|
| `solution` | Full solution text from the agent/LLM. |
| `steps` | List of solution steps. |
| `answer` | Final answer string. |
| `confidence` | Depends on outcome: higher when `verified` and SymPy-backed; lower when failed or unverified; ~0.85 when verification is off. |
| `processing_time` | Seconds elapsed since request start. |
| `verified` | `true` only if mechanical check passed; `false` if check failed; `null` if verification off or unverified / no check. |
| `verification_status` | `"verified"` \| `"failed"` \| `"unverified"` when `use_verification` is True; else `null`. |
| `verification_method` | e.g. `sympy_substitute`, `sympy_multi`, `numeric_plugin`, `skipped_non_algebraic`, `none`. |
| `verification_message` | Human-readable detail from the worker (or agent-visible tool text). |
| `verification_critique` | Optional second-pass LLM note when unverified + env enabled. |
| `correction_note` | e.g. set when a tool run returned `failed` and the agent was prompted to correct. |

**Flutter client:** when `verified == true`, the UI can show **verification method** and **verification message**; when `verified` is not true and **`verification_critique`** is present, show the **review note** instead (see `SolutionDisplayWidget`).

---

## 6. Related files (backend)

| File | Role |
|------|------|
| `main.py` | FastAPI routes; `POST /solve-math-problem`. |
| `solver.py` | Orchestrates agent vs one-shot path, critique, Firestore persist, response assembly. |
| `math_agent.py` | LangGraph graph, `verify_solution` tool, system prompt, return tuple with verification fields. |
| `math_tools.py` | Spawns `_verify_worker.py` subprocess with JSON payload. |
| `_verify_worker.py` | SymPy + numeric fallback + `problem_kind` skip logic. |
| `math_verification_critique.py` | Optional critique LLM call. |
| `schemas.py` | `MathProblemRequest` / `MathProblemResponse` field definitions. |
