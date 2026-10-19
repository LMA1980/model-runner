# ADR-024: Architecture/kernel extensions

**Status**: Locked

## Context
The forward pass is the hot path and needs zero-copy, inlinable code.

## Decision
**In-process only**, unlike ADR-019. Separate crates compiled into k3-engine with Cargo features (`arch-*`, `kernels-*`). Vendor-tuned kernels = another crate plus an engine rebuild. No runtime plugin ABI.

## Consequences
Adding an architecture or kernel requires rebuilding k3-engine.
