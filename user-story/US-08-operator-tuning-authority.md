# US-08: Operator-Authoritative Tuning Profiles & Advisory Recommendations

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#8](https://github.com/LMA1980/model-runner/issues/8)
- **Feature Ref**: [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-010](../decisions/ADR-010-determinism-cost.md), [ADR-032](../decisions/ADR-032-tuning-authority.md)

## Narrative
**As a** System Operator,
**I want** my configured tuning profiles to remain strictly authoritative over model placement, resource reservations, context window bounds, priority class, and core sharing while the runtime provides data-driven tuning suggestions on demand,
**So that** runtime behavior stays completely predictable for my target application and never mutates resource allocations behind my back.

## Business Context & Domain Rules
- Optimal resource allocation depends on the business application the board serves (e.g., interactive low-latency routing versus background batch reasoning).
- The operator tuning profile is the sole authority governing a model's cluster reservations, context window cap, priority class (`latency` vs `throughput`), and idle core lending/borrowing permissions.
- While serving live traffic, the runtime continuously observes pass execution costs for two purposes only:
  1. Refining internal cost weights for fair time-slicing among same-priority models.
  2. Generating advisory tuning recommendations when requested by the operator.
- The runtime must never automatically alter an operator's configured tuning profile.

## Core System Assertions
- **Scenario 1: Strict preservation of operator profile under online observation**
  - **Given** a model running under an operator-applied tuning profile while the runtime observes live prefill and decode pass costs that differ from static estimates,
  - **When** the runtime updates its internal execution cost metrics,
  - **Then** the model's configured cluster placement, core reservation, context window, priority class, and lending flags remain completely unchanged.
- **Scenario 2: On-demand advisory tuning recommendations**
  - **Given** historical diagnostic baselines and online pass cost measurements collected for a model,
  - **When** the operator requests tuning recommendations for that model,
  - **Then** the system outputs a proposed tuning profile explaining the expected latency/throughput trade-offs without applying the changes until the operator explicitly approves them.
