# US-18: Content-Addressed Model Store & Human-Browsable Registry

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#18](https://github.com/LMA1980/model-runner/issues/18)
- **Feature Ref**: [Model Management & Storage](../features/model-mgmt.md)
- **Spec Ref**: [Model Registry & Formats](../specs/models/registry.md)
- **Related ADRs**: [ADR-035](../decisions/ADR-035-store-layout.md), [ADR-036](../decisions/ADR-036-store-location.md)

## Narrative

**As a** System Administrator / Operator,
**I want** model weights to reside in a configurable, content-addressed store deduplicated by cryptographic digest alongside structured manifests and a human-browsable hierarchy,
**So that** identical weights acquired from multiple sources are stored only once, bulk model assets can be placed on dedicated high-capacity storage rather than primary boot media, and operators can inspect models intuitively.

## Business Context & Domain Rules

- Edge boards often pair smaller primary boot storage with optional high-capacity secondary storage (for example, the SpacemiT K3 Pico-ITX reference platform pairs onboard flash with an M.2 SSD, while other boards may use different storage tiers).
- The model store root location is configurable so operators can direct bulk model assets to their preferred storage tier.
- Every weight artifact is stored by its cryptographic content digest, guaranteeing automatic deduplication when the same model weights are referenced across different tags or external sources.
- Each registered model version stores a manifest capturing its format, architecture recipe, quantization, trained context limit, license, and origin, plus a human-browsable alias hierarchy pointing to the underlying content-addressed blobs.
- A model build's canonical identity combines the weight digest and the active architecture recipe version.

## Core System Assertions

- **Scenario 1: Cross-source weight deduplication**
  - **Given** a model weight file already stored in the registry from Source A,
  - **When** an operator registers or pulls an identical weight file (matching cryptographic digest) from Source B or under a new tag,
  - **Then** the store records the new manifest and human-browsable entry referencing the existing weight blob without duplicating the weight bytes on storage.
- **Scenario 2: Configurable store root location**
  - **Given** an operator configures the model store root to point to a designated secondary storage volume,
  - **When** models are pulled, converted, or loaded,
  - **Then** all weight blobs, temporary staging files, and manifests reside exclusively under the configured storage volume rather than consuming primary system boot storage.
- **Scenario 3: Human-browsable model inspection**
  - **Given** one or more models registered in the content-addressed store,
  - **When** an operator browses the model directory hierarchy by source, model name, and tag,
  - **Then** each entry resolves cleanly to its manifest metadata and underlying content-addressed weight blob.
