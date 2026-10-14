# Feature: Heterogeneous Core Affinity

## Codename: `core-affinity`

### Architecture Split
SpacemiT K3 combines asymmetric RISC-V cores:
1. **X100 (Cores 0-7, 2.2GHz)**:
   - Microarchitecture: **Out-of-Order (OoO)**.
   - Vector Width: **VLEN = 256 bits** (`zvl256b`).
   - Role: Session routing, HTTP, tokenization, KV cache index.
2. **A100 (Cores 8-15, 1.8GHz)**:
   - Microarchitecture: **In-Order (InO)**.
   - Vector Width: **VLEN = 1024 bits** (`zvl1024b`, 4x wider).
   - Role: High-throughput tensor GEMM, IME, and attention kernels.

### Affinity & HMP Policy
- **VLEN Isolation**: Threads cannot arbitrarily migrate between X100 and A100 due to asymmetric VLEN ABI mismatch.
- **Kernel HMP Interface**: User threads run on X100 by default (`0x00FF`). Compute workers register with HMP / cgroup sets to dispatch onto A100 (`0xFF00`).
