# Spec: Process Model & IPC

## Location: `specs/runtime/process-model.md`

### Process Architecture
- `k3-manager`: Supervises runtime, owns tokenization, session state, and SQLite (ADR-018, ADR-025).
- `k3-kv`: Independent KV memory holder (ADR-042).
- `k3-engine`: Isolated worker processes per model placement (ADR-018, ADR-043).

### Inter-Process Communication
- Control plane: `rkyv` serialization over Unix Domain Sockets.
- Tensor/KV transport: Zero-copy `memfd` file descriptors passed via `SCM_RIGHTS`.
- Out-of-process extensions: Apache Fory over UDS (ADR-019).
