# Spec: Front-End & Source Extensions

## Location: `specs/api/extensions.md`

### Extension Model
- All extensions run out-of-process in `k3-ext@<name>.service` units (ADR-019, ADR-041).
- Only extensions possess network namespace access.
- Inter-process contract: Apache Fory serialization over Unix Domain Sockets.

### Extension Roles
1. **Front-End Extensions**:
   - Expose external client protocols (OpenAI, Claude, Gemini).
   - Ingest client requests and stream responses from `k3-manager`.
2. **Source Extensions**:
   - Ingest weights from Hugging Face, Ollama, or vendor stores.
