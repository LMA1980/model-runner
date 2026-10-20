# Feature: KV Cache Management

## Codename: `kv-cache`

### Memory Strategy & Allocation

- Operates strictly in unified RAM for v1; swap/NVMe tiers deferred (ADR-016).
- Managed via dedicated `k3-kv` process holding memfd arenas (ADR-042).
- Per-model dedicated arenas sized to `n_ctx * slots * bytes_per_tok` prevent context bursting (ADR-043).

### Prefix Caching & Prompt Sharing

- Radix tree lookup on token IDs: `(project_id, model_id, model_build, tokens)` (ADR-004).
- Paged allocation in fixed 16-token blocks with Copy-On-Write (COW).
- Eviction policy: LRU within project/model arena when budget ceiling reached.

### Context Limits & Patience

- Fixed `n_ctx` per model placement; oversize requests return `context_length_exceeded` (ADR-027).
- No token quotas; incoming volume queues gracefully with keep-alive pings (ADR-015).
