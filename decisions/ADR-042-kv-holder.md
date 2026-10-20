# ADR-042: KV holder

**Status**: Locked

## Context

KV must survive both engine and manager crashes.

## Decision

**Holding KV (memory) is separate from managing it (policy).** `k3-kv.service` is tiny and policy-free, with its own cgroup (`MemoryMax` = KV budget, `mlock`ed). It allocates the memfd arena, hands fds over UDS, and holds a block-metadata table in shared memory. **Engines write KV values; the manager writes tags** (`purge`/`persist`/`volatile`, project, refcount, committed-token count, sampler RNG state). A manager crash kills the engines (delegated subtree) but KV and progress survive, so the restarted manager resumes (ADR-026). `k3-kv` must not crash: a few hundred lines, heavily tested.

## Consequences

k3-kv is the one component that must not crash; kept minimal.
