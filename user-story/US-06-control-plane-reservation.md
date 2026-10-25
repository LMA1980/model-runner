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

## Engineering Breakdown

- [**US-06.1**: Control Plane Core Reservation & Cgroup/Affinity Domain Partitioning (#65)](https://github.com/LMA1980/model-runner/issues/65)
  - [**US-06.1.1**: Implement `ControlPlaneCapacityConfig` & `X100` Control/Spare/Compute Core Resolver (#69)](https://github.com/LMA1980/model-runner/issues/69)
  - [**US-06.1.2**: Implement Cgroup v2 Leaf Domain Placement & OS Thread Affinity Fallback (#70)](https://github.com/LMA1980/model-runner/issues/70)
  - [**US-06.1.3**: Enforce Compute Worker Placement Cap & Multi-Thread Affinity Guard (#71)](https://github.com/LMA1980/model-runner/issues/71)
- [**US-06.2**: Control-Plane Orchestration Pipeline & Tokenization Responsiveness Under Compute Saturation (#66)](https://github.com/LMA1980/model-runner/issues/66)
  - [**US-06.2.1**: Integrate `k3-tokenizer` & Chat Template Orchestration into `k3-manager` (#72)](https://github.com/LMA1980/model-runner/issues/72)
  - [**US-06.2.2**: Implement Control-Plane Token-ID Prefix Radix Index & Block Lookup (#73)](https://github.com/LMA1980/model-runner/issues/73)
  - [**US-06.2.3**: Implement Reserved Active Control Thread Pool & Non-Blocking Admin/Queue Status Plane (#74)](https://github.com/LMA1980/model-runner/issues/74)
- [**US-06.3**: Health Supervisor, Spare Recovery Thread & Runaway Workload Intervention (#67)](https://github.com/LMA1980/model-runner/issues/67)
  - [**US-06.3.1**: Implement Deadline-Bounded UDS I/O & Worker Heartbeat/Pass Timeout Detection (#75)](https://github.com/LMA1980/model-runner/issues/75)
  - [**US-06.3.2**: Implement Dedicated Spare Recovery Watchdog Thread & Runaway Task/Worker Preemption (#76)](https://github.com/LMA1980/model-runner/issues/76)
- [**US-06.4**: End-to-End Integration Verification for Control Responsiveness & Runaway Recovery (#68)](https://github.com/LMA1980/model-runner/issues/68)
  - [**US-06.4.1**: Implement US-06 Scenario 1 E2E Test (Control Responsiveness Under 100% Compute Saturation) (#77)](https://github.com/LMA1980/model-runner/issues/77)
  - [**US-06.4.2**: Implement US-06 Scenario 2 E2E Test (Runaway Workload Preemption & Recovery via Spare Capacity) (#78)](https://github.com/LMA1980/model-runner/issues/78)
