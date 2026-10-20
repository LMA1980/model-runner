# ADR-019: Extensions

**Status**: Locked

## Context
'Vendor adapter' mixed model repositories and AI vendor protocols; both are specs owned by third parties.

## Decision
One extension pattern; the external party owns the spec. Roles: **front-end** (OpenAI/Claude/Gemini) and **source** (HF/Ollama/private). **All out-of-process**, including first-party, using Apache Arrow (Arrow IPC streams and C Data Interface) over IPC. Core = IPC only (m1).

## Consequences
Every streamed token crosses one extra IPC hop; the core exposes IPC only (m1).
