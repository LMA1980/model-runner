# K3 Uber AI Runtime Manager

Specifications and architectural documentation for the SpacemiT K3 AI platform (16 RISC-V cores, 32GB Unified RAM).

## Repository Ecosystem
Tracked via GitHub Project `model-runner`:
- `model-runner` (This Repo): Master specifications and architecture.
- [`k3-manager`](https://github.com/LMA1980/k3-manager): Control plane, sessions, APIs, and diagnostic CLI.
- [`k3-engine`](https://github.com/LMA1980/k3-engine): Low-level 16-core runtime and vector engine.

## Core Architectural Decisions
- **Stack**: Pure Rust across all layers.
- **Process Model**: Dedicated `k3-manager` process + single-binary `k3-engine` with X100/A100 thread groups.
- **Data Plane**: Zero-copy shared memory ring buffers + UDS control RPC.
- **Execution Rules**: Strict prompt cycle exclusivity; tail-only A100 underfill.

## Navigation
- [Master Plan](PLAN.md)
- [Features Index](features/index.md)
- [Specs Index](specs/index.md)
