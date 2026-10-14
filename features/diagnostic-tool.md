# Feature: Operator Diagnostic Tool

## Codename: `diag-tool`

### Business Logic
Non-interactive operator CLI tool for rapid benchmarking and model verification.

### Multi-Stage Delivery
1. **Stage 1 (Direct Model Evaluation)**:
   - 3 standalone spike binaries in `k3-engine`: `k3-diag-spin`, `k3-diag-futex`, `k3-diag-rayon`.
   - Direct GGUF loading via zero-copy `mmap`; embedded pure Rust BPE tokenizer.
   - Unified CLI: `--cluster <both|x100|a100>`, `--threads <n>`, `--cores <mask>`, `--repeat <n>`.
   - Inputs: `--prompt "..."` or `--file <path>` (OpenAI messages array).
   - Outputs: Live token streaming + summary table (TTFT, tok/s, repeat statistics) or `--json`.
2. **Stage 2 (Manager Querying)**:
   - Interacts with `k3-manager` daemon via Apache Fury IPC over UDS.
