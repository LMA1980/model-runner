# US-19: Isolated External Model Source Ingestion & Atomic Verification

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#19](https://github.com/LMA1980/model-runner/issues/19)
- **Feature Ref**: [Model Management & Storage](../features/model-mgmt.md)
- **Spec Ref**: [Model Source Adapter Interface](../specs/models/source-adapter.md), [Front-End & Source Extensions](../specs/api/extensions.md)
- **Related ADRs**: [ADR-019](../decisions/ADR-019-extensions.md), [ADR-040](../decisions/ADR-040-gc-safety.md), [ADR-041](../decisions/ADR-041-isolation-domains.md)

## Narrative
**As a** System Operator,
**I want** to authenticate, search, list, and pull models from external repositories (such as Hugging Face, Ollama, or private registries) through isolated source extensions that validate digests before atomic store promotion,
**So that** third-party repository credentials and network access remain isolated from the core runtime and interrupted downloads never corrupt the model store.

## Business Context & Domain Rules
- External model hubs evolve their APIs, authentication schemes, and SDKs independently of the core runtime.
- Source adapters operate as isolated extensions that hold external network access and repository credentials outside the core control and compute domains.
- Every source extension supports a standard lifecycle contract: authentication (`auth`), repository search (`search`), version listing (`list`), and weight acquisition (`pull`).
- Incoming downloads are written to a staging area first and promoted atomically into the content-addressed store only after their cryptographic digest and integrity are verified.

## Core System Assertions
- **Scenario 1: External repository search and pull via source extension**
  - **Given** a configured source extension for an external model repository,
  - **When** an operator searches for a model and initiates a pull,
  - **Then** the isolated source extension authenticates with the remote repository, downloads the weights into the staging area, verifies the cryptographic digest, and atomically promotes the verified blob and manifest into the model store.
- **Scenario 2: Protection against partial or corrupted downloads**
  - **Given** a model pull is in progress in the staging area,
  - **When** the network connection drops or the downloaded bytes fail cryptographic digest verification,
  - **Then** the incomplete or corrupted artifact is never promoted into the active model store, and existing models remain completely unaffected.
- **Scenario 3: Credential and network isolation from core runtime**
  - **Given** repository credentials configured for an external source extension,
  - **When** model compute workers and the core scheduler execute,
  - **Then** neither the compute workers nor the core scheduler possess external network access or direct access to external repository credentials.
