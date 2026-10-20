# Specs: API Layer

Client-facing protocols and transport adapters.

## Architecture

- `k3-manager` core is an IPC daemon over UDS (ADR-018, ADR-019).
- WebAPI front-ends run out-of-process as extension daemons using Apache Arrow IPC.
- Base transport: HTTP/1.1; HTTP/3 optional spike (ADR-021).

## Components

- [OpenAI Adapter](openai.md): `/v1/chat/completions` and `/v1/models`.
- [Claude Adapter](claude.md): `/v1/messages` Anthropic protocol.
- [Extension Protocol](extensions.md): Out-of-process IPC contract.
