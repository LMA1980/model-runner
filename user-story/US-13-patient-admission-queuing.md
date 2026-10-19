# US-13: Patient Request Queuing with Live Progress Feedback

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#13](https://github.com/LMA1980/model-runner/issues/13)
- **Feature Ref**: [Multi-Model Scheduling](../features/multi-model-sched.md), [KV Cache Management](../features/kv-cache.md)
- **Spec Ref**: [OpenAI API Adapter](../specs/api/openai.md), [Claude API Adapter](../specs/api/claude.md)
- **Related ADRs**: [ADR-005](../decisions/ADR-005-prompt-exclusivity.md), [ADR-015](../decisions/ADR-015-admission-queue.md)

## Narrative
**As an** AI Application Client,
**I want** concurrent requests that arrive while a model is busy to wait patiently in a deep per-model queue with periodic keep-alive and queue-position updates rather than being cut off by arbitrary quotas or premature timeouts,
**So that** bursty workloads reliably complete on local hardware without client connection drops or artificial usage throttling.

## Business Context & Domain Rules
- Because the runtime enforces single-prompt cycle exclusivity for determinism, concurrent requests to the same model queue in First-In, First-Out (FIFO) order.
- The system prioritizes **patience over rejection**:
  - Each model maintains a deep, configurable admission queue (default depth 64).
  - Queue wait timeouts are disabled by default so long-running generations ahead in the queue do not cause waiting requests to fail prematurely.
  - No token or usage quotas are imposed on clients.
- While a streaming request waits in the queue, the runtime emits periodic keep-alive heartbeats and current queue-position notifications so client connections never time out waiting for the first token.
- Only when an operator-configured queue depth cap is reached does the runtime reject additional incoming requests with an explicit overload status and a recommended retry delay.

## Core System Assertions
- **Scenario 1: Patient FIFO queuing with keep-alive and queue-position updates**
  - **Given** a model is actively executing a request and its admission queue is below its configured depth cap,
  - **When** additional streaming client requests arrive for that model,
  - **Then** the requests are placed in FIFO order, receive periodic keep-alive signals with their advancing queue position while waiting, and begin token generation in exact arrival order without timing out.
- **Scenario 2: Explicit overload signaling when queue capacity is reached**
  - **Given** a model's admission queue is completely full at its operator-configured maximum depth,
  - **When** a new request arrives for that model,
  - **Then** the system immediately rejects the request with a standard overload status code and an explicit retry-after guidance indicator without disrupting queued or executing requests.
- **Scenario 3: Absence of token or usage quota cutoffs**
  - **Given** a client submitting sustained multi-turn or high-volume inference requests within the model's context window and queue depth limits,
  - **When** the runtime processes the requests over time,
  - **Then** no request is ever throttled or rejected due to cumulative token consumption or usage quotas.
