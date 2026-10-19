# ADR-010: Determinism / cost

**Status**: Locked

## Context
Determinism was ranked above throughput but undefined; the daemon needs per-model cost weights.

## Decision
diag-tool runs one model in isolation and produces a static cost baseline (the "weight"). The daemon re-measures online, but **only to refine its internal cost estimate for fair time-slicing and to produce recommendations** (`k3 tune suggest <model>`). It never changes operator settings on its own.

## Consequences
Online measurements never override the operator profile (ADR-032).
