# US-05: Isolated Compute Worker Execution & Zero-Copy Tensor Dispatch

- **Milestone**: [M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)
- **Status**: Completed
- **GitHub Issue**: [#5](https://github.com/LMA1980/model-runner/issues/5)
- **Feature Ref**: [Distributed Node Architecture](../features/distributed-node.md), [KV Cache Management](../features/kv-cache.md)
- **Spec Ref**: [Process Model & IPC](../specs/runtime/process-model.md), [System Isolation & CGroups](../specs/runtime/isolation.md)
- **Related ADRs**: [ADR-018](../decisions/ADR-018-process-model.md), [ADR-041](../decisions/ADR-041-isolation-domains.md), [ADR-042](../decisions/ADR-042-kv-holder.md)

## Narrative

**As a** Platform Architect / Operator,
**I want** model compute workers to execute in fault-isolated runtime domains separated from control orchestration and context memory while exchanging tensor payloads without memory copying,
**So that** a compute kernel fault or runaway worker never corrupts session state, other active models, or cached context data.

## Business Context & Domain Rules

- High-performance inference requires zero-copy access to shared tensor buffers and context state, yet running orchestration, context storage, and model compute in a single fault domain risks losing all active sessions if a single model faults.
- The runtime separates responsibilities into three distinct local isolation domains:
  1. **Control domain**: Orchestrates sessions, tokenization, routing, and scheduling policies.
  1. **Compute worker domain**: Executes model forward passes per model placement with no external network access and read-only access to model weights.
  1. **Context memory holder domain**: Retains active context memory arenas independently of both control and compute lifecycles.
- Control dispatches and bulk tensor accesses across local domains must operate in place without duplicating payload bytes in unified memory.

## Core System Assertions

- **Scenario 1: Zero-copy forward-pass command and tensor dispatch**
  - **Given** an active control service, a context memory holder, and an isolated model compute worker on the same board,
  - **When** the control service dispatches a forward-pass command referencing shared input tokens and context memory blocks,
  - **Then** the compute worker reads inputs and writes output activations in place without copying bulk tensor payloads across memory.
- **Scenario 2: Fault containment upon compute worker failure**
  - **Given** an isolated model compute worker executing a forward pass while other models and sessions are active,
  - **When** the compute worker terminates abnormally or encounters an unrecoverable execution fault,
  - **Then** the control plane and context memory holder remain intact and operational, other loaded models continue serving unaffected, and the failed worker can be restarted cleanly.
