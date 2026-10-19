# Feature: Multi-Model Scheduling

## Codename: `multi-model-sched`

### Multi-Model Coexistence
- Supports concurrent model placements (up to `max_active_models`, default 3) within 32GB RAM (ADR-043).
- Model core reservations may overlap across clusters (ADR-006).

### Scheduling & Arbitration
- Contested cores time-sliced strictly at forward-pass boundaries (ADR-006).
- Priority classes: `latency` class passes always preempt `throughput` class passes; weighted fair sharing by measured cost within class (ADR-014).
- Decision models (`tev1`, `nimble`) serve client requests and act as internal router for `model: auto` (ADR-013).

### Admission & Queuing
- Bounded FIFO queue per model (default depth 64); wait timeout disabled by default (ADR-015).
- Over-capacity queues emit 429/529 with `Retry-After`; active queues stream SSE keep-alive comments.
