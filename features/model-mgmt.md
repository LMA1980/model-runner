# Feature: Model Management & Formats

## Codename: `model-mgmt`

### Business Logic
Manage model weights, format ingestion, and vendor repository integrations.

### Broad Public Format Support
- **Universal Ingestion**: Support mainstream public formats including GGUF, Safetensors, OCI/Ollama blobs, and ONNX.
- **Architecture Compatibility Filter**: Accept any format whose layers and tensors can execute on RISC-V RVV / IME. Reject formats requiring incompatible proprietary architectures (e.g., hardcoded CUDA PTX / Metal kernels).

### Vendor Adapters & Integrity
1. **Pluggable Adapters**: CLI/RPC plugins for proprietary/vendor model stores.
2. **Quantization & Verification**: SHA-256 checks, quantization validation (Q4_K, Q8_0, FP16, BF16, FP8), and layer deduplication.
