# US-17: Session Metadata Persistence & Last-Turn Diagnostic Replay

- **Milestone**: [M2: Multi-Model Runtime, Memory & Isolation](milestone-02.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#17](https://github.com/LMA1980/model-runner/issues/17)
- **Feature Ref**: [Session & Project Isolation](../features/session-mgmt.md)
- **Spec Ref**: [Process Model & IPC](../specs/runtime/process-model.md)
- **Related ADRs**: [ADR-001](../decisions/ADR-001-tenancy.md), [ADR-003](../decisions/ADR-003-persistence-sqlite.md)

## Narrative
**As a** System Operator,
**I want** the runtime to persist operational metadata (tenants, projects, budgets, tuning profiles, labels, and usage statistics) along with only the most recent prompt and response per session across reboots,
**So that** administrative configuration survives power cycles and I can replay the latest interaction of any session for diagnostics without accumulating unbounded conversation logs on storage.

## Business Context & Domain Rules
- Administrative state—including tenant and project definitions, resource budgets, applied model tuning profiles, accounting labels, and operational statistics—must survive service restarts and full board reboots.
- Because clients resend full conversation history on each turn, the runtime does not need to store multi-turn transcript archives to serve requests.
- For troubleshooting and quality verification, the persistent store retains a single overwritten record per session containing the last prompt and its corresponding generated result, allowing operators to inspect and replay that turn via diagnostic tools.

## Core System Assertions
- **Scenario 1: Persistence of operational configuration across reboots**
  - **Given** an operator has configured projects, model tuning profiles, budgets, and session accounting labels,
  - **When** the host board or control service restarts,
  - **Then** the runtime restores all projects, tuning profiles, budgets, and cumulative statistics without operator reconfiguration.
- **Scenario 2: Bounded single-row last-turn retention per session**
  - **Given** an active session that processes multiple sequential conversation turns over time,
  - **When** each new turn completes,
  - **Then** the persistent session record overwrites the previous turn's prompt and result with the latest prompt and result so storage per session remains strictly bounded to one turn.
- **Scenario 3: Diagnostic replay of the last session interaction**
  - **Given** a recorded session with a persisted last prompt and result,
  - **When** an operator triggers a diagnostic replay for that session,
  - **Then** the diagnostic tool loads the exact prompt and parameters from the persisted session record to reproduce and compare the model's output.
