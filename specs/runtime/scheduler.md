# Spec: Core Scheduler

## Location: `specs/runtime/scheduler.md`

### Dual-Pool & Overlapping Reservations
- X100 Pool (`0x00FF`, OoO, VLEN=256) & A100 Pool (`0xFF00`, InO, VLEN=1024 + IME) (ADR-006, ADR-007).
- Reservations may overlap; scheduler time-slices at forward-pass boundaries.

### Priority & Work-Stealing
- Priority classes: `latency` class preempts `throughput` class (ADR-014).
- Fair sharing: Weighted fair queuing within class based on measured pass cost.
- Work-stealing: Borrows idle cores across reservations per pass when opted in (ADR-030).
