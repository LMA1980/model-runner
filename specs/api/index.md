# Specs: API Layer

Client-facing protocols and transport adapters.

## Architecture
- `k3-manager` is fundamentally an IPC daemon at minimum, with a modular WebAPI at most.
- Web framework options (Axum, Rocket, etc.) to be spiked for dependency health, lifecycle, and HTTP/3 support.

## Components
- [OpenAI Adapter](openai.md): `/v1/chat/completions` and `/v1/models`.
- [Claude Adapter](claude.md): `/v1/messages` Anthropic protocol.
