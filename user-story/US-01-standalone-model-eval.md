# US-01: Standalone Local Model Evaluation

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#1](https://github.com/LMA1980/model-runner/issues/1)
- **Feature Ref**: [Operator Diagnostic Tool](../features/diagnostic-tool.md)
- **Spec Ref**: [Inference Worker](../specs/runtime/worker.md)
- **Related ADRs**: [ADR-005](../decisions/ADR-005-prompt-exclusivity.md), [ADR-017](../decisions/ADR-017-formats.md), [ADR-023](../decisions/ADR-023-architecture-onboarding.md), [ADR-037](../decisions/ADR-037-weight-residency.md)

## Narrative
**As an** Operator / Systems Engineer,
**I want to** load and evaluate a local quantized model directly in a standalone diagnostic session without starting background orchestration or multi-service infrastructure,
**So that** I can rapidly verify inference correctness, prompt tokenization, and raw token generation behavior on the target hardware.

## Business Context & Domain Rules
- Operators need a direct, zero-orchestration path to validate that a model produces coherent output on the target board (such as the SpacemiT K3 Pico-ITX reference platform or lower-resource variants) before onboarding the model into managed service pools.
- Loaded model weights must remain resident in active system memory throughout evaluation so storage paging never introduces unpredictable stalls during forward passes.
- Prompt tokenization must use the vocabulary and chat formatting rules matching the model's architecture.
- Evaluation executes strictly one prompt per forward pass without cross-prompt batching to guarantee isolated, reproducible behavior.

## Core System Assertions
- **Scenario 1: Direct local model evaluation and token streaming**
  - **Given** a supported local model file and an input prompt provided by the operator,
  - **When** the operator initiates a standalone diagnostic evaluation,
  - **Then** the system validates the model's architecture support, locks its weights in active memory, tokenizes the input prompt, executes the forward pass in isolation, and streams generated tokens in real time.
- **Scenario 2: Explicit compute cluster and concurrency targeting**
  - **Given** a target board with one or more processor clusters and configurable execution concurrency,
  - **When** the operator specifies the target processor cluster(s) and worker count for the diagnostic run,
  - **Then** the evaluation restricts model execution strictly to the requested compute cluster(s) and concurrency bound for the duration of the run.
- **Scenario 3: Resident memory verification prior to execution**
  - **Given** a local model whose weight footprint exceeds currently available lockable system memory,
  - **When** the operator attempts a standalone evaluation,
  - **Then** the system refuses the run upfront with an explicit insufficient-memory diagnostic rather than degrading into storage thrashing mid-generation.
