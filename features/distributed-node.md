# Feature: Distributed Node Architecture

## Codename: `distributed-arch`

### Architecture Status
- **V1 Scope**: Single-K3 Unified Local Mode only (ADR-012). Strict native `riscv64` target.
- **Future Milestone (m3)**: Multi-node scaling over network RPC, pending hardware availability.

### Unified Local Mode (v1)
- All subsystems (manager, KV holder, engines, extensions) execute on a single K3 SoC.
- Inter-process communication via UDS (`rkyv` / Apache Arrow IPC) and zero-copy shared memory (`memfd`).

### Multi-Node Mode (Future)
- Disaggregated control plane and remote worker topology.
- Preserves X100 session residency rules per autonomous worker node.
