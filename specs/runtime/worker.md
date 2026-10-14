# Spec: Inference Worker

## Location: `specs/runtime/worker.md`

### A100 Compute Engine (Cores 8-15)
- **Arch**: In-Order dual-issue, VLEN = 1024 bits (`zvl1024b`, 128B/reg).
- **Compiler**: `-mcpu=spacemit-a100 -mrvv-vector-bits=1024`.
- **Acceleration**: IME matrix kernels, `xsmtvdotii`, FlashAttention (`vlen1024`).

### Prompt Isolation & Tail Underfill
- **No Cross-Prompt Co-Scheduling**: An execution cycle processes tokens for exactly one prompt. Never co-pack prompts into the same SIMD cycle.
- **Tail Underfill**: Underfill (`avl < VLMAX`) is allowed only for prompt tail batches or single-token decode steps.

### Zero-Copy IPC Data Path
- Worker pool bound to CPUs 8-15 (`0xFF00`).
- Lock-free ring buffer for requests from X100.
- Zero-copy tensor buffers via unified memory and `/dev/ai_dma`.
- Logits streamed back to X100 token queues.
