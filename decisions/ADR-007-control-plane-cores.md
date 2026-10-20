# ADR-007: Control plane cores

**Status**: Locked

## Context

INTENT keeps session management on X100; model reservations could otherwise consume every X100 core.

## Decision

Reserved X100 threads (default 3 = 2 active + 1 spare to recover a runaway thread; configurable down to 1). Round-robin. Only compute threads are pinned; X100 compute is capped at 6 by default.

## Consequences

A spare control thread can recover a runaway thread; X100 compute defaults to 6 cores.
