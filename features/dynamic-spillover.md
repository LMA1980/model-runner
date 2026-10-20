# Feature: Dynamic Unified Memory Balancing

## Codename: `dynamic-spillover`

### Work-Stealing Model

- Cores outside a model's reservation may be borrowed on a per-pass basis when idle (ADR-030).
- Strict operator opt-in per model via `lend_idle_cores` and `borrow_idle_cores` (default false) (ADR-030, ADR-032).

### Pass-Boundary Reclaim

- Borrowed cores are reclaimed immediately at forward-pass boundaries without interrupting executing passes.
- Dispatched across pre-pinned worker threads; no runtime cpuset re-allocation overhead (ADR-041).

### Cluster Agnostic Balancing

- Does not assume A100 superiority; placements and lending are evaluated empirically via Stage 1 spikes (ADR-028, ADR-034).
- Shared physical memory backing allows zero-copy descriptor dispatch between pools.
