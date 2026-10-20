# Spec: OpenAI API Adapter

## Location: `specs/api/openai.md`

### Endpoints

- `GET /v1/models`: Returns loaded models, tags unprofiled models (ADR-031).
- `POST /v1/chat/completions`: Full chat completion pipeline.

### Protocol Details

- **Streaming**: Server-Sent Events (`text/event-stream`), `data: {...}`, `data: [DONE]`.
- **Keep-Alive**: Emits periodic SSE comments and queue position while queued (ADR-015).
- **Errors**: Emits 429 on queue cap with `Retry-After`; `context_length_exceeded` on oversize (ADR-027).
- **Tools**: Pass-through tool calling schemas (ADR-020).
