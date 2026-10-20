# US-07: Safe Conservative Defaults for Unprofiled Models

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#7](https://github.com/LMA1980/model-runner/issues/7)
- **Feature Ref**: [Model Tuning & Profiles](../features/tuning-profile.md)
- **Spec Ref**: [OpenAI API Adapter](../specs/api/openai.md), [Core Scheduler](../specs/runtime/scheduler.md)
- **Related ADRs**: [ADR-028](../decisions/ADR-028-a100-premise.md), [ADR-031](../decisions/ADR-031-unprofiled-models.md)

## Narrative

**As a** System Operator,
**I want** newly pulled models that lack a diagnostic cost profile to load using a conservative, safe default placement and be visibly flagged as unprofiled,
**So that** untested models can be served immediately without risking severe performance degradation or memory exhaustion while reminding me to profile and tune them.

## Business Context & Domain Rules

- Freshly acquired models do not yet have empirical hardware cost baselines or custom placement rules.
- Placing an unprofiled model onto specialized or unverified compute clusters or granting it a large context allocation risks degraded token rates or memory contention.
- The system assigns every unprofiled model a conservative default profile: general-purpose compute cluster placement only, standard throughput priority class, a conservative context window bound, and dynamic core lending/borrowing disabled.
- Unprofiled status is surfaced in model registry listings and operational logs until an operator explicitly applies a tuning profile.

## Core System Assertions

- **Scenario 1: Conservative placement on initial model load**
  - **Given** a newly ingested model that has no associated diagnostic cost profile or operator tuning profile,
  - **When** the model is loaded into the runtime,
  - **Then** the system places it on the conservative general-purpose compute pool with a bounded default context window, throughput priority class, and dynamic core lending/borrowing turned off.
- **Scenario 2: Explicit unprofiled status surfacing**
  - **Given** an active model running under the conservative default profile,
  - **When** an operator or client queries the list of available models or inspects operational logs,
  - **Then** the model entry is explicitly tagged as unprofiled along with an advisory notice to run diagnostic profiling and apply a tuning profile.
