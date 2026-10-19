# US-02: Multi-Core Synchronization & Jitter Evaluation

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#2](https://github.com/LMA1980/model-runner/issues/2)
- **Feature Ref**: [Operator Diagnostic Tool](../features/diagnostic-tool.md)
- **Spec Ref**: [Inference Worker](../specs/runtime/worker.md)
- **Related ADRs**: [ADR-006](../decisions/ADR-006-exclusivity-unit.md), [ADR-007](../decisions/ADR-007-control-plane-cores.md)

## Narrative
**As a** Runtime Engineer,
**I want to** evaluate identical model workloads across distinct multi-core coordination strategies over repeated runs,
**So that** I can measure synchronization overhead, latency variance, and compute utilization across cores and select the most deterministic execution strategy for the hardware.

## Business Context & Domain Rules
- Multi-core AI inference requires frequent coordination barriers between layers and operations; excessive barrier wait times or thread wake-up jitter directly degrade token generation throughput.
- On heterogeneous multi-core boards (such as the 16-core SpacemiT K3 reference platform or smaller multi-core configurations), different coordination strategies trade off idle power against barrier responsiveness.
- Candidate coordination strategies must be evaluated using identical model weights, prompts, and core allocations to ensure an objective comparison.

## Core System Assertions
- **Scenario 1: Comparative synchronization overhead measurement**
  - **Given** multiple candidate multi-core coordination profiles configured with identical model weights, input prompt, and core allocation,
  - **When** the operator executes a diagnostic benchmark across each coordination profile,
  - **Then** each run reports Time to First Token (TTFT), decode token generation rate, and cumulative inter-worker barrier wait overhead.
- **Scenario 2: Multi-run jitter and statistical variance reporting**
  - **Given** a diagnostic evaluation configured to repeat for multiple iterations (`N >= 3`),
  - **When** the repeated execution sequence completes,
  - **Then** the system reports mean latency, minimum and maximum bounds, and standard deviation across iterations to expose run-to-run jitter.
