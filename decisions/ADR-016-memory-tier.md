# ADR-016: Memory tier

**Status**: Locked / Future

## Context
kv-cache.md mentioned per-cluster DDR (RAM is unified) and NVMe swap.

## Decision
RAM only in v1. NVMe tier comes later, together with warm restart.

## Consequences
NVMe tier is designed together with warm restart.
