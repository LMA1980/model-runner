# K3 Uber AI Runtime Manager

Specifications and architectural documentation for the SpacemiT K3 AI platform (16 RISC-V cores, 32GB Unified RAM).

## Repository Ecosystem
Tracked via GitHub Project `model-runner`:
- `model-runner` (This Repo): Master specifications and architecture.
- [`k3-manager`](https://github.com/LMA1980/k3-manager): IPC daemon, session SQLite state, and modular WebAPI.
- [`k3-engine`](https://github.com/LMA1980/k3-engine): Low-level 16-core runtime, VLA RVV loops, and sync spikes.

## Core Architectural Decisions
- **Stack**: Pure Rust across all layers; strict native `riscv64` target.
- **IPC**: Apache Fury serialization over UDS + shared memory for bulky tensors.
- **Compute**: Unified VLA RVV 1.0 kernels with A100 IME; Qwen/LLaMA Q4_K_M first.
- **Diagnostics**: 3 sync spikes (`spin`, `futex`, `rayon`) with unified CLI.

## Navigation
- [Master Plan](PLAN.md)
- [Features Index](features/index.md)
- [Specs Index](specs/index.md)
