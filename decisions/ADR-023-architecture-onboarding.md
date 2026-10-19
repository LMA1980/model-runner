# ADR-023: Architecture onboarding

**Status**: Locked

## Context
Minor model versions (Qwen3 -> Qwen3.8) may change algorithms, not just weights.

## Decision
Shared op/kernel library plus a small Rust **recipe** per architecture (qwen3, **qwen3.8**, gemma4, llama), chosen from GGUF `general.architecture`. Treat minor versions as possibly new algorithms. The capability filter rejects architectures with no recipe.

## Consequences
Supporting a new architecture means a new recipe, and kernels only for new ops.
