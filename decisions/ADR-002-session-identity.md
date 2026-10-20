# ADR-002: Session identity

**Status**: Locked

## Context

OpenAI and Claude APIs are stateless: clients resend the whole history and carry no session id.

## Decision

Implicit: clients resend full history; the manager matches cached prefixes. Optional `X-K3-Session` / `X-K3-Project` headers are hints and accounting labels only.

## Consequences

No server-side transcript is required to serve a turn; continuity comes from prefix matching (ADR-004).
