# US-04: Hardware Ceiling Cost Profiling & Machine-Readable Export

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Completed
- **GitHub Issue**: [#4](https://github.com/LMA1980/model-runner/issues/4)
- **Feature Ref**: [Operator Diagnostic Tool](../features/diagnostic-tool.md), [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-010](../decisions/ADR-010-determinism-cost.md), [ADR-032](../decisions/ADR-032-tuning-authority.md), [ADR-034](../decisions/ADR-034-stage-1-yardstick.md)

## Narrative

**As a** Control Plane Developer / Operator,
**I want** diagnostic evaluations to produce a structured, machine-readable cost profile comparing achieved prefill and decode performance against theoretical hardware ceilings,
**So that** the runtime can establish static scheduling weights and generate evidence-based tuning recommendations for the board.

## Business Context & Domain Rules

- Without a meaningful external baseline on emerging hardware architectures, model performance must be evaluated against the physical limits of the host board.
- Prompt prefill throughput is evaluated as a ratio of theoretical peak compute capacity, while autoregressive token decode is evaluated as a ratio of available system memory bandwidth.
- Diagnostic runs impose no arbitrary pass/fail threshold; instead, they export an objective cost profile that feeds fair time-slicing weights and operator tuning advisories.

## Core System Assertions

- **Scenario 1: Hardware ceiling efficiency reporting**
  - **Given** a completed model benchmark on a specified compute cluster and core allocation,
  - **When** the diagnostic summary is produced,
  - **Then** the system reports prefill speed alongside its percentage of theoretical compute capacity, and decode speed alongside its percentage of theoretical memory bandwidth capacity.
- **Scenario 2: Machine-readable cost baseline export**
  - **Given** an operator request for a machine-readable cost profile export,
  - **When** the isolated diagnostic benchmark completes,
  - **Then** the system outputs a structured cost profile record capturing the model identity, quantization level, cluster placement, allocated core count, split strategy, prefill cost per token, decode rate, and peak resident memory footprint.
