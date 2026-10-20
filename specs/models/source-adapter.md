# Spec: Model Source Adapter Interface

## Location: `specs/models/source-adapter.md`

### Purpose
External adapter interface for pulling weights from external repositories (ADR-019).

### Protocol Specification
- Out-of-process sidecar speaking Apache Arrow IPC over UDS.
- Methods: `auth`, `search`, `list`, `pull`.
- Downloads write to `/var/lib/k3/tmp/` and atomically `rename()` to `blobs/` upon SHA-256 validation (ADR-040).
- Adapters isolate third-party SDKs and credentials outside the control daemon.
