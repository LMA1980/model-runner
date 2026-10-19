# ADR-005: Prompt exclusivity

**Status**: Locked

## Context
Batching across prompts is the main throughput lever for bandwidth-bound decode.

## Decision
One prompt per forward pass, **no cross-prompt batching**. Determinism and isolation matter more than throughput.

## Consequences
Aggregate tok/s equals single-stream tok/s; requests queue. 'Batched' wording removed from feature docs.
