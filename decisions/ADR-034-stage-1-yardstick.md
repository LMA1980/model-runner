# ADR-034: Stage 1 yardstick

**Status**: Locked

## Context
Without an external baseline, Stage 1 needs a meaningful yardstick.

## Decision
Compare against itself: same recipe/kernels with `--cluster x100` vs `--cluster a100` (IME on/off), prefill and decode measured separately. Each phase is reported as a ratio of the hardware ceiling (memory bandwidth for decode, peak RVV/IME throughput for prefill). No pass/fail threshold; the operator decides placement (ADR-032).

## Consequences
diag-tool reports per-phase metrics against hardware ceilings.
