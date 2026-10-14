# Spec: Paged KV Allocator

## Location: `specs/memory/kv-allocator.md`

### Purpose
Provides dynamic, zero-fragmentation KV cache block management.

### Technical Specification
- **Block Size**: 16 tokens per physical block.
- **Block Table**: Logical-to-physical block table maintained on X100.
- **Allocation Strategy**:
  - Prefix match using radix tree lookup on token IDs.
  - Copy-On-Write (COW) for branchings or parallel samples.
  - LRU eviction of unreferenced blocks when cache budget is reached.
- **Budgeting**: User-configurable memory ceiling (e.g., up to 20GB of 32GB RAM).
