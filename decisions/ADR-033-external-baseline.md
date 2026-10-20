# ADR-033: External baseline

**Status**: Locked

## Context

RVA23 is young; llama.cpp is fast only where the architecture is well understood.

## Decision

**No llama.cpp/Ollama baseline stage.** RVA23 is young, and llama.cpp is only highly tuned for well-understood architectures, so its numbers on K3 are not a meaningful yardstick. The k3-diag spikes (Stage 1) test ADR-028 directly.

## Consequences

No Stage 0; Stage 1 compares the engine against itself.
