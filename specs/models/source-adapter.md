# Spec: Vendor Adapter Interface

## Location: `specs/models/vendor-adapter.md`

### Purpose
Enables private vendors to supply custom repositories and authenticated sources.

### Technical Specification
- **Interface Protocol**: gRPC or executable CLI contract (`pull`, `list`, `auth`).
- **Input**: Model URI (e.g., `vendor://org/model-name:tag`), auth credentials.
- **Output**: Streamed weight blobs or filesystem path after verification.
- **Security**: Sandboxed execution, TLS 1.3 verification, token-based auth.
