# Spec: Model Registry & Formats

## Location: `specs/models/registry.md`

### Format Support Matrix
- **Supported Public Formats**:
  - `GGUF`: Quantized models (Q4_0, Q4_K_M, Q8_0, etc.) for RVV/IME.
  - `Safetensors`: Direct tensor maps (FP16, BF16, FP8, INT8).
  - `OCI / Ollama Blobs`: Standard registry layers and manifests.
  - `ONNX`: Portable graphs with CPU/RVV execution providers.
- **Incompatibility Filter**: Reject formats bound to proprietary hardware ISA (e.g., CUDA-only assembly, proprietary NPU bitstreams).

### Storage & Manifest
- Layout: `/var/lib/k3-ai/models/<source>/<model>/<tag>/`
- Manifest: Records tensor types, context window, and core target.
