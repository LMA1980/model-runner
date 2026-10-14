# Feature: Operator Diagnostic Tool

## Codename: `diag-tool`

### Business Logic
Non-interactive operator CLI tool for rapid benchmarking, model verification, and decision-task evaluation.

### Multi-Stage Delivery
1. **Stage 1 (Direct Model Evaluation)**:
   - Standalone execution directly in `k3-engine`.
   - Direct GGUF loading; benchmarks latency, TTFT, tokens/s, and core placement.
2. **Stage 2 (Manager Querying)**:
   - Interacts with `k3-manager` daemon to request model loading and session dispatch.

### Input Flexibility
- Plain prompt via `--prompt "..."` for standard generation.
- Structured JSON via `--file <path>` or stdin for multi-criteria decision models.
