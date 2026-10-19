# US-16: Crash-Resilient Context Retention & Resumable Generation

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#16](https://github.com/LMA1980/model-runner/issues/16)
- **Feature Ref**: [Session & Project Isolation](../features/session-mgmt.md), [KV Cache Management](../features/kv-cache.md)
- **Spec Ref**: [KV Holder Service](../specs/memory/kv-holder.md), [Paged KV Allocator](../specs/memory/kv-allocator.md), [Inference Worker](../specs/runtime/worker.md)
- **Related ADRs**: [ADR-026](../decisions/ADR-026-resumable-computation.md), [ADR-042](../decisions/ADR-042-kv-holder.md)

## Narrative
**As an** Operator / AI Application Client,
**I want** active context state, committed tokens, and sampler state to survive compute worker crashes, control service restarts, and temporary client disconnects in active memory,
**So that** interrupted long-running generations resume seamlessly from the last committed token without re-running expensive prompt prefill or already-generated tokens.

## Business Context & Domain Rules
- On edge and local hardware, long prompt prefills and multi-hundred-token reasoning generations represent significant compute investment.
- Holding active context memory in a dedicated, minimal, policy-free memory holder independent of both the compute workers and the control service ensures that neither a worker fault nor a control restart destroys in-flight context state.
- As each token is generated, the runtime checkpoints the committed token count and deterministic sampler state alongside the context blocks.
- If a compute worker or control service restarts mid-generation, the recovered runtime resumes decoding from the last committed token.
- If a client disconnects mid-response and reconnects with the same prompt, it picks up the in-flight or completed generation rather than starting over.

## Core System Assertions
- **Scenario 1: Seamless decode resumption after compute worker crash**
  - **Given** a model is mid-way through generating a multi-token response after completing prompt prefill,
  - **When** the model's compute worker crashes and is restarted by the supervisor,
  - **Then** the restarted worker attaches to the preserved context arena and resumes token generation from the exact last committed token with identical sampler state, without re-executing prefill.
- **Scenario 2: Context survival across control service restart**
  - **Given** active context caches and in-flight generation metadata held in the independent context memory holder,
  - **When** the control service restarts,
  - **Then** the restarted control service re-attaches to the surviving context memory table, recovers all committed session prefixes and progress, and resumes interrupted generations.
- **Scenario 3: Client reconnection recovery**
  - **Given** a client disconnects while its request is actively generating tokens,
  - **When** the client reconnects and resubmits the identical prompt within the retention window,
  - **Then** the runtime attaches the client to the surviving in-flight or completed generation result without duplicating prefill or prior decode work.
