# K3 Uber AI Runtime Manager

High-performance AI runtime engine tailored for the SpacemiT K3 RISC-V SoC (16 cores, 32GB RAM).

## Key Highlights
- **Heterogeneous Architecture**:
  - X100 (OoO, 2.2GHz, 256-bit VLEN): Sessions, API, KV routing.
  - A100 (InO, 1.8GHz, 1024-bit VLEN): IME & vector tensor kernels.
- **Unified Memory Data Plane**: Zero-copy token and weight sharing across clusters.
- **Prompt Isolation**: Exclusive execution cycles; tail-only vector underfill on A100.
- **Multi-Model Scheduling**: Tiered queues for fast decision models vs heavy generative jobs.
- **Dual Protocol & MCP**: OpenAI and Claude compatible endpoints.
- **Broad Format Ingestion**: GGUF, Safetensors, OCI/Ollama, and ONNX.
- **Operator Diagnostic Tool**: Non-interactive CLI for evaluation and benchmarking.

## Navigation
- [Master Plan](PLAN.md)
- [Features Index](features/index.md)
- [Specifications Index](specs/index.md)
