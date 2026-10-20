# ADR-039: Disk lifecycle

**Status**: Locked

## Context

Blobs, derived layouts and purges accumulate on disk; operators have site-specific policies.

## Decision

**Operator-driven, reference-counted.** `k3 model rm` removes manifests; unreferenced or stale blobs are only deleted by GC. A dedicated operator tool, **`k3-admin`** (in the style of `mysqladmin`), whose policy is configured through the manager. GC runs as systemd **`k3-store-gc.service`** (oneshot), triggered by a **`.timer`** and/or an event-based **`.path`** unit (e.g. the manager writes `/run/k3/gc.request`). A disk high-water mark warns only.

## Consequences

GC never deletes automatically on thresholds; it runs as systemd units.
