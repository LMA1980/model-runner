# ADR-018: Process model

**Status**: Locked

## Context

A kernel crash or runaway thread must not take down session state.

## Decision

`k3-manager` supervises separate `k3-engine` processes. `rkyv` over UDS for control; `#[repr(C)]` structs in shared memory for tensors and rings.

## Consequences

Control uses rkyv over UDS; bulk data stays in shared memory, read in place.
