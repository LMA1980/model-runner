# Spec: Paged KV Allocator

## Location: `specs/memory/kv-allocator.md`

### Architecture & Allocation

- Operates on memfd shared memory backed by `k3-kv` (ADR-042).
- Block size: 16 tokens per block.
- Radix tree prefix index: Keyed on `(project_id, model_id, model_build, tokens)` (ADR-004).
- Copy-On-Write (COW) for branchings; LRU eviction within model arena (ADR-043).

### Budgeting & Context

- Sized strictly to `n_ctx * slots` per model placement (ADR-027, ADR-043).
- Resumption: Tracks committed tokens in shared metadata table (ADR-026).
