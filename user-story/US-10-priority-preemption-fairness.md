# US-10: Priority Class Preemption & Cost-Weighted Fair Sharing

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#10](https://github.com/LMA1980/model-runner/issues/10)
- **Feature Ref**: [Multi-Model Scheduling](../features/multi-model-sched.md), [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-010](../decisions/ADR-010-determinism-cost.md), [ADR-014](../decisions/ADR-014-priority.md)

## Narrative
**As a** System Operator,
**I want** models assigned to the `latency` priority class to preempt `throughput` class models at forward-pass boundaries, while models within the same priority class share contested compute proportionally by measured execution cost,
**So that** latency-critical decision and interactive models respond immediately while heavy background models share remaining capacity fairly.

## Business Context & Domain Rules
- Priority is a model-level business policy set by the operator in the tuning profile (`latency` or `throughput`), never overridden by arbitrary client request flags.
- Whenever a `latency`-class model and a `throughput`-class model contend for overlapping compute cores, the `latency`-class model is scheduled immediately at the next forward-pass boundary.
- When multiple models within the same priority class contend for overlapping cores, the scheduler allocates passes using weighted fair sharing driven by each model's measured execution cost so a heavy model cannot starve a lighter peer.

## Core System Assertions
- **Scenario 1: Latency-class preemption at pass boundary**
  - **Given** a `throughput`-class model actively executing a multi-token generation and a `latency`-class model sharing overlapping compute cores,
  - **When** a request arrives for the `latency`-class model while the `throughput`-class model is mid-pass,
  - **Then** the `throughput`-class model completes its current forward pass, and the scheduler immediately dispatches the `latency`-class model's pass before scheduling further `throughput`-class passes.
- **Scenario 2: Cost-weighted fair sharing within the same priority class**
  - **Given** two models in the same priority class with different measured per-pass execution costs contending for overlapping cores,
  - **When** both models have continuous pending work,
  - **Then** the scheduler interleaves their forward passes at pass boundaries in proportion to their measured cost weights so both achieve fair compute time share.
- **Scenario 3: Rejection of client-supplied priority overrides**
  - **Given** a model configured by the operator in the `throughput` priority class,
  - **When** an external client request attempts to elevate its own execution priority,
  - **Then** the scheduler ignores or rejects the client override and schedules the request strictly according to the model's operator-configured priority class.
