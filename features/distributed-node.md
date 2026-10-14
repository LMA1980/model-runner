# Feature: Distributed Node Architecture

## Codename: `distributed-arch`

### Business Logic
Enables unified operation whether running entirely locally on one K3 or scaled across heterogeneous nodes.

### Topology Modes
1. **Unified Local Mode**:
   - All subsystems (Ingress, Session, KV Cache, and Inference) run locally on a single K3 SoC.
   - Zero IPC overhead via shared memory and local DMA.
2. **Disaggregated / Multi-Node Mode**:
   - Control Plane, session history, and KV index reside on an external host (e.g. x86_64 server).
   - One or more K3 boards act as dedicated A100/X100 compute accelerators over network RPC.
3. **Pragmatic Scaling**:
   - No remote memory access (NUMA/RDMA); nodes operate as autonomous worker units.
