# Spec: Process Model & IPC

## Location: `specs/runtime/process-model.md`

### Process Architecture

- `k3-manager`: Supervises runtime, owns tokenization, session state, and SQLite (ADR-018, ADR-025).
- `k3-kv`: Independent KV memory holder (ADR-042).
- `k3-engine`: Isolated worker processes per model placement (ADR-018, ADR-043).

### Inter-Process Communication

- Control plane: Apache Fory (`fory`) serialization over Unix Domain Sockets (ADR-018).
- Shared memory headers & rings: `zerocopy` `#[repr(C)]` structs in `memfd` arenas passed via `SCM_RIGHTS` (ADR-018, ADR-042).
- Columnar tensor views & extensions: Apache Arrow buffers/IPC over `memfd` and UDS (ADR-018, ADR-019).
