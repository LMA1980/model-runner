# Feature: Model Tuning & Profiles

## Codename: `tuning-profile`

### Business Logic
Balance latency, compute density, and core allocation across models on K3.

### Prompt Isolation & Tail Underfill
- **Exclusive Cycle Ownership**: No two prompts share the same execution cycle or vector register space.
- **Tail Underfill Only**: Underfilled 1024-bit vectors are permitted strictly at the tail of a prompt's batch. Never merge unrelated prompts to fill lanes.

### Tuning Dimensions
1. **Compute Target**: Route small models (0.5B-1.5B) to X100 or A100 based on core availability.
2. **Context Bounds**: Configure `n_ctx` against 32GB RAM to prevent page thrashing.
3. **Kernel Selection**: Deploy RVV 1.0 / IME kernels with dynamic AVL tail sizing.
