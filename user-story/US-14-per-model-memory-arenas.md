# US-14: Strict Per-Model Memory Arenas & Context Window Admission

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#14](https://github.com/LMA1980/model-runner/issues/14)
- **Feature Ref**: [KV Cache Management](../features/kv-cache.md), [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [Paged KV Allocator](../specs/memory/kv-allocator.md), [KV Holder Service](../specs/memory/kv-holder.md), [System Isolation & CGroups](../specs/runtime/isolation.md)
- **Related ADRs**: [ADR-016](../decisions/ADR-016-memory-tier.md), [ADR-027](../decisions/ADR-027-context-window.md), [ADR-037](../decisions/ADR-037-weight-residency.md), [ADR-043](../decisions/ADR-043-per-model-isolation.md)

## Narrative

**As a** System Operator / AI Application Developer,
**I want** each loaded model placement to operate within a strictly isolated, pre-reserved memory arena sized to its configured context window and concurrency slots, and to reject oversize prompts explicitly without silent truncation,
**So that** no model can ever burst into another model's memory or trigger system-wide out-of-memory failures, and clients always know when a prompt exceeds the configured context limit.

## Business Context & Domain Rules

- All loaded model weights, derived layouts, control overhead, and active context caches share the board's unified physical memory (e.g., 32 GB on the SpacemiT K3 reference board, or smaller pools on lower-memory boards).
- By construction, no model placement may encroach on another model's memory:
  - Each model placement defines a fixed context window bound (`n_ctx`), capped by the model's trained maximum.
  - At model load time, the system verifies that the model's locked weights plus a dedicated context arena sized for `n_ctx × active slots` fit within available system memory; if not, the model load is refused upfront.
  - Once loaded, context blocks for that model are allocated exclusively from its own dedicated arena; when full, least-recently-used cached entries within that same arena are evicted or incoming requests wait.
- If a client request (prompt plus requested generation budget) exceeds the model's configured `n_ctx`, the runtime immediately returns an explicit context-length-exceeded error and never silently truncates the prompt.

## Core System Assertions

- **Scenario 1: Load-time memory admission enforcement**
  - **Given** available unified memory on the host board and one or more already-loaded models,
  - **When** an operator attempts to load a model whose combined weight footprint and pre-reserved context arena (`n_ctx × active slots`) exceed remaining memory capacity,
  - **Then** the system refuses the load upfront with a clear memory-budget diagnostic and leaves already-loaded models completely unaffected.
- **Scenario 2: Strict per-model context arena containment under heavy load**
  - **Given** Model A and Model B are both loaded with their own dedicated context arenas,
  - **When** Model A experiences intense multi-session traffic that completely fills its context arena,
  - **Then** Model A evicts least-recently-used unreferenced context blocks only within its own arena (or queues incoming requests) and never consumes a single byte of Model B's arena.
- **Scenario 3: Explicit rejection of oversize prompts without silent truncation**
  - **Given** a model placement configured with a fixed context window bound `n_ctx`,
  - **When** a client submits a request whose tokenized prompt length exceeds `n_ctx`,
  - **Then** the system immediately rejects the request with an explicit `context_length_exceeded` error and never silently drops or truncates leading tokens.
