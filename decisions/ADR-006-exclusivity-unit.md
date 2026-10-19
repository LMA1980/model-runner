# ADR-006: Exclusivity unit

**Status**: Locked

## Context
Models need predictable core budgets in both clusters, but 16 cores cannot be statically partitioned for 3 models.

## Decision
Per **model placement**: a core reservation in *both* clusters (e.g. tev1 = 2X+2A, Gemma4-Flash = 6X+8A). Reservations may **overlap** and are time-sliced at forward-pass boundaries.

## Consequences
Scheduler arbitrates contested cores at pass boundaries; per-model cost profiles drive fairness (ADR-014).
