# ADR-032: Tuning authority

**Status**: Locked

## Context

Correct tuning depends on the application the board serves.

## Decision

**The operator owns tuning.** The right settings depend on the application the board serves. The tuning-profile (placement, reservation, `n_ctx`, priority class, lending) is authoritative. K3 provides diag-tool measurements and recommendations, never automatic changes.

## Consequences

K3 recommends (k3 tune suggest); it never applies changes automatically.
