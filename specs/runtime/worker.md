# Spec: Inference Worker

## Location: `specs/runtime/worker.md`

### Architecture & Compute Kernels
- **Target**: Strict native `riscv64` only; no host fallback abstraction overhead.
- **Kernels**: Unified Vector-Length-Agnostic (VLA) RVV 1.0 loops via dynamic `vsetvli` scaling across 256-bit (X100) and 1024-bit (A100).
- **Acceleration**: Direct branch to SpacemiT IME matrix intrinsics (`xsmtvdotii`) on A100.
- **Model Target**: Qwen/LLaMA transformer family; Q4_K_M quantization first.

### Memory & KV Cache
- **Weights**: Zero-copy `mmap(MAP_SHARED)` with `madvise(MADV_WILLNEED | MADV_HUGEPAGE)`.
- **KV Cache**: Direct paged 16-token block allocator in unified memory.

### Prompt Cycle Rules
- **Cycle Exclusivity**: Tokens for exactly one prompt per execution cycle.
- **Tail Underfill**: Underfill (`avl < VLMAX`) allowed strictly for prompt tails or decode.
