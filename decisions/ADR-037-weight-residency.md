# ADR-037: Weight residency

**Status**: Locked

## Context

Page-cache eviction of mmap'd weights would stall forward passes unpredictably, while an unbounded `LimitMEMLOCK=infinity` risks system-wide hard lockups if 100% of physical RAM becomes locked.

## Decision

Weights are **always `mlock`ed** while loaded; not configurable. Requires `CAP_IPC_LOCK` and an operator-allocated fixed `LimitMEMLOCK` / `RLIMIT_MEMLOCK` ceiling sized to the board (on the 32 GiB K3 reference board, **28 GiB** is allocated, reserving **4 GiB** for the OS kernel and remaining processes; `LimitMEMLOCK=infinity` is strictly a last resort). Huge pages are best-effort. The locked size counts against the ADR-027 RAM and `RLIMIT_MEMLOCK` admission check.

## Consequences

systemd units and limits configure a bounded `LimitMEMLOCK` (28 GiB on 32 GiB K3); loaded weights count against RAM and lockable-memory admission.
