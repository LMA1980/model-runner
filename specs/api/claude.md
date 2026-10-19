# Spec: Claude API Adapter

## Location: `specs/api/claude.md`

### Endpoints
- `POST /v1/messages`: Claude messages protocol.

### Protocol Details
- **Streaming**: Anthropic SSE event types:
  - `message_start`
  - `content_block_start`
  - `content_block_delta` (text_delta, thinking_delta)
  - `content_block_stop`
  - `message_delta`
  - `message_stop`
- **Errors**: Emits 529 `overloaded_error` on queue cap; invalid request on context overflow (ADR-015, ADR-027).
- **Mapping**: Translates Claude content blocks to canonical `UnifiedPrompt`.
