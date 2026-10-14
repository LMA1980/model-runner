# Feature: Dual API & MCP Compatibility

## Codename: `api-compat`

### Business Logic
Provide transparent interoperability with existing LLM clients and tool ecosystems.

### Core Philosophy
- `k3-manager` operates fundamentally as an IPC daemon; the WebAPI is a modular layer.
- Web frameworks (Axum, Rocket, etc.) to be spiked for dependency security, lifecycle, and HTTP/3 support.

### Protocol Support
1. **OpenAI Compatibility**:
   - `/v1/models`, `/v1/chat/completions` (streaming SSE & non-streaming), tool calling.
2. **Anthropic Claude Compatibility**:
   - `/v1/messages` (streaming SSE & non-streaming), thinking blocks.
3. **MCP (Model Context Protocol)**:
   - Pluggable MCP host bridge for models invoking external tools.

### Unification Layer
- Translates inputs into internal canonical representation (`UnifiedPrompt`).
