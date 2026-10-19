# US-03: Heterogeneous Cluster Workload Splitting & Matrix Acceleration Benchmarking

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#3](https://github.com/LMA1980/model-runner/issues/3)
- **Feature Ref**: [Heterogeneous Core Affinity](../features/core-affinity.md), [Operator Diagnostic Tool](../features/diagnostic-tool.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md), [Inference Worker](../specs/runtime/worker.md)
- **Related ADRs**: [ADR-009](../decisions/ADR-009-cross-cluster-split.md), [ADR-028](../decisions/ADR-028-a100-premise.md), [ADR-029](../decisions/ADR-029-kernel-language.md), [ADR-033](../decisions/ADR-033-external-baseline.md), [ADR-034](../decisions/ADR-034-stage-1-yardstick.md)

## Narrative
**As an** Architecture Researcher,
**I want to** benchmark model forward passes across distinct processor clusters using configurable workload-splitting strategies and toggleable matrix acceleration,
**So that** I can empirically validate cluster capabilities and determine whether single-cluster placement or cross-cluster splitting delivers superior throughput without sacrificing output determinism.

## Business Context & Domain Rules
- Heterogeneous processors (such as the SpacemiT K3 reference platform pairing Out-of-Order general-purpose cores with wide-vector/matrix In-Order cores) exhibit asymmetric strengths across prefill and decode workloads.
- Rather than assuming one cluster is universally faster or relying on unpatched external baselines, the system benchmarks its own execution recipes against themselves across cluster configurations.
- Three cross-cluster distribution strategies are evaluated:
  1. **Phase split**: Assigning prompt prefill to one cluster and token decode to another.
  2. **Operation split**: Assigning heavy matrix multiplications to matrix-capable cores and normalization/attention operations to general-purpose cores.
  3. **Row split**: Partitioning matrix work concurrently across both clusters proportional to measured throughput.
- Workers must never migrate across asymmetric vector/matrix cluster boundaries mid-execution.

## Core System Assertions
- **Scenario 1: Cross-cluster workload splitting evaluation**
  - **Given** a multi-cluster processor configuration and a target model,
  - **When** the operator runs comparative benchmarks under single-cluster placement versus phase, operation, and row cross-cluster splitting strategies,
  - **Then** the system executes the workload according to the selected strategy and reports separate prefill and decode latencies for each configuration.
- **Scenario 2: Hardware matrix acceleration isolation**
  - **Given** a compute cluster supporting specialized matrix acceleration alongside baseline vector execution,
  - **When** the operator toggles matrix acceleration on versus off for the same model and prompt,
  - **Then** the system isolates and reports the exact prefill and decode throughput delta attributable to matrix acceleration.
- **Scenario 3: Deterministic output verification across placements**
  - **Given** deterministic sampling parameters (temperature set to zero) across repeated runs,
  - **When** a prompt is evaluated repeatedly on a given cluster and split configuration,
  - **Then** the generated token sequence is bit-identical across every iteration.
