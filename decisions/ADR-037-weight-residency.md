# ADR-037: Weight residency

**Status**: Locked

## Context
Page-cache eviction of mmap'd weights would stall forward passes unpredictably.

## Decision
Weights are **always `mlock`ed** while loaded; not configurable. Requires `CAP_IPC_LOCK` / `LimitMEMLOCK=infinity` in the systemd unit. Huge pages are best-effort. The locked size counts against the ADR-027 RAM admission check.

## Consequences
systemd units need CAP_IPC_LOCK; loaded weights count against RAM admission.
