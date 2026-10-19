# ADR-015: Admission / queue

**Status**: Locked

## Context
Strict exclusivity means queues; the product accepts slowness rather than cutting users off.

## Decision
**Patience over rejection.** Deep per-model FIFO (e.g. 64, configurable), wait timeout off by default, SSE keep-alive + queue-position comments. 429/529 + `Retry-After` only when an operator-set cap is hit. **No token or usage quotas.**

## Consequences
Queue memory needs its own cap; streaming clients need keep-alives to avoid timeouts.
