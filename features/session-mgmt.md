# Feature: Session & Project Isolation

## Codename: `session-mgmt`

### Tenancy Hierarchy & Isolation
- Hierarchy: Tenant -> Project -> Session (ADR-001). V1 runs single tenant/project.
- Sessions never cross project boundaries. Prefix KV blocks shared only within same project (ADR-004).

### Session Identity & State
- Sessions are implicit: clients send full history; manager matches cached token prefixes (ADR-002).
- Optional `X-K3-Session` and `X-K3-Project` headers serve as hints and accounting labels.

### Persistence & Resumption
- Operational state backed by SQLite: metadata + last prompt & result per session for diagnostic replay (ADR-003).
- Resumable computation survives engine restarts and client disconnects in RAM (ADR-026).
- Reboot persistence of KV caches deferred to future warm-restart milestone.
