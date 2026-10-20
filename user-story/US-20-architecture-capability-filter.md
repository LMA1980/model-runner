# US-20: Architecture Recipe Capability Filtering

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#20](https://github.com/LMA1980/model-runner/issues/20)
- **Feature Ref**: [Model Management & Storage](../features/model-mgmt.md)
- **Spec Ref**: [Model Registry & Formats](../specs/models/registry.md), [Inference Worker](../specs/runtime/worker.md)
- **Related ADRs**: [ADR-017](../decisions/ADR-017-formats.md), [ADR-023](../decisions/ADR-023-architecture-onboarding.md), [ADR-024](../decisions/ADR-024-architecture-kernel-extensions.md), [ADR-025](../decisions/ADR-025-tokenizer-ownership.md)

## Narrative

**As a** System Operator,
**I want** the runtime to validate model formats and exact architecture revisions against its supported execution recipes during registry search and model loading,
**So that** incompatible models or minor model revisions that introduce unsupported algorithms are caught immediately with clear diagnostics rather than failing unpredictably during inference.

## Business Context & Domain Rules

- Modern open-source model families frequently introduce algorithmic changes—not just new weights—across minor version releases (for example, between major and minor revisions of Qwen or Gemma families).
- Each supported model architecture and minor algorithmic revision is paired with an explicit execution recipe and matching tokenizer/template definition so control-plane tokenization and worker execution can never drift apart.
- While the store supports universal ingestion of standard weight formats, the runtime capability filter inspects each model's declared architecture metadata and refuses to load or schedule any model whose architecture revision lacks a verified execution recipe.

## Core System Assertions

- **Scenario 1: Capability filtering during model search and inspection**
  - **Given** an operator searches external sources or inspects local registry manifests,
  - **When** candidate models are listed,
  - **Then** the system indicates whether each model's format and exact architecture revision match a supported execution recipe on the current runtime build.
- **Scenario 2: Upfront rejection of unsupported architecture revisions**
  - **Given** a model file whose metadata declares an architecture or minor algorithmic revision not supported by the installed runtime recipes,
  - **When** an operator or client attempts to load the model for execution,
  - **Then** the system rejects the load upfront with an explicit unsupported-architecture diagnostic naming the missing recipe.
- **Scenario 3: Guaranteed alignment between tokenization and execution recipe**
  - **Given** a model loaded using a verified architecture recipe,
  - **When** the control plane tokenizes prompts and formats chat templates for that model,
  - **Then** the control plane uses the exact tokenizer and template rules bound to that architecture recipe version.
