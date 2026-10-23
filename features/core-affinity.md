# Feature: Heterogeneous Core Affinity

## Codename: `core-affinity`

### Hardware Topology

1. **X100 (Cores 0–7, mask `0x00FF`, up to 2.15 GHz)**:
   - Out-of-Order (`spacemit,x100`), `VLEN = 256` bits (`vlenb = 32`, `zvl256b`).
   - 64 KiB L1I + 64 KiB L1D per core; 2x 4 MiB shared L2 (8 MiB total).
   - Hosts control plane, tokenization, session routing, and `x100` RVV compute; does not implement `XSMTVDotII` Matrix 2.0 (`--ime on` on `x100`-only placement is rejected with `CapabilityMismatch`).
1. **A100 (Cores 8–15, mask `0xFF00`, up to 1.80 GHz)**:
   - In-Order (`spacemit,a100`, `cpu-ai`), `VLEN = 1024` bits (`vlenb = 128`, `zvl1024b`) + SpacemiT IME (`XSMTVDotII`, `smt.vmadot` `8x16` `i8` -> `8x8` `i32` tiles).
   - 32 KiB L1I + 32 KiB L1D per core; 2x 1 MiB shared L2 (2 MiB total).
   - Dedicated compute workers (registered via `/proc/set_ai_thread` when running on the SpacemiT-patched `spacemit-hmp` kernel; not required on vanilla Linux); evaluated via Stage 1 spikes (ADR-028, ADR-034).

### Control Plane Reservation & HMP

- Control plane reserves 2 active + 1 spare recovery core on `X100` by default, capping default `X100` compute threads at 6 (`0x003F`) while `A100` defaults to up to 8 compute threads (`0xFF00`) (ADR-007).
- Compute worker threads are pinned 1-to-1 to physical cores via `sched_setaffinity` (after conditionally registering with `/proc/set_ai_thread` for `A100` cores 8–15 when present on the SpacemiT-patched kernel) and verified before and after execution via `sched_getaffinity`, `/proc/self/task/<tid>/status` (`Cpus_allowed_list`), and `sched_getcpu()` (ADR-008, ADR-041).
- VLEN and cluster isolation enforced: worker threads never migrate across the `X100`/`A100` (`0x00FF` / `0xFF00`) boundary, and a mixed-cluster mask is permitted only with an explicit cross-cluster split policy (`--cluster both --split <phase|op|row>`, ADR-009).
