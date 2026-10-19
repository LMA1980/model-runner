# US-06: Dedicated Control Plane Capacity & Runaway Workload Recovery

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#6](https://github.com/LMA1980/model-runner/issues/6)
- **Feature Ref**: [Heterogeneous Core Affinity](../features/core-affinity.md)
- **Spec Ref**: [System Isolation & CGroups](../specs/runtime/isolation.md), [Process Model & IPC](../specs/runtime/process-model.md)
- **Related ADRs**: [ADR-007](../decisions/ADR-007-control-plane-cores.md), [ADR-008](../decisions/ADR-008-core-partitioning.md), [ADR-025](../decisions/ADR-025-tokenizer-ownership.md), [ADR-041](../decisions/ADR-041-isolation-domains.md)

## Narrative
**As a** System Operator,
**I want** the runtime to reserve dedicated general-purpose processing capacity—including spare recovery capacity—exclusively for control orchestration and tokenization,
**So that** session management, prompt tokenization, and administrative intervention remain immediately responsive even when all model compute workers are saturated or a worker enters a runaway state.

## Business Context & Domain Rules
- Model inference is compute-intensive and can saturate all cores assigned to compute pools.
- If control-plane tasks (request admission, prompt tokenization, chat template formatting, prefix index lookup, stop-sequence detection, and health supervision) compete with pinned model workers, system responsiveness collapses under heavy load.
- By default, the system reserves dedicated general-purpose control capacity (including spare recovery headroom, configurable down to a minimal footprint on lower-resource boards) and caps maximum compute reservations on that cluster accordingly.

## Core System Assertions
- **Scenario 1: Control responsiveness under full compute saturation**
  - **Given** active model workers utilizing 100% of their allocated compute capacity,
  - **When** new client requests or operator management commands arrive at the control plane,
  - **Then** tokenization, prefix matching, queue status reporting, and administrative commands execute within normal latency bounds without being starved by model forward passes.
- **Scenario 2: Runaway workload intervention via spare recovery capacity**
  - **Given** a compute or control task that becomes unresponsive or enters a runaway loop,
  - **When** the health supervisor detects the stalled workload,
  - **Then** reserved spare control capacity remains available to preempt, terminate, and recover the runaway task without requiring a physical board reboot.
