# US-15: Implicit Session Continuity & Project-Scoped Prefix Caching

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#15](https://github.com/LMA1980/model-runner/issues/15)
- **Feature Ref**: [Session & Project Isolation](../features/session-mgmt.md), [KV Cache Management](../features/kv-cache.md)
- **Spec Ref**: [Paged KV Allocator](../specs/memory/kv-allocator.md)
- **Related ADRs**: [ADR-001](../decisions/ADR-001-tenancy.md), [ADR-002](../decisions/ADR-002-session-identity.md), [ADR-004](../decisions/ADR-004-prefix-cache-scope.md)

## Narrative
**As an** AI Application Developer,
**I want** the runtime to organize workloads under a `Tenant -> Project -> Session` hierarchy and automatically reuse cached prompt prefixes across stateless requests within the same project while prohibiting cross-project cache sharing,
**So that** multi-turn conversations and shared system prompts skip redundant prefill computation without requiring stateful client session IDs or leaking context timing across projects.

## Business Context & Domain Rules
- External AI client protocols are typically stateless: clients resend the full conversation transcript on each turn without a mandatory session identifier.
- The runtime establishes session continuity implicitly by matching tokenized request prefixes against cached context blocks keyed by `(project, model, model_build, token_prefix)`.
- Optional session and project request headers serve as routing hints and accounting labels rather than mandatory state tokens.
- Within a single project, identical prompt prefixes (such as shared system instructions or branching conversation histories) share cached context blocks via copy-on-write paged blocks.
- Across different projects, context caches are strictly isolated: even identical system prompts are never shared across project boundaries, eliminating cross-project timing side-channels and ensuring multi-tenant readiness from day one.

## Core System Assertions
- **Scenario 1: Implicit multi-turn prefix reuse for stateless clients**
  - **Given** a client in Project A completes a conversation turn and subsequently sends a follow-up request containing the prior conversation history plus a new user message,
  - **When** the runtime tokenizes the follow-up request,
  - **Then** the system automatically matches the cached token prefix from the previous turn and computes prefill only for the newly appended tokens.
- **Scenario 2: Intra-project shared prefix branching via copy-on-write**
  - **Given** two concurrent or sequential sessions within the same Project A that share an identical long system prompt or initial conversation prefix on the same model build,
  - **When** both sessions diverge with different user follow-ups,
  - **Then** both sessions share the underlying cached context blocks for the common prefix without duplication and allocate distinct context blocks only where their token sequences diverge.
- **Scenario 3: Strict cross-project cache isolation**
  - **Given** Project A has already cached a specific prompt prefix on a loaded model,
  - **When** a request assigned to Project B submits the exact same prompt text to the same model,
  - **Then** the runtime does not match or reuse Project A's cached context blocks, computing and storing Project B's context independently within Project B's scope.
