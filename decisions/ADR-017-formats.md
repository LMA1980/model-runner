# ADR-017: Formats

**Status**: Locked

## Context

model-mgmt.md promised GGUF, Safetensors, OCI and ONNX while the engine targets Qwen/LLaMA Q4_K_M first.

## Decision

Universal ingestion stays the goal. Engine support grows step by step (Qwen/LLaMA Q4_K_M first).

## Consequences

Registry search must filter by engine capability (ADR-023).
