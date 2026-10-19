# US-12: Automated Request Routing via Internal Decision Models

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#12](https://github.com/LMA1980/model-runner/issues/12)
- **Feature Ref**: [Multi-Model Scheduling](../features/multi-model-sched.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-013](../decisions/ADR-013-decision-models.md), [ADR-014](../decisions/ADR-014-priority.md)

## Narrative
**As an** AI Application Developer / Client,
**I want** to submit requests targeting either a specific lightweight decision model directly or an automatic routing target (`model: auto`) that uses an internal decision model to select the optimal loaded model,
**So that** simple classification/routing queries run at minimal latency and complex prompts are automatically directed to the best-suited specialist model on the board.

## Business Context & Domain Rules
- Lightweight decision models (such as `tev1` or `nimble`) serve a dual role in the runtime:
  1. Direct inference endpoints for client classification, intent detection, or fast utility tasks.
  2. Internal routers invoked automatically on the critical path when a client specifies `model: auto`.
- When acting as an internal router, the decision model evaluates the incoming prompt against the capabilities of currently loaded models and dispatches the request to the selected target model.

## Core System Assertions
- **Scenario 1: Direct client invocation of a decision model**
  - **Given** a lightweight decision model is loaded and active on the runtime,
  - **When** a client submits a completion request explicitly naming that decision model,
  - **Then** the runtime executes the prompt on the decision model and returns its response directly to the client.
- **Scenario 2: Automatic model selection via `model: auto`**
  - **Given** a decision model and multiple specialist models are loaded on the runtime,
  - **When** a client submits a request with the model parameter set to `auto`,
  - **Then** the runtime first evaluates the prompt using the internal decision model to select the appropriate loaded specialist model, routes the prompt to that selected model, and returns the specialist model's generated response.
- **Scenario 3: Fallback or clear error when no decision router is available**
  - **Given** a client submits a request with `model: auto` when no decision router model is loaded or configured,
  - **When** the control plane processes the request,
  - **Then** the system either applies the operator's configured default fallback model or returns an explicit routing-unavailable error rather than hanging indefinitely.
