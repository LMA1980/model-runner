# ADR-043: Per-model isolation

**Status**: Locked

## Context

KV memory lives in k3-kv's cgroup, so engine cgroups cannot bound a model's context.

## Decision

**No model can burst into another's memory, by construction.** At load time `k3-kv` creates a **dedicated memfd arena per model placement**, sized to `n_ctx × active slots × KV bytes/token` (ADR-027), first-touched and `mlock`ed. Blocks come only from the model's own arena; when it is full, LRU eviction happens inside that arena or the request waits. The engine cgroup `engines/<model>` caps weights + derived layouts + scratch (`MemoryMax`), `pids.max` and the cpuset. Operator-set **`max_active_models`** (default **3**) is checked at load time. Expect to trade accuracy (smaller quants or models) for running several at once.

## Consequences

At most 3 active models by default; accuracy traded for concurrency.
