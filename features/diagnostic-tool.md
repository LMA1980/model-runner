# Feature: Operator Diagnostic Tool

## Codename: `diag-tool`

### Business Logic
A non-interactive operator CLI tool enabling rapid validation, benchmarking, and quality evaluation of models on the K3 runtime.

### Capabilities
1. **Non-Interactive Execution**:
   - Single-shot execution via CLI args or piped input.
   - Outputs structured latency, TTFT (time-to-first-token), and tokens/s metrics.
2. **Decision Model Evaluation**:
   - Native support for structured evaluation payloads (e.g., classification, routing, and multi-criteria choice prompts).
   - Validates accuracy and schema compliance against expected outcomes.
3. **Specialized Model Testing**:
   - Tests compact reasoning models (e.g., `tev1`, `nimble`, `0.8B`) vs larger generative models.
   - Verifies execution correctness on X100 vs A100 cores.
