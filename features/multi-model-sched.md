# Feature: Multi-Model Scheduling

## Codename: `multi-model-sched`

### Business Logic
Orchestrates execution when multiple models (e.g., small decision models and large generative models) coexist on limited K3 RAM.

### Scheduling Strategy
1. **Tiered Priority Queue**:
   - Fast-path queue for compact decision models (`tev1`, `nimble`) requiring low latency.
   - Batched queue for throughput-oriented generative models on A100.
2. **Resource Coexistence**:
   - Small decision models (<2GB) remain pinned in X100/RAM for instant routing.
   - Large models utilize A100 vector units without starving fast decision tasks.
3. **Preemption & Interleaving**:
   - Allow quick decision checks to interleave between generation steps without unloading active weights.
