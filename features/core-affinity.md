# Feature: Heterogeneous Core Affinity

## Codename: `core-affinity`

### Hardware Topology

1. **X100 (Cores 0-7, 2.2GHz)**:
   - OoO, VLEN = 256 bits (`zvl256b`).
   - Hosts control plane, tokenization, session routing, and X100 compute.
1. **A100 (Cores 8-15, 1.8GHz)**:
   - In-Order, VLEN = 1024 bits (`zvl1024b`) + IME (`xsmtvdotii`).
   - Dedicated compute workers; evaluated via Stage 1 spikes (ADR-028).

### Control Plane Reservation & HMP

- Control plane reserves 3 threads (2 active + 1 idle recovery) on X100 by default (ADR-007).
- Compute threads on X100 capped at 6 by default.
- Pinned compute threads registered via cgroup v2 cpusets (`0x00FF` vs `0xFF00`) (ADR-008, ADR-041).
- VLEN isolation enforced: threads never migrate across cluster boundaries.
