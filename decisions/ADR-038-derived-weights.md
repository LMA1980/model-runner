# ADR-038: Derived weights

**Status**: Locked

## Context
Safetensors and IME tile layouts need converted weights.

## Decision
Converted/repacked weights (Safetensors→native, IME tile layouts) are kept as **derived blobs** keyed by `(source digest, recipe version, kernel layout)`. The operator chooses whether to keep the original, purge it, or purge it after a delay. After a breaking runtime change, stale derived blobs are flagged and the operator is invited to re-download the original. Every loaded layout counts against RAM admission.

## Consequences
Breaking runtime changes invite re-downloading originals.
