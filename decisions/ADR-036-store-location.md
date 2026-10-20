# ADR-036: Store location

**Status**: Locked

## Context

Operators run different storage setups.

## Decision

Default root **`/var/lib/k3`** (replaces `/var/lib/k3-ai`), configurable. Fast storage, e.g. an NVMe bind mount `/mnt/nvme/k3-var-lib` → `/var/lib/k3`, is documented as a **recommendation only**; the operator decides.

## Consequences

Docs recommend fast storage; the operator decides.
