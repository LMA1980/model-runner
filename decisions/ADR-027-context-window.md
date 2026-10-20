# ADR-027: Context window

**Status**: Locked

## Context

Weights, KV and the control plane share 32GB; vendors expose a fixed context window.

## Decision

**Fixed `n_ctx` per model placement** in its tuning-profile, capped by the trained maximum. KV for `n_ctx` × active slots is reserved when the model loads; if it doesn't fit, the load is refused. A request over `n_ctx` gets `context_length_exceeded`, never silent truncation.

## Consequences

Loads that do not fit are refused; oversize requests get context_length_exceeded.
