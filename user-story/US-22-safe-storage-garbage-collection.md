# US-22: Operator-Driven Storage Lifecycle & Safe Garbage Collection

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#22](https://github.com/LMA1980/model-runner/issues/22)
- **Feature Ref**: [Model Management & Storage](../features/model-mgmt.md)
- **Spec Ref**: [Store Garbage Collection](../specs/models/store-gc.md)
- **Related ADRs**: [ADR-039](../decisions/ADR-039-disk-lifecycle.md), [ADR-040](../decisions/ADR-040-gc-safety.md)

## Narrative
**As a** System Administrator / Operator,
**I want** model removal to unlink only manifest references while a dedicated garbage collection workflow safely reclaims unreferenced or stale weight blobs only after verifying no active or offline worker is using them,
**So that** storage reclamation never deletes weights mapped by a running model or triggers unexpected deletions during production traffic.

## Business Context & Domain Rules
- Model weight blobs, derived layouts, and purged originals accumulate on storage over time, and operators require predictable, site-specific storage lifecycle policies.
- Removing a model removes its manifest and human-browsable alias; underlying weight blobs are reference-counted and deleted only by explicit or scheduled garbage collection (GC).
- Exceeding a configured storage high-water mark emits an operational warning only; the system never automatically deletes model blobs on storage thresholds without operator-configured GC execution.
- Before deleting any unreferenced or stale blob, garbage collection enforces two mandatory safety checks that work even if the control service is offline:
  1. Verifying that no running worker holds an active shared lock on the blob.
  2. Scanning active worker memory mappings to confirm no compute process currently maps the blob, and exposing an administrative query to inspect which processes use any given blob.

## Core System Assertions
- **Scenario 1: Reference-counted manifest removal without immediate blob destruction**
  - **Given** a weight blob referenced by two different model tags,
  - **When** the operator removes one of the model tags and runs garbage collection,
  - **Then** only the removed tag's manifest and alias are deleted, while the shared weight blob remains intact for the remaining tag.
- **Scenario 2: High-water mark warning without unapproved auto-deletion**
  - **Given** model store usage crosses the operator-configured storage high-water mark threshold,
  - **When** new models or derived blobs are stored,
  - **Then** the system emits a high-water mark warning to the operator and never automatically deletes existing manifests or referenced blobs.
- **Scenario 3: Dual-gate safety check preventing deletion of mapped blobs (online or offline)**
  - **Given** a weight blob whose manifest was removed while an active compute worker still has the blob locked or mapped in memory (even if the control service is offline),
  - **When** garbage collection runs,
  - **Then** garbage collection detects that the blob is actively in use, skips deleting it, and reports the active holder when queried by the operator.
