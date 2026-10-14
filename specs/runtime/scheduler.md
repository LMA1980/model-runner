# Spec: Core Scheduler

## Location: `specs/runtime/scheduler.md`

### Asymmetric Dual-Pool Architecture
- **X100 Pool (Cores 0-7)**:
  - Mask: `0x00FF`, Arch: OoO, VLEN=256-bit (`-mcpu=spacemit-x100`)
  - Role: Ingress, session routing, small/spillover token execution
- **A100 Pool (Cores 8-15)**:
  - Mask: `0xFF00`, Arch: InO, VLEN=1024-bit (`-mcpu=spacemit-a100`)
  - Role: Dense batch GEMM, attention kernels, heavy prefill

### Dynamic Work-Stealing over Unified RAM
- Weights and paged KV cache are mapped into shared physical memory.
- **Spillover**: If A100 queue latency exceeds SLA threshold, dispatch small batch tokens to X100 pool.
- **Acceleration**: If A100 is idle, X100 pushes prefill chunks to A100.
- Threads remain pinned within their respective pools, passing token buffer descriptors via lock-free ring queues.
