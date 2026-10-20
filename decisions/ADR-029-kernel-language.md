# ADR-029: Kernel language

**Status**: Locked

## Context

Rust has no stable RVV or SpacemiT IME intrinsics yet.

## Decision

Inline `asm!` (RVV 1.0 + IME via `.insn`) now. **Track nightly Rust scalable-vector intrinsics** and switch when available. The SpacemiT llama.cpp patch (not yet public) is a reference only.

## Consequences

Kernel crates contain inline asm until scalable-vector intrinsics mature.
