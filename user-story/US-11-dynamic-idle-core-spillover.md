# US-11: Opt-In Dynamic Idle Core Lending & Pass-Boundary Reclaim

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#11](https://github.com/LMA1980/model-runner/issues/11)
- **Feature Ref**: [Dynamic Unified Memory Balancing](../features/dynamic-spillover.md), [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md), [System Isolation & CGroups](../specs/runtime/isolation.md)
- **Related ADRs**: [ADR-030](../decisions/ADR-030-spillover.md), [ADR-032](../decisions/ADR-032-tuning-authority.md), [ADR-041](../decisions/ADR-041-isolation-domains.md)

## Narrative

**As a** System Operator,
**I want** to selectively opt models into lending or borrowing idle compute cores on a per-forward-pass basis with guaranteed pass-boundary reclamation,
**So that** active models can accelerate generation using otherwise idle board capacity while immediately returning those cores as soon as their reserved owner needs them.

## Business Context & Domain Rules

- Under strict reservation boundaries, compute cores assigned to an idle model sit unused even when another active model could use them.
- Dynamic spillover (work-stealing) is strictly opt-in per model via two independent operator profile settings—permission to lend idle cores (`lend_idle_cores`) and permission to borrow idle cores (`borrow_idle_cores`)—both disabled by default to preserve baseline determinism.
- Borrowed cores are granted for a single forward pass at a time and reclaimed cleanly at the next pass boundary without interrupting an in-flight pass or incurring runtime reconfiguration stalls.

## Core System Assertions

- **Scenario 1: Default isolation when lending or borrowing is disabled**
  - **Given** Model A with idle reserved cores and Model B actively executing requests, where either Model A has not opted into lending or Model B has not opted into borrowing,
  - **When** Model B executes forward passes,
  - **Then** Model B executes strictly within its own reserved cores and never spills over onto Model A's idle cores.
- **Scenario 2: Temporary core borrowing during peer idle periods**
  - **Given** Model A has `lend_idle_cores` enabled and is currently idle, and Model B has `borrow_idle_cores` enabled and is actively processing a prompt,
  - **When** Model B dispatches a forward pass,
  - **Then** the scheduler expands Model B's pass execution across its own reservation plus Model A's lendable idle cores.
- **Scenario 3: Immediate pass-boundary reclamation when owner wakes**
  - **Given** Model B is currently executing a forward pass using cores borrowed from idle Model A,
  - **When** a new inference request arrives for Model A,
  - **Then** Model B finishes its current single forward pass and the scheduler immediately reclaims Model A's reserved cores at the pass boundary so Model A executes its next pass without delay.
