# ADR-026: Resumable computation

**Status**: Locked / Future

## Context

Slow models make re-running prefill and generated tokens expensive after interruptions.

## Decision

Survives **engine crash/restart and client disconnect** in v1, RAM only. KV lives in the **`k3-kv` holder** (ADR-042), so it survives engine *and* manager crashes. The manager records progress (prompt text hash + tokens so far) and resumes decode. A client reconnecting with the same prompt picks up the in-flight or finished result. Surviving a reboot comes with the NVMe tier.

## Consequences

Resume restarts from the last committed token with saved sampler RNG state.
