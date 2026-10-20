# ADR-025: Tokenizer ownership

**Status**: Locked

## Context

The prefix radix index is keyed on token IDs and lives on the control plane.

## Decision

The **manager** tokenizes, applies the chat template, keeps the token-ID radix index, and detects stop sequences. The **engine** receives token IDs + a block table and writes KV in place. Each recipe crate ships a tokenizer/template lib crate that the manager links, so they can't drift.

## Consequences

Tokenizer/template crates ship with recipes so manager and engine cannot drift.
