# Spec: Inference Worker

## Location: `specs/runtime/worker.md`

### Kernel & Architecture Recipes

- Strict native `riscv64` target; pure Rust with inline `asm!` RVV 1.0 + IME (ADR-029).
- Architecture recipes compiled as modular crates (`arch-*`, `kernels-*`) (ADR-024).

### Execution & Safety

- Strict cycle exclusivity: exactly one prompt per forward pass (ADR-005).
- Weights loaded via `mmap` with `mlock` and `flock(LOCK_SH)` (ADR-037, ADR-040).
- Committed token checkpoints allow resume after engine restarts (ADR-026).
