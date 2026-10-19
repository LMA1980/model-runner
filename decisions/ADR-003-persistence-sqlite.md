# ADR-003: Persistence (SQLite)

**Status**: Locked / Future

## Context
SQLite was said to persist 'state' across reboots without defining what state.

## Decision
Metadata (projects, budgets, profiles, labels, stats) + **last prompt and result per session** for diagnostics and replay. Warm restart after reboot comes later.

## Consequences
One overwritten row per session for replay via diag-tool; warm restart (re-prefill) is future work.
