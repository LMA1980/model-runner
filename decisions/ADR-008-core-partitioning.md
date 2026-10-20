# ADR-008: Core partitioning

**Status**: Locked / Future

## Context

A hypervisor was proposed for core access; it would add two-stage translation and break single-address-space zero-copy.

## Decision

cgroup v2 cpusets / `isolcpus` in v1. **Hypervisor** comes later, for multi-tenant isolation.

## Consequences

cpusets/isolcpus now; a hypervisor is reconsidered for multi-tenant isolation.
