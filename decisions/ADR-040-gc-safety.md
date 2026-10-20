# ADR-040: GC safety

**Status**: Locked

## Context

GC must not delete blobs mapped by engines or partially written by pulls.

## Decision

**Two checks:** (1) engines hold `flock(LOCK_SH)` on mapped blobs and GC takes `LOCK_EX|LOCK_NB`, skipping busy ones; (2) a `/proc/*/maps` scan confirms no `k3-engine` still maps the blob, which **works with the manager offline**. Pulls and conversions write to `/var/lib/k3/tmp/` and atomically `rename()` only after verification. `k3-admin store who-uses <blob>` exposes the scan. GC runs as the same `k3` user as the engines so it can read their maps.

## Consequences

GC runs as the k3 user; works without the manager.
