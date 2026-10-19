# K3 Uber AI Runtime Manager Intent

## Vision & Tenancy
- Multi-model AI runtime on SpacemiT K3 (X100 + A100).
- Hierarchy: Tenant -> Project -> Sessions. V1 runs single tenant/project with multi-tenant-ready schemas (ADR-001).

## Model Execution & Architectures
- Execute modern open source models: Gemma4, Qwen3.8, etc.
- Recipes per architecture; minor versions may change algorithms (ADR-023).

## Model Management & Source Adapters
- Ingest models via external source adapters (ADR-019).
- Content-addressed storage on NVMe under `/var/lib/k3` (ADR-035, ADR-036).

## Compute & Affinity
- Session management, routing, and tokenization on X100 (ADR-007, ADR-025).
- Compute partitioned via cgroups; A100 tested in Stage 1 spikes (ADR-008, ADR-028, ADR-034).
- Paged KV cache kept in RAM-only KV holder (ADR-016, ADR-042).
