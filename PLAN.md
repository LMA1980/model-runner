# K3 AI Runtime Master Plan

## 1. Architecture Ecosystem
Specification repo for SpacemiT K3 AI platform.
Code lives in `k3-manager` (control plane) and `k3-engine` (runtime).

## 2. Locked Core Decisions
- **Stack**: Pure Rust across all layers.
- **Processes**: Manager daemon (`k3-manager`) + 16-core engine (`k3-engine`).
- **IPC**: UDS control RPC + shared memory ring buffer for tokens/logits.
- **Execution**: Prompt cycle exclusivity; tail-only A100 underfill.
- **Formats**: GGUF primary for Stage 1; broad public format support.

## 3. Roadmap
1. **Stage 1 (Direct Evaluation)**: Standalone diagnostic CLI in `k3-engine` evaluating GGUF decision models directly on K3.
2. **Stage 2 (Manager Integration)**: `k3-manager` daemon with session/project isolation, connected via UDS/shm IPC.
3. **Stage 3 (Ecosystem)**: OpenAI/Claude APIs, MCP host, and vendor adapters.

## Navigation
- [Features](features/index.md)
- [Specs](specs/index.md)
