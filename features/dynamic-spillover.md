# Feature: Dynamic Unified Memory Balancing

## Codename: `dynamic-spillover`

### Business Logic
SpacemiT K3 features 32GB unified RAM shared by both X100 and A100. Workloads dynamically balance across clusters without memory copies.

### Bidirectional Work-Stealing
1. **A100 Saturated -> Spill to X100**:
   - When A100 vector cores are fully engaged with large generative batches, small token requests (e.g., decision models, short chat replies) spill to idle X100 cores.
   - X100's Out-of-Order execution provides fast TTFT for compact jobs.
2. **A100 Idle -> Offload from X100**:
   - When A100 is idle, X100 offloads heavy prefill chunks and vector embeddings to A100's 1024-bit compute units.

### Zero-Copy Unified Data Plane
- Model weights and paged KV cache reside in unified physical memory.
- Separate X100 and A100 worker pools read identical buffer pointers.
- Eliminates thread migration crashes while maximizing 16-core utilization.
