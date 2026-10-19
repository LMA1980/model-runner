# ADR-013: Decision models

**Status**: Locked

## Context
multi-model-sched.md named tev1/nimble 'for instant routing' without saying who calls them.

## Decision
tev1/nimble can be called by clients **and** act as the internal router for `model: auto`.

## Consequences
model: auto adds a decision-model inference on the critical path of routed requests.
