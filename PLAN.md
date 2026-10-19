# K3 AI Runtime Master Plan

## 1. Architecture Ecosystem
- Spec repo: `model-runner`.
- Control plane: `k3-manager` (IPC daemon, session SQLite state).
- Compute runtime: `k3-engine` (16-core runtime, VLA RVV loops, IME).
- Memory holder: `k3-kv` (dedicated KV memfd arena holder).

## 2. Locked Core Decisions
- **Stack**: Pure Rust (first-party); strict native `riscv64` target.
- **IPC**: Apache Fory for external adapters/extensions; rkyv + shared memory for internal daemon IPC (ADR-018, ADR-019).
- **Compute**: Inline asm RVV 1.0 + IME; track nightly Rust scalable vectors (ADR-029).
- **Sync**: 3 diagnostic spikes (spin, futex, rayon) with unified CLI.
- **Tenancy**: Tenant -> Project -> Session (ADR-001). RAM-only KV holder (ADR-042).

## 3. Roadmap & Milestones ([User Stories](user-story/index.md))
- **M1 (Core Evaluation & Profiling)**: [M1 Stories](user-story/milestone-01.us-index.md) - `k3-diag` Stage 1 spikes, cluster benchmarking, and isolated IPC domains.
- **M2 (Multi-Model Runtime & Memory)**: [M2 Stories](user-story/milestone-02.us-index.md) - Tuning profiles, priority scheduling, KV arenas, and crash resumption.
- **M3 (Storage & External Protocols)**: [M3 Stories](user-story/milestone-03.us-index.md) - Content-addressed store, GC, and Fory source/front-end extensions.
