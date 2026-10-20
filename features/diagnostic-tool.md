# Feature: Operator Diagnostic Tool

## Codename: `diag-tool`

### Purpose & Delivery

Non-interactive CLI for single-model benchmarking and cost baseline profiling (ADR-010).

### CLI Capabilities

- Standalone spikes in `k3-engine`: `k3-diag-spin`, `k3-diag-futex`, `k3-diag-rayon`.
- Options:
  - `--cluster <both|x100|a100>`: Target core clusters.
  - `--split <phase|op|row>`: Cross-cluster work distribution (ADR-009).
  - `--ime <on|off>`: Toggle SpacemiT IME matrix intrinsics (ADR-034).
  - `--threads <n>`, `--cores <mask>`, `--repeat <n>`.

### Metrics & Self-Comparison

- Measures prefill and decode separately against hardware ceilings (ADR-034).
- Checks bit-identical output at temperature 0 across `--repeat` runs.
- Emits cost profile JSON (`--json`) consumed by `k3 tune` recommendations (ADR-010, ADR-032).
