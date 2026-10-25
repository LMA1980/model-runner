# Spec: Model Source Adapter Interface

## Location: `specs/models/source-adapter.md`

### Purpose

External adapter interface for pulling weights from external repositories (ADR-019).

### Protocol Specification

- Out-of-process sidecar speaking Apache Arrow IPC over UDS.
- Methods: `auth`, `search`, `list`, `pull`.
- Downloads write to `/var/lib/k3/tmp/` and atomically `rename()` to `blobs/` upon SHA-256 validation (ADR-040).
- Adapters isolate third-party SDKs and credentials outside the control daemon.

### Distributed Model Migration via Apache Arrow Flight

- **Decoupled Roles**: The control plane daemon (`k3-manager`) executes model acquisition (via source extensions) and format conversion / IME tile repacking (ADR-038) on host nodes (e.g. `entrance` or `rubicon`), offloading heavy downloads, SHA-256 validation, and repacking compute from target K3 boards.
- **Arrow Flight Transport**: Preprocessed, IME-tiled model tensors are streamed to target K3 accelerator nodes (`pey-wail-deu`) using the Apache Arrow Flight protocol (`arrow-flight` over gRPC / HTTP/2 or QUIC).
- **Zero-Copy Receiver**: The node agent / bridge (`k3-rpcbridge`) streams incoming `FlightData` chunks directly into an aligned anonymous shared memory segment (`memfd_create`), calls `mlock()` to satisfy residency requirements (ADR-037), applies seals (`F_SEAL_WRITE`), and passes the sealed descriptor to `k3-worker` via `SCM_RIGHTS` over UDS.
- **Flash Endurance**: Target nodes avoid repetitive flash writes and wear on local eMMC/SD storage; models can reside ephemerally in RAM or be cached optionally as derived `.arrow` blobs on local disk (ADR-038).
