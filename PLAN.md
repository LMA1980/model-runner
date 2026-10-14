# K3 AI Runtime Master Plan

## 1. Architecture Ecosystem
Specification repo for SpacemiT K3 AI platform.
Code lives in `k3-manager` (control plane) and `k3-engine` (runtime).

## 2. Locked Core Decisions
- **Stack**: Pure Rust across all layers; strict native `riscv64` target.
- **IPC**: Apache Fury serialization over UDS + shared memory for bulky tensors.
- **Compute**: Unified VLA RVV 1.0 loops with A100 IME; Qwen/LLaMA Q4_K_M first.
- **Sync**: 3 diagnostic spikes (spin, futex, rayon) with unified CLI.
- **State**: Active in-memory sessions backed by SQLite for reboot persistence.

## 3. Roadmap
1. **Stage 1 (Direct Evaluation)**: 3 sync CLI spikes in `k3-engine` on K3.
2. **Stage 2 (Manager Integration)**: `k3-manager` IPC daemon + Fury + search/pull.
3. **Stage 3 (Ecosystem)**: Modular WebAPI (HTTP/3 spike), OpenAI/Claude, MCP host.

## Navigation
- [Features](features/index.md)
- [Specs](specs/index.md)
