# Feature: Model Management & Storage

## Codename: `model-mgmt`

### Storage Architecture
- Content-addressed store under `/var/lib/k3/blobs/sha256/<digest>` (ADR-035, ADR-036).
- Human-browsable symlink hierarchy under `/var/lib/k3/models/`.
- Manifest records model metadata, architecture recipe, context, and digest.

### Weights & Derivations
- Weights mapped via `mmap` and strictly `mlock`ed into RAM upon load (ADR-037).
- Converted/repacked weights (e.g. IME tiles) stored as derived blobs (ADR-038).

### Source Extensions & Lifecycle
- Out-of-process source extensions pull from Hugging Face, Ollama, and private repos via Apache Arrow IPC (ADR-019).
- Engine capability filter rejects formats/architectures lacking verified recipes (ADR-023).
- Space reclaimed via `k3-admin store gc` and systemd units (ADR-039, ADR-040).
