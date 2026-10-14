# Spec: OpenAI API Adapter

## Location: `specs/api/openai.md`

### Endpoints
- `GET /v1/models`: Returns loaded and available models.
- `POST /v1/chat/completions`: Full chat completion pipeline.

### Protocol Details
- **Streaming**: Server-Sent Events (`text/event-stream`), `data: {...}\n\ndata: [DONE]\n\n`.
- **Payload Parser**: Extract `messages`, `temperature`, `max_tokens`, `stream`, `tools`.
- **Response Format**: OpenAI standard JSON schema with `id`, `created`, `choices`.
