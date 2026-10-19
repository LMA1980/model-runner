# US-21: Derived Weight Layout Caching & Stale Recipe Detection

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#21](https://github.com/LMA1980/model-runner/issues/21)
- **Feature Ref**: [Model Management & Storage](../features/model-mgmt.md)
- **Spec Ref**: [Model Registry & Formats](../specs/models/registry.md)
- **Related ADRs**: [ADR-037](../decisions/ADR-037-weight-residency.md), [ADR-038](../decisions/ADR-038-derived-weights.md)

## Narrative
**As a** System Operator,
**I want** hardware-repacked or format-converted model weights to be cached on storage as derived artifacts keyed by source digest, recipe version, and target layout—with configurable retention of original weights and automatic detection of stale derivations after runtime upgrades,
**So that** models do not pay conversion overhead on every load, storage consumption matches my retention policy, and breaking recipe updates never silently use outdated weight layouts.

## Business Context & Domain Rules
- Certain weight formats or specialized hardware matrix accelerators require weights to be converted or repacked into hardware-specific tile layouts before execution.
- Converted or repacked weights are stored as **derived blobs** keyed by `(source weight digest, architecture recipe version, target kernel layout)`.
- The operator controls original-weight retention policy after a derived layout is created: keep the original source blob indefinitely, purge it immediately, or purge it after a configured delay.
- Every simultaneously loaded weight layout counts toward the load-time system memory admission check.
- When a runtime update introduces a breaking change to an architecture recipe or kernel layout, existing derived blobs built for the older version are flagged as stale, and if the original source blob was previously purged, the operator is prompted to re-acquire the source model.

## Core System Assertions
- **Scenario 1: Reuse of cached derived weight layouts across loads**
  - **Given** a model whose weights have been converted or repacked into a hardware-optimized derived blob for the current recipe and layout version,
  - **When** the model is unloaded and subsequently reloaded on the same runtime version,
  - **Then** the runtime loads the cached derived blob directly without repeating the conversion process.
- **Scenario 2: Operator-controlled retention of original source weights**
  - **Given** a derived weight blob has been generated and verified from an original source weight blob,
  - **When** the operator's retention policy specifies keeping the original, purging immediately, or purging after a delay,
  - **Then** the lifecycle manager retains or marks the original source blob for reclamation strictly according to that configured policy.
- **Scenario 3: Stale derived blob detection after a breaking runtime upgrade**
  - **Given** a cached derived weight blob built under an older recipe or layout version,
  - **When** the runtime is upgraded with a breaking recipe or layout change,
  - **Then** the system flags the derived blob as stale, automatically rebuilds it if the original source blob is present, or notifies the operator to re-download the source model if the original was purged.
