# ADR-012: Topology

**Status**: Locked

## Context
distributed-node.md placed sessions on an x86_64 host, contradicting INTENT and riscv64-only.

## Decision
Single-K3 local mode only. Multi-node becomes a "Future" note (own RPC = m3, depends on hardware).

## Consequences
distributed-node.md becomes a Future note; own RPC is milestone m3, hardware permitting.
