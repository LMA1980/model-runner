# User Stories & Core System Assertions Index

Business-logic user stories and core system assertion requirements for the K3 AI Runtime Manager.
Exempt from the 1,000-character document limit (see [ADR-022](../decisions/ADR-022-docs.md)).

## Scope & Design Principles

- **Business Logic & Core Assertions Only**: Each user story defines *what* business capability and system invariant is required (`Narrative`, `Business Context & Domain Rules`, and `Core System Assertions`), remaining agnostic to programming languages, OS primitives, or specific third-party libraries.
- **Hardware Portability & Reference Board**: The **SpacemiT K3 Pico-ITX (16 heterogeneous cores, 32 GB unified RAM, 128 GB UFS, 2 TB M.2 SSD)** serves as our reference development platform. All business rules and assertions scale across lower-resource or alternative board configurations without hardcoding fixed memory or storage capacities.
- **GitHub Issue Synchronization**: Each GitHub Issue contains only the pure business logic and core assertions plus a link back to its full filesystem specification reference in this directory.

## Milestones Overview

- **[M1: Core Evaluation & Hardware Profiling](milestone-01.us-index.md)** (`US-01` – `US-06`): Standalone model evaluation, multi-core synchronization benchmarking, heterogeneous cluster splitting, hardware ceiling cost profiling, and isolated worker/control execution domains.
- **[M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)** (`US-07` – `US-17`): Safe defaults for unprofiled models, operator tuning authority, multi-model overlapping reservations, priority preemption, dynamic core spillover, decision routing, patient queuing, per-model memory arenas, project-scoped prefix caching, crash-resilient resumption, and session replay.
- **[M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)** (`US-18` – `US-24`): Content-addressed model store, isolated external source ingestion, architecture recipe capability filtering, derived weight caching, safe garbage collection, and network-isolated OpenAI & Anthropic Claude front-ends.
