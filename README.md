# K3 Uber AI Runtime Manager

Master specifications and architecture for SpacemiT K3 AI platform (16 RISC-V cores, 32GB Unified RAM).

## Repository Ecosystem
Tracked via GitHub Project `model-runner`:
- `model-runner` (This Repo): Architecture, specifications, and [ADRs](decisions/index.md).
- [`k3-manager`](code/manager): IPC daemon, session SQLite state, and extension host.
- [`k3-engine`](code/engine): Compute engine, VLA RVV 1.0 / IME kernels, sync spikes.

## Core Architecture
- **Isolation**: systemd cgroup v2 slices (`k3.slice`: control, compute, kv, edge) (ADR-041).
- **IPC**: Internal rkyv over UDS + memfd shared memory; Apache Fory for out-of-process extensions (ADR-018, ADR-019).
- **Execution**: Strict one prompt per forward pass; operator tuning authority (ADR-005, ADR-032).
- **Storage**: Content-addressed store at `/var/lib/k3` with `k3-admin` GC (ADR-035, ADR-039).

## Navigation
- [Master Plan](PLAN.md) | [Intent](INTENT.md) | [Decisions](decisions/index.md)
- [Features](features/index.md) | [Specs](specs/index.md) | [User Stories](user-story/index.md) | [Lab Environment](LAB.md)
