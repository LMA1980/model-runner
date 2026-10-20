# K3 Uber AI Runtime Manager

[![K3 CI Status](https://hook.lma1980.duckdns.org/badges/LMA1980/model-runner/main/status.svg)](https://hook.lma1980.duckdns.org/jobs)
[![Shields CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fhook.lma1980.duckdns.org%2Fbadges%2FLMA1980%2Fmodel-runner%2Fmain%2Fshield.json)](https://hook.lma1980.duckdns.org/jobs)

<p align="center">
  <a href="https://hook.lma1980.duckdns.org/jobs">
    <img src="https://hook.lma1980.duckdns.org/cards/LMA1980/model-runner/main/card.svg" alt="K3 Native CI Branch Health Card" />
  </a>
</p>

Master specifications and architecture for SpacemiT K3 AI platform (16 RISC-V cores, 32GB Unified RAM).

## Repository Ecosystem

Tracked via GitHub Project `model-runner`:

- `model-runner` (This Repo): Architecture, specifications, and [ADRs](decisions/index.md).
- [`k3-manager`](code/manager): IPC daemon, session SQLite state, and extension host.
- [`k3-engine`](code/engine): Compute engine, VLA RVV 1.0 / IME kernels, sync spikes.

## Core Architecture

- **Isolation**: systemd cgroup v2 slices (`k3.slice`: control, compute, kv, edge) (ADR-041).
- **IPC**: Internal rkyv over UDS + memfd shared memory; Apache Arrow for out-of-process extensions (ADR-018, ADR-019).
- **Execution**: Strict one prompt per forward pass; operator tuning authority (ADR-005, ADR-032).
- **Storage**: Content-addressed store at `/var/lib/k3` with `k3-admin` GC (ADR-035, ADR-039).

## Navigation

- [Master Plan](PLAN.md) | [Intent](INTENT.md) | [Decisions](decisions/index.md)
- [Features](features/index.md) | [Specs](specs/index.md) | [User Stories](user-story/index.md) | [Lab Environment](LAB.md)
