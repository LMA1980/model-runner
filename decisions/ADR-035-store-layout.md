# ADR-035: Store layout

**Status**: Locked

## Context

The same weights may come from several sources; caches need a stable model_build identity.

## Decision

**Content-addressed** `blobs/sha256/<digest>` (deduplicated across sources) + `manifests/<source>/<model>/<tag>.json` (format, architecture/recipe, quant, trained context, licence, origin) + a **human-browsable symlink tree** for operators. `model_build` = weights blob digest + recipe version (feeds ADR-004, ADR-026).

## Consequences

Operators browse via symlinks; tooling works on digests.
