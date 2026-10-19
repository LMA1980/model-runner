# Feature: Model Tuning & Profiles

## Codename: `tuning-profile`

### Operator Authority
- Operator profile is authoritative over placement, reservations, `n_ctx`, and priority class (ADR-032).
- Daemon measures online costs solely to suggest recommendations (`k3 tune suggest`) and balance fair time-slicing (ADR-010).

### Cycle Exclusivity & Tail Underfill
- Strictly one prompt per forward pass; no cross-prompt batching (ADR-005).
- Underfill allowed only at the tail of a prompt's sequence.

### Profile Attributes
- `core_reservation`: X100 and A100 core counts (ADR-006).
- `priority_class`: `latency` (e.g. decision models) or `throughput` (ADR-014).
- `lend_idle_cores` / `borrow_idle_cores`: Opt-in work-stealing, default off (ADR-030).
- `n_ctx`: Fixed context window bound (ADR-027).
- Unprofiled models load with conservative X100-only defaults (ADR-031).
