# Spec: Model Registry & Formats

## Location: `specs/models/registry.md`

### Search & Download Lifecycle
1. **Search Request**: Discovers compatible models across repositories (Hugging Face, Ollama, vendors), exposing model name, source, and variants (Q4_K_M, Q8_0).
2. **Pull Request**: Specifies source, model, and variant. `k3-manager` directly initiates the download, verifies checksums, and manages storage in the registry.

### Format Support Matrix
- **Supported Public Formats**:
  - `GGUF`: Quantized models (Q4_K_M, Q8_0, etc.) for RVV/IME.
  - `Safetensors`: Direct tensor maps (FP16, BF16, FP8, INT8).
  - `OCI / Ollama Blobs`: Standard registry layers and manifests.
- **Incompatibility Filter**: Reject formats bound to proprietary hardware ISA (e.g., CUDA-only assembly, proprietary NPU bitstreams).

### Storage Layout
- Path: `/var/lib/k3-ai/models/<source>/<model>/<tag>/`
- Manifest: Records tensor types, context window, and core target.
