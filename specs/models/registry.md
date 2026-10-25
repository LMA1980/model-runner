# Spec: Model Registry & Formats

## Location: `specs/models/registry.md`

### Store Hierarchy

- Path: `/var/lib/k3/blobs/sha256/<digest>` (ADR-035, ADR-036).
- Symlinks: `/var/lib/k3/models/<source>/<model>/<tag>/`.
- Manifests: Store SHA-256 digest, quant, recipe, and context bounds.
- Model build identity: `(blob_digest, recipe_version)` (ADR-035).

### Format Support & Capability Filter

- Formats: GGUF, Safetensors, OCI/Ollama layers (ADR-017).
- Engine filter: Rejects models lacking compiled architecture recipes (ADR-023).
- Derived blobs: Repacked IME tiles and converted formats cached on disk (ADR-038).

### Remote Distribution & Node Memory Residency

- **Head Node Ingestion**: In multi-host topologies, the head node (`k3-manager`) ingests GGUF/Safetensors blobs, executes capability filtering (ADR-023), and repacks tensors to the IME tile layout (ADR-038).
- **Arrow Flight Transfer**: Tensors are transferred to target K3 nodes over Apache Arrow Flight without requiring local node internet access or third-party hub credentials.
- **Hybrid Storage Modes**: Target K3 nodes can retain the incoming model purely in an ephemeral `mlock`ed `memfd` (zero disk writes, flash protection), or persist a local `.arrow` derived blob cache in `/var/lib/k3/blobs/` for instant offline reboot recovery.
