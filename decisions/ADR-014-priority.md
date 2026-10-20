# ADR-014: Priority

**Status**: Locked

## Context

A fast-path queue and an undefined 'SLA threshold' existed with no source of priority.

## Decision

Per model, set in the tuning-profile (`latency` / `throughput`). Weighted-fair by measured cost within a class; latency class goes first. No per-request override.

## Consequences

Priority is operator configuration, not a client choice.
