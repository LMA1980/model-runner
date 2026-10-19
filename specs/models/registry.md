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
