# ADR-011: Request vs pass ownership

**Status**: Open (Stage 1)

## Context

Per-request ownership lets one long generation block short ones; per-pass interleaving holds more KV.

## Decision

Whole-request vs per-pass interleaving: wait for Stage 1 board capacity numbers. Fallback: dedicated partitions per model.

## Consequences

Fallback is dedicated partitions per model if the board proves too slow to share.
