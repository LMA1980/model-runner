# ADR-009: Cross-cluster split

**Status**: Open (Stage 1)

## Context

X100 (OoO, 256-bit) and A100 (in-order, 1024-bit + IME) differ; naive splits stall at barriers.

## Decision

`phase` / `op` / `row` all remain candidates; the Stage 1 spikes decide. diag-tool gains `--split`.

## Consequences

diag-tool gains --split \<phase|op|row>; decision deferred to Stage 1 data.
