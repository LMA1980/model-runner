# ADR-018: Process model

**Status**: Locked

## Context

A kernel crash or runaway thread must not take down session state, and internal IPC must support multi-language and cross-version interoperability without proprietary archive lock-in.

## Decision

`k3-manager` supervises separate `k3-engine` processes and communicates with `k3-kv`.

- **Control plane IPC**: **Apache Fory** (`fory`) over Unix Domain Sockets (UDS) for low-latency, schema-evolving command and status serialization.
- **In-place shared memory**: **`zerocopy`** (`#[repr(C)]`, `FromBytes`, `IntoBytes`, `KnownLayout`, `Immutable`) structs and ring headers inside `memfd` segments passed via `SCM_RIGHTS` for KV block metadata, token/logit slabs, and synchronization headers.
- **Columnar / batch tensor transport**: **Apache Arrow** (`arrow-buffer` / `arrow-array` / `arrow-ipc`) zero-copy views over shared memory and UDS for structured tensor batches and out-of-process extensions (ADR-019).

## Consequences

Control uses Apache Fory over UDS; fixed shared-memory headers and rings use `zerocopy` in place; columnar tensor batches and extensions use Apache Arrow. Bulk tensor payloads are never copied across processes.
