# Feature: Dual API & Front-End Extensions

## Codename: `api-compat`

### Protocol Front-Ends
- Out-of-process front-end extensions communicating with `k3-manager` via Apache Arrow IPC over UDS (ADR-019).
- **OpenAI Compatibility**: `/v1/models`, `/v1/chat/completions` (streaming SSE & non-streaming).
- **Anthropic Claude Compatibility**: `/v1/messages` (SSE events, thinking blocks).

### Web Transport
- Baseline transport: HTTP/1.1; HTTP/2 supported where framework provides it (ADR-021).
- HTTP/3 retained for future experimentation.
- Network sandboxing: front-ends are the only components with network namespace access (ADR-041).

### Tools & MCP Status
- Standard OpenAI/Claude tool calls pass through directly to client; no server-side execution in v1.
- MCP host integration is deferred to future milestones (ADR-020).
