# ADR-028: A100 premise

**Status**: Hypothesis (Stage 1)

## Context

Stock llama.cpp/Ollama without the SpacemiT patch ran ~40-60x slower on A100 than X100.

## Decision

Measured with stock llama.cpp/Ollama (no SpacemiT patch): A100 0.5–0.9 tok/s vs X100 30–32 tok/s. Working hypothesis: A100 is suited to **isolated model threads only** with proper kernels. The docs stop stating "A100 = heavy compute" as a fact.

## Consequences

Unprofiled models default to X100 (ADR-031); Stage 1 measures A100 directly (ADR-034).
