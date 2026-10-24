# SpacemiT AI SDK (`spacemit-com/ai-sdk`) Complete Technical Reference

This document contains the complete architectural, API, build, and hardware-scheduling reference for the **SpacemiT AI SDK** (`spacemit-com/ai-sdk`) and its integration with the **SpacemiT K3 (`riscv64`)** SoC.

## Companion Findings

- **[SpacemiT K3 Hardware, TCM & HMP Topology](../spacemit-k3-topology/README.md)**: Deep-dive hardware & OS scheduling guide for the SpacemiT K3 (X100 vs A100 clusters, L1/L2 cache asymmetry, 8× 384 KiB TCM blocks, `/dev/tcm` & `/dev/ai_dma`, `spacemit-hmp` vendor kernel vs vanilla kernel, and 2-core / 4-core thread containment rules).
- **[`spacemit_k3_topology.json`](../spacemit-k3-topology/spacemit_k3_topology.json)** / **[`spacemit_k3_topology.rs`](../spacemit-k3-topology/spacemit_k3_topology.rs)** / **[`spacemit_k3_topology.h`](../spacemit-k3-topology/spacemit_k3_topology.h)** / **[`spacemit_k3_topology.py`](../spacemit-k3-topology/spacemit_k3_topology.py)**: Canonical topology manifests and thread containment selectors.

______________________________________________________________________

## 1. Upstream Repository & Submodule Inventory

The upstream `https://github.com/spacemit-com/ai-sdk.git` repository is an umbrella repo with **zero root-level source code**; it aggregates **11 Git submodules** (all tracking branch `main`):

| Submodule Path    | Upstream Git URL                                       | Public Header / Entrypoint                                     | Primary Inference Engine(s)                                                                    | Uses K3 A100 Cores?                                              |
| :---------------- | :----------------------------------------------------- | :------------------------------------------------------------- | :--------------------------------------------------------------------------------------------- | :--------------------------------------------------------------- |
| **`vision/`**     | `https://github.com/spacemit-com/model-zoo-vision.git` | `vision/include/vision_service.h`                              | ONNX Runtime (`SpaceMITExecutionProvider`), OpenCV 4/5, OpenBLAS, V2D + RVV 1.0, OpenCL        | **Yes** (35+ YAML models default to `SpaceMITExecutionProvider`) |
| **`rl/`**         | `https://github.com/spacemit-com/model_zoo_rl`         | `rl/include/rl_service.h`                                      | ONNX Runtime (`libspacemit_ep.so`), optional MNN (`USE_MNN_BACKEND`)                           | **Yes** (`provider: auto\|spacemit`)                             |
| **`asr/`**        | `https://github.com/spacemit-com/model-zoo-asr.git`    | `asr/include/asr_service.h`                                    | ONNX Runtime (SenseVoice, Zipformer CTC), `llama-server` (Qwen3-ASR, Fun-ASR Nano, Gemma4 ASR) | **Yes** (`USE_SPACEMIT_EP=ON` + `llama-server`)                  |
| **`tts/`**        | `https://github.com/spacemit-com/model-zoo-tts`        | `tts/include/tts_service.h`                                    | ONNX Runtime (Matcha-TTS + Vocos vocoder, Kokoro EN/ZH)                                        | **Yes** (`USE_SPACEMIT_EP=ON`)                                   |
| **`vlm/`**        | `https://github.com/spacemit-com/model-zoo-vlm`        | `vlm/include/vlm_service.h`, `vlm/src/python/vlm.py`           | `llama-server` (`llama.cpp-tools-spacemit`) with `--vision-backend smt` (or `mtmd`)            | **Yes** (`--vision-backend smt` uses SpaceMIT EP + TCM on A100)  |
| **`llm/`**        | `https://github.com/spacemit-com/model-zoo-llm.git`    | `llm/include/llm_service.h`                                    | OpenAI-compatible HTTP client (`libcurl`) talking to `llama-server`                            | **Yes** (via external `llama-server`)                            |
| **`gateway/`**    | `https://github.com/spacemit-com/ai-gateway`           | `gateway/src/spacemit_ai_gateway/`                             | FastAPI HTTP + WebSocket service orchestrating ASR, TTS, VAD, Vision, LLM, VLM, Embed, Rerank  | **Yes** (via child `llama-server` and native SDK workers)        |
| **`vad/`**        | `https://github.com/spacemit-com/model-zoo-vad.git`    | `vad/include/vad_service.h`                                    | ONNX Runtime (Silero VAD)                                                                      | **No** (Standard ORT CPU only; runs on X100)                     |
| **`voiceprint/`** | `https://github.com/spacemit-com/model_zoo_voiceprint` | `voiceprint/include/vp_service.h`                              | ONNX Runtime (CAM++ 256-d speaker embedding)                                                   | **No** (Has unimplemented stub for `"spacemit"`; runs on X100)   |
| **`kws/`**        | `https://github.com/spacemit-com/model-zoo-kws.git`    | `kws/include/kws_service.h`                                    | Hand-written C++ CFSMN (no ONNX Runtime, no BLAS)                                              | **No** (Single-thread `num_threads=1` on X100, ~2.7% of 1 core)  |
| **`build/`**      | `https://github.com/spacemit-robotics/build`           | `build/envsetup.sh`, `build/common.sh`, `build/cross_build.sh` | CMake / ROS2 / Docker / Sysroot build scripts (`m`, `mm`, `lunch`)                             | N/A (Maps `k3*` targets to `bianbu:4.0` / `ubuntu:26.04`)        |

______________________________________________________________________

## 2. System Packages & Proprietary Runtime Stack on SpacemiT K3

The SDK itself contains **no custom A100 matrix/IME assembly instructions**. All A100 and TCM hardware exploitation is performed by closed-source SpacemiT system packages installed via Bianbu `apt`:

| Debian Package                 | Version (on K3)          | Shared Libraries / Binaries                                                                               | Role in A100 / TCM Exploitation                                                                                                                                                       |
| :----------------------------- | :----------------------- | :-------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`spacemit-tcm`**             | `3.0.1`                  | `/usr/bin/spacemit-tcm-smi`, `/dev/tcm` (`misc` 10:260), `/dev/ai_dma` (239:0), `/dev/aidma_list` (238:0) | Manages the 8× 384 KiB (`393,216` B = `3 MiB` total) TCM blocks wired to `cpu8–15` (A100) and promotes worker threads from `HMP_REGULAR` to `HMP_AI` via `hmp_set_ai_thread(pid_t)`.  |
| **`spacemit-runtime`**         | `0.6.2`                  | `libspine` / SpacemiT spine runtime                                                                       | Low-level A100 / TCM execution runtime (depends on `spacemit-tcm >= 3.0.1`).                                                                                                          |
| **`spacemit-onnxruntime`**     | `2.0.7+2` (or `2.0.6+1`) | `libonnxruntime.so`, `libspacemit_ep.so`, `spacemit_ort_env.h`                                            | Custom ONNX Runtime build + `SpaceMITExecutionProvider` (`libspacemit_ep.so`), which compiles ONNX subgraphs onto A100 cores + TCM + AI-DMA (depends on `spacemit-runtime >= 0.6.1`). |
| **`python3-spacemit-ort`**     | `2.0.7+2`                | Python `onnxruntime` bindings                                                                             | Python interface to `SpaceMITExecutionProvider`.                                                                                                                                      |
| **`llama.cpp-tools-spacemit`** | `0.1.9` (or `0.1.7`)     | `/usr/bin/llama-server`                                                                                   | Custom `llama.cpp` build with `CPU_RISCV64_SPACEMIT` backend and `--vision-backend smt` (depends on `spacemit-onnxruntime` and `spacemit-runtime >= 0.6.1`).                          |
| **`/opt/opencv-spacemit`**     | OpenCV 4 / 5             | `libopencv_*.so` (`libopencv_geometry.so` in v5)                                                          | Vendor OpenCV build used by `vision/`.                                                                                                                                                |
| **`/opt/openblas-spacemit`**   | OpenBLAS                 | `libopenblas.so`                                                                                          | Vendor OpenBLAS linked by `vision/` (`EIGEN_USE_BLAS`).                                                                                                                               |
| **`/opt/eigen-spacemit`**      | Eigen3                   | `/opt/eigen-spacemit/include/eigen3`                                                                      | Vendor Eigen headers used by `vision/`.                                                                                                                                               |

> [!WARNING]
> Standard Ubuntu/Debian packages `libonnxruntime-dev`, `libonnxruntime1.23`, and `python3-onnxruntime` **conflict** with `spacemit-onnxruntime` on K3 and do **not** include `libspacemit_ep.so` or `spacemit_ort_env.h`. They must be removed before installing `spacemit-onnxruntime`:
>
> ```bash
> sudo apt remove libonnxruntime-dev libonnxruntime1.23 python3-onnxruntime
> sudo apt install -y libeigen3-dev libyaml-cpp-dev spacemit-tcm pkg-config \
>   libonnx-dev libonnx-testdata libonnx1t64 libonnxruntime-providers \
>   onnxruntime-tools python3-onnx python3-spacemit-ort spacemit-onnxruntime \
>   llama.cpp-tools-spacemit
> ```

______________________________________________________________________

## 3. `SpaceMITExecutionProvider` (`libspacemit_ep.so`) C++ Integration Reference

### 3.1 Header & CMake Discovery

- Header: `#include "spacemit_ort_env.h"`
- Libraries: `onnxruntime` and `spacemit_ep` (`libspacemit_ep.so`)
- Registration Function Signatures (in namespace `Ort`):
  ```cpp
  // 1-argument overload (used in vision/)
  Ort::Status Ort::SessionOptionsSpaceMITEnvInit(Ort::SessionOptions& options);

  // 2-argument overload (used in rl/, asr/, tts/)
  Ort::Status Ort::SessionOptionsSpaceMITEnvInit(
      Ort::SessionOptions& options,
      const std::unordered_map<std::string, std::string>& provider_options);
  ```

### 3.2 Supported `provider_options` Keys & Environment Variables

| Option Key / Env Var                     | Format / Values                                             | Behavior & Usage in SDK                                                                                                                                                          |
| :--------------------------------------- | :---------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`SPACEMIT_EP_INTRA_THREAD_NUM`**       | `"1"` .. `"8"` (string integer)                             | Number of A100 worker threads spawned inside `SpaceMITExecutionProvider` for this `Ort::Session`.                                                                                |
| **`SPACEMIT_EP_INTRA_THREAD_AFFINITY`**  | Semicolon-separated EP CPU IDs, e.g. `"0;1"` or `"0;1;2;3"` | Pins the EP's intra-op worker threads to specific A100 cores (`0..7` map to `cpu8..15`). **The number of semicolon-separated IDs must equal `SPACEMIT_EP_INTRA_THREAD_NUM`.**    |
| **`SPACEMIT_EP_DUMP_SUBGRAPHS`**         | `"1"`                                                       | Exports the subgraphs compiled by `SpaceMITExecutionProvider` (used in `rl` `--ep-dump-subgraphs` to verify operators did not silently fall back to CPU).                        |
| **`SPACEMIT_EP_DEBUG_PROFILE`**          | `<prefix_string>`                                           | Exports EP execution profile JSON files with the given prefix (used in `rl` `--ep-profile`).                                                                                     |
| **`SPACEMIT_EP_DISABLE_OP_TYPE_FILTER`** | Semicolon/string op type list, e.g. `"Conv"`                | Forces all operators of the specified ONNX op type(s) to fall back to `CPUExecutionProvider` (required on K3 for `asr/` Zipformer: `SPACEMIT_EP_DISABLE_OP_TYPE_FILTER="Conv"`). |
| **`SPACEMIT_EP_DISABLE_OP_NAME_FILTER`** | Node name filter string                                     | Excludes specific named ONNX graph nodes from `SpaceMITExecutionProvider` (used in `tts/` Kokoro `getConvFallbackFilter()`).                                                     |

### 3.3 Best-Practice Initialization Pattern (from `rl/src/backends/onnx/onnx_infer.cpp` & `asr/`)

When initializing an ONNX Runtime session with `SpaceMITExecutionProvider` on K3, follow these 4 rules:

1. **Set ORT `SetIntraOpNumThreads(1)` when using `SpaceMITExecutionProvider`**:
   - `SpaceMITExecutionProvider` manages its own A100 thread pool sized by `SPACEMIT_EP_INTRA_THREAD_NUM`. Leaving ORT's `SetIntraOpNumThreads(N)` at `N > 1` spawns redundant ORT CPU threads on the X100 cores for any fallback nodes.
1. **Control ORT CPU worker spinning via `session.intra_op.allow_spinning`**:
   - `session_options.AddConfigEntry("session.intra_op.allow_spinning", "0")` stops ORT's CPU fallback thread pool from busy-spinning between periodic inferences (note: this does not control the EP's internal A100 workers).
1. **Never call `DisableCpuMemArena()` or `DisableMemPattern()` when `SpaceMITExecutionProvider` is active**:
   - As documented in `asr/src/backends/sensevoice/sensevoice_model.cpp` and `tts/src/backends/kokoro/kokoro_backend.cpp`, `SpaceMITExecutionProvider` requires ORT's memory arena and memory pattern enabled for TCM/DMA buffer management. Only disable them when falling back to pure `CPUExecutionProvider` on RISC-V.
1. **Contain `SPACEMIT_EP_INTRA_THREAD_AFFINITY` within a 2-core TCM pair or 4-core A100 cluster**:
   - For 2 threads: use `"0;1"`, `"2;3"`, `"4;5"`, or `"6;7"` (keeps both threads in the same `768 KiB` TCM pair).
   - For 4 threads: use `"0;1;2;3"` (Cluster 2: `cpu8–11`) or `"4;5;6;7"` (Cluster 3: `cpu12–15`).

```cpp
Ort::SessionOptions session_options;
session_options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
session_options.SetInterOpNumThreads(1);
session_options.AddConfigEntry("session.intra_op.allow_spinning", "0");

// Rule 1: ORT intra-op = 1 when using SpaceMIT EP; EP uses its own thread pool
session_options.SetIntraOpNumThreads(1);

std::unordered_map<std::string, std::string> ep_options = {
    {"SPACEMIT_EP_INTRA_THREAD_NUM", std::to_string(ep_threads)},
    {"SPACEMIT_EP_INTRA_THREAD_AFFINITY", ep_affinity} // e.g., "0;1" or "0;1;2;3"
};

Ort::Status status = Ort::SessionOptionsSpaceMITEnvInit(session_options, ep_options);
if (!status.IsOK()) {
    // Fallback to pure CPU on X100 cores
    session_options.SetIntraOpNumThreads(cpu_threads);
    session_options.DisableMemPattern();
    session_options.DisableCpuMemArena();
}
```

______________________________________________________________________

## 4. Submodule-Specific Implementation Details, Quirks & Bugs

### 4.1 `vision/` (`model-zoo-vision`)

- **Inconsistent 1-arg `SessionOptionsSpaceMITEnvInit` Call**:
  - In `vision/src/core/cpp/vision_model_base.cpp` (lines 233–243), `mobilesam_segmentor.cpp`, `nanotrack_tracker.cpp`, `ppocr_detector.cpp`, and `siglip2_encoder.cpp`, `vision` calls `session_options.SetIntraOpNumThreads(num_threads)` followed by the **1-argument** `Ort::SessionOptionsSpaceMITEnvInit(session_options)` without passing `SPACEMIT_EP_INTRA_THREAD_NUM` or `SPACEMIT_EP_INTRA_THREAD_AFFINITY`.
- **Multi-Session Thread Budgeting Across the 8 A100 Cores**:
  - Single-model YAML configs in `vision/examples/*/config/*.yaml` default to `num_threads: 8` (or `4` for trackers/encoders like `mixformer`, `nanotrack`, `lightglue`, `superpoint`, `siglip2`, `mobileclip2`, `ppocr`), while `gateway/configs/vision/*.yaml` defaults all models to `num_threads: 4` (or `3` for `ocsort`/`bytetrack`).
  - `vision/examples/mobilesam1/README.md` explicitly warns: *"On a board with 8 A100 cores, do not allocate 8 threads to each of two EP Sessions simultaneously."*
  - Multi-model applications in `vision/applications/` partition the 8 A100 threads across sessions:
    - `fall_detection`: `pose.yaml` (`6`) + `stgcn.yaml` (`2`) = **8 threads**.
    - `face_recognition`: `scrfd.yaml` (`4`) + `arcface_buffalo.yaml` (`2`) + `landmark2d106.yaml` (`1`) + `genderage.yaml` (`1`) = **8 threads**.
    - `emotion_detection`: `face_detector.yaml` (`4`) + `emotion_features.yaml` (`2`) + `emotion_lstm.yaml` (`2`) = **8 threads**.
- **Hardware-Accelerated Preprocessing (`VISION_WITH_V2D`, `VISION_WITH_MPP`, `VISION_WITH_OPENCL`)**:
  - **V2D + RVV 1.0 (`src/backends/spacemit/v2d_image_preprocessor.cpp` & `src/operators/image_preprocess/rvv_image_pack.h`)**:
    - Compiled with `-march=rv64gcv`. Uses SpacemiT's `V2D` hardware blitter (`/dev/v2d_dev`) on zero-copy NV12 `DMA-BUF` frames (`input.dma_fd`, 16-byte aligned stride) to resize/convert to interleaved RGB, then uses hand-written RVV 1.0 segmented vector loads (`__riscv_vlseg3e8_v_u8m1x3`, `__riscv_vzext_vf2_u16m2`, `__riscv_vfwcvt_f_xu_v_f32m4`, `__riscv_vfsub_vf_f32m4`, `__riscv_vfmul_vf_f32m4`, `__riscv_vse32_v_f32m4`) on the X100 cores to normalize and unpack into planar `NCHW` `float32`.
  - **MPP (`src/common/cpp/mpp_frame_source.cpp`)**: Sets `K3_V4L2_DEV` and uses `libspacemit_mpp.so` for hardware camera/video decoding.
  - **Eigen + OpenBLAS**: Compiles with `-DEIGEN_USE_BLAS` and links `/opt/openblas-spacemit/lib/libopenblas.so` for post-processing matrix multiplications (e.g. YOLOv8-Seg mask assembly).

### 4.2 `rl/` (`model_zoo_rl`)

- **Architecture**: YAML-driven robot policy executor (`PolicyExecutor`: `AssembleObs` $\\rightarrow$ `Infer` $\\rightarrow$ `MapActionToTargetPos`) supporting `observation`, `observation_history` (`flat_history` or `frame_history`), recurrent `feedback`, `constant`, and `external` tensor inputs.
- **Benchmarking & Real-Time Metrics (`rl/example/benchmark_common.h`, `benchmark_policy_executor.cpp`, `benchmark_onnx_infer.cpp`)**:
  - Supports `--mode throughput|periodic` (using `steady_clock::sleep_until` at `--hz N`, e.g. 50 Hz), `--overrun drop|backlog`, `--provider auto|cpu|spacemit`, `--threads N`, `--ort-spinning on|off`, `--affinity CPU_LIST` (Linux process `sched_setaffinity`), and `--ep-affinity CPU_LIST` (converted via `EpAffinityFromCpuList()` to semicolon-separated `SPACEMIT_EP_INTRA_THREAD_AFFINITY`).

### 4.3 `tts/` (`model-zoo-tts`)

- **Backends**:
  - `MATCHA_ZH`, `MATCHA_EN`, `MATCHA_ZH_EN`: Two ONNX sessions (`acoustic` model + `vocos` vocoder). SDK `TtsConfig::num_threads` defaults to `2`, while `matcha_backend.cpp` reads `SPACEMIT_TTS_EP_THREADS` / `SPACEMIT_TTS_CPU_THREADS` (defaulting to `3`).
  - `KOKORO`, `KOKORO_EN`, `KOKORO_ZH`: Preset `num_threads = 4`. Uses `SPACEMIT_EP_DISABLE_OP_NAME_FILTER` (`getConvFallbackFilter()`) to bypass broken Conv nodes in the EP.
  - **Kokoro Dynamic Token Bucketing Workaround**: When `using_spacemit_ep_` is true (`kokoro_backend.cpp` lines 740–750, 895–905), Kokoro disables cross-sentence merging and caps `runtime_max_effective_tokens` to `ZH_EP_WARMUP_EFFECTIVE_TOKENS` / `EN_EP_WARMUP_EFFECTIVE_TOKENS` to prevent TCM subgraph recompilation/overflow on long sentences.

### 4.4 `asr/` (`model-zoo-asr`)

- **ONNX Backends**:
  - `SenseVoice` (`sensevoice_model.cpp`): Default `num_threads = 2` (`1` in Gateway; achieves RTF `0.129` on 1.80s audio with `num_threads=1, device=spacemit` on K3).
  - `Zipformer` (`zipformer_ctc_model.cpp`): Requires `SPACEMIT_EP_DISABLE_OP_TYPE_FILTER="Conv"` on K3 due to a temporary `Conv` operator bug in `libspacemit_ep.so`.
- **LLM Audio Backends (`llama_audio_client.cpp`)**:
  - Supports `Qwen3-ASR` (Q4_0), `Fun-ASR Nano` (Q4_K_M), and `Gemma4 ASR` (Q4_0) via HTTP requests to `llama-server` (`llama.cpp-tools-spacemit`).

### 4.5 `vlm/`, `llm/`, and `gateway/` (`llama.cpp-tools-spacemit` Integration)

- **How `vlm` Spawns `llama-server` (`vlm/src/core/cpp/server_vlm_model.cpp` & `vlm_config.cpp`)**:
  - Defaults `cpu_affinity` to `"0-7"` (the 8 X100 cores) and builds the command:
    ```bash
    OMP_NUM_THREADS=8 taskset -c 0-7 llama-server -m <text_model.gguf> \
      --port 8080 --ctx-size <ctx> -t 8 -tb 8 --host 127.0.0.1 -ngl 0 \
      --vision-backend smt --smt-config-dir <model_dir>
    ```
  - Why `taskset -c 0-7`? Because on the SpacemiT vendor kernel (`spacemit-hmp`), `taskset` runs in user space as an `HMP_REGULAR` process and is only permitted on `cpu0–7` (passing `8-15` to `taskset` fails with `EINVAL`). Once `llama-server` starts, its `--vision-backend smt` module loads `SpaceMITExecutionProvider` (`libspacemit_ep.so`), which opens `/dev/tcm`, promotes its internal worker threads to `HMP_AI` via `hmp_set_ai_thread()`, and executes the vision encoder across the A100 cores (`cpu8–15`) and their 384 KiB TCM blocks.
- **Known K3 `llama-server` Shared Memory Warning (`gateway/src/spacemit_ai_gateway/common/llama_process.py`)**:
  - Every launch of `llama-server` (`llama.cpp-tools-spacemit`) on K3 prints:
    `CPU_RISCV64_SPACEMIT: failed to allocate init_barrier from shared mem, falling back to heap`
  - Do **not** treat `"failed to allocate"` as a fatal OOM error in log parsers; match specific buffer failure strings (`"failed to allocate buffer"`, `"failed to allocate cpu buffer"`).
- **Gateway Telemetry (`gateway/frontend/console/src/ResourceBar.jsx`)**:
  - Detects K3 via `cores.length === 16`, labeling `cores.slice(0, 8)` as **`X100`** and `cores.slice(8, 16)` as **`A100`**.

### 4.6 Speech Modules Running Purely on X100 (`vad/`, `voiceprint/`, `kws/`)

- **`voiceprint/` Bug**: `voiceprint/CMakeLists.txt` finds and links `libspacemit_ep.so` (`USE_SPACEMIT_EP`), and `voiceprint/README.md` instructs K3 users to enable it, but `voiceprint/src/backends/campplus/onnx_model.cpp` (lines 94–96) has an unimplemented stub:
  ```cpp
  } else if (provider == "spacemit") {
      std::cerr << "SpaceMIT provider requested but not implemented in this version" << std::endl;
  }
  ```
  Furthermore, `voiceprint/CMakeLists.txt` (line 100) compiles with `-march=rv64gc` (omitting the `v` RVV extension).
- **`vad/`**: `vad/src/backends/silero/silero_backend.cpp` uses standard `Ort::SessionOptions` (`num_threads = 1`, `ORT_ENABLE_EXTENDED`) without `spacemit_ort_env.h`.
- **`kws/`**: `kws/src/backends/cfsmn/cfsmn_backend.cpp` is a hand-written single-threaded C++ CFSMN implementation (`num_threads` must be `1`) that consumes ~2.7% of a single X100 core on K3.
