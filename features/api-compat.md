# Feature: Dual API & MCP Compatibility

## Codename: `api-compat`

### Business Logic
Provide transparent interoperability with existing LLM clients and tool ecosystems.

### Protocol Support
1. **OpenAI Compatibility**:
   - `/v1/models`
   - `/v1/chat/completions` (streaming SSE & non-streaming)
   - Tool calling / structured JSON schema.
2. **Anthropic Claude Compatibility**:
   - `/v1/messages` (streaming SSE & non-streaming)
   - System prompts and thinking blocks.
3. **MCP (Model Context Protocol)**:
   - Pluggable MCP host bridge for specialized models requiring external tools or knowledge sources.

### Unification Layer
- Translates inputs into an internal canonical representation (`UnifiedPrompt`).
