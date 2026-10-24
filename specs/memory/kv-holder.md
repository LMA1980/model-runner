# Spec: KV Holder Service

## Location: `specs/memory/kv-holder.md`

### Responsibilities

- `k3-kv.service`: Minimal policy-free process holding KV memfd arenas (ADR-042).
- Allocates per-model isolated arenas via Apache Fory control over UDS and passes fds via `SCM_RIGHTS` (ADR-018, ADR-041, ADR-043).
- Pre-faults and locks memory via `mlock` (`LimitMEMLOCK=infinity`).

### Shared Metadata & Crash Survival

- Shared `zerocopy` (`#[repr(C)]`) metadata table & Apache Arrow tensor views:
  - Engines write KV tensor values and output activations in place.
  - Manager writes block tags (`purge`, `persist`, `volatile`), token counts, and RNG state.
- Survives manager crashes; enables seamless resumption (ADR-026).
