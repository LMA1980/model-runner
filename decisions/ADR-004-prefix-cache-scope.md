# ADR-004: Prefix-cache scope

**Status**: Locked

## Context
kv-cache.md said reuse across sessions; session-mgmt.md said session scope. Cross-project hits would leak via timing.

## Decision
Never shared across projects. Shared across sessions within a project (copy-on-write). Radix key `(project_id, model_id, model_build, tokens)`.

## Consequences
Some system prompts are duplicated across projects; multi-tenant readiness comes for free.
