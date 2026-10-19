# ADR-031: Unprofiled models

**Status**: Locked

## Context
Freshly pulled models have no diag cost profile.

## Decision
Load with the **shipped conservative default**: X100-only, `throughput` class, small `n_ctx`, lending/borrowing off. Flagged "unprofiled" in `/v1/models` and the logs, with a prompt to tune. The profile changes only when the operator applies one.

## Consequences
Unprofiled models are safe but slow until the operator applies a profile.
