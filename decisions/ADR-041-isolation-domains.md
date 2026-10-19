# ADR-041: Isolation domains

**Status**: Locked

## Context
Manager, engines and extensions need distinct resource limits and privileges.

## Decision
**systemd + cgroup v2 + namespaces, no runc** (runc/OCI is kept for the future multi-tenant/hypervisor step, ADR-008). `k3.slice` holds: **control**: `k3-manager.service` on the reserved X100 cores, no network, the manager moves itself into a leaf (`.../control`); **compute**: delegated subtree `.../engines/<model>` (`Delegate=yes`), cpuset = reservation ∪ lendable cores, no network, read-only store + lock files; **kv**: `k3-kv.service` (ADR-042); **edge**: `k3-ext@<name>.service`, the only domain with network, IPC socket only, no store or shared-memory access. Shared memory = `memfd_create` + `SCM_RIGHTS` over UDS (no shared `/dev/shm` or IPC namespace).

## Consequences
Manager restarts kill delegated engines; KV survives in k3-kv (ADR-042).
