# ADR-003: Persistence (DuckDB / SQLite)

**Status**: Accepted (Migrated to DuckDB in M3)

## Context

Persistence stores operational metadata (tenants, projects, budgets, tuning profiles, accounting labels, cumulative stats) and last prompt and result per session across reboots without defining an unbounded database schema. In Milestone M3, persistence was migrated from SQLite to DuckDB to support columnar analytical metrics, embedded durability, and decoupled cross-compilation toolchains.

## Decision

Use DuckDB embedded persistence (`DuckDbPersistenceStore`, aliased as `SqlitePersistenceStore` for compatibility) for metadata (projects, budgets, profiles, labels, stats) + **last prompt and result per session** for diagnostics and replay. Overwrite session turns in-place with single-row $O(1)$ retention. Warm restart after reboot comes later.

## Consequences

One overwritten row per session for replay via diag-tool; native write-ahead logging (WAL) on disk provides durability without complex pragmas. Host builds link bundled DuckDB engine; cross-compilation targets decouple C++ build scripts cleanly.
