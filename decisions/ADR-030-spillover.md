# ADR-030: Spillover

**Status**: Locked

## Context

Idle cores outside a reservation are wasted under strict exclusivity.

## Decision

**Work-stealing**: idle cores anywhere, even outside a model's reservation, can be lent for one pass and taken back at the next pass boundary. **Operator opt-in per model** via `lend_idle_cores` / `borrow_idle_cores` in the tuning-profile, both **off by default**.

## Consequences

Lending is done by dispatch to pre-pinned threads, not cpuset rewrites (ADR-041).
