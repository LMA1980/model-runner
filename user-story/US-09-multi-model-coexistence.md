# US-09: Multi-Model Coexistence & Overlapping Compute Time-Slicing

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#9](https://github.com/LMA1980/model-runner/issues/9)
- **Feature Ref**: [Multi-Model Scheduling](../features/multi-model-sched.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-005](../decisions/ADR-005-prompt-exclusivity.md), [ADR-006](../decisions/ADR-006-exclusivity-unit.md), [ADR-011](../decisions/ADR-011-request-vs-pass-ownership.md), [ADR-043](../decisions/ADR-043-per-model-isolation.md)

## Narrative
**As a** Platform Operator,
**I want** multiple models to remain loaded and active concurrently with overlapping compute cluster reservations that are arbitrated cleanly at forward-pass boundaries,
**So that** diverse workloads (such as routing, coding, and chat models) can share a single board without static core under-utilization or mid-pass interference.

## Business Context & Domain Rules
- Fixed hardware core counts cannot always be statically partitioned without leaving cores idle when one model is quiet.
- Up to an operator-configured maximum number of active models (defaulting to 3, subject to available system memory) may reside concurrently in memory.
- Each model placement defines its desired core reservation across available processor clusters, and reservations across models are allowed to overlap.
- Within any single model execution, strict single-prompt exclusivity applies (one prompt per forward pass, no cross-prompt batching; underfill occurs only at the tail of a prompt sequence).
- When multiple models contend for overlapping cores, the scheduler arbitrates access strictly at forward-pass boundaries so an executing pass is never preempted mid-computation.

## Core System Assertions
- **Scenario 1: Concurrent execution on non-overlapping reservations**
  - **Given** two active models whose configured core reservations do not overlap,
  - **When** both models receive inference requests simultaneously,
  - **Then** both models execute their forward passes in parallel without queuing behind one another for compute capacity.
- **Scenario 2: Pass-boundary time-slicing on overlapping reservations**
  - **Given** two active models whose configured core reservations overlap on one or more processor clusters,
  - **When** both models have pending forward passes simultaneously,
  - **Then** the scheduler grants each model exclusive use of its full core reservation for the duration of an individual forward pass and switches ownership only at pass completion boundaries.
- **Scenario 3: Enforcement of maximum active model limit**
  - **Given** the runtime is already hosting the operator-configured maximum number of active models,
  - **When** a request is made to load an additional active model without unloading an existing one,
  - **Then** the runtime rejects the load with a clear concurrency-limit diagnostic.
