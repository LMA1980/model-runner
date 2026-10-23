# Feature: Operator Diagnostic Tool

## Codename: `diag-tool`

### Purpose & Delivery

Non-interactive CLI binary (`k3-diag`) for standalone model evaluation, multi-core synchronization benchmarking, heterogeneous cluster workload splitting, and SpacemiT IME matrix acceleration profiling (US-01, US-02, US-03, ADR-009, ADR-010, ADR-033, ADR-034).

### CLI Capabilities

- Delivered as the unified `k3-diag` binary in `code/engine/bins/k3-diag` with selectable coordination profiles (`--coord <spin|futex|rayon>`).
- Options:
  - `-m, --model <path>`: Path to local GGUF model file (required).
  - `-p, --prompt <text>`: Input prompt to tokenize and evaluate in-process.
  - `--cluster <both|x100|a100>`: Target processor cluster (`x100` = cores 0–7 `0x00FF`, `a100` = cores 8–15 `0xFF00`, `both` = dual-cluster across both pools).
  - `--split <phase|op|row>`: Cross-cluster work distribution policy for `--cluster both` (ADR-009):
    - `phase`: Prompt prefill on `a100`, autoregressive token decode on `x100`.
    - `op`: Matrix multiplications on `a100`, normalization and attention on `x100`.
    - `row`: Matrix output-tile rows partitioned concurrently across `x100` and `a100` in proportion to measured per-cluster throughput.
  - `--ime <on|off>`: Toggle SpacemiT IME matrix acceleration (`XSMTVDotII` / `smt.vmadot` on `a100`; rejected with exit code `10` on `x100`-only placement) (ADR-034).
  - `-t, --threads <n>`, `--cores <mask>`, `--n-ctx <tokens>`, `--max-tokens <n>`, `--coord <spin|futex|rayon>`, `--repeat <n>` ($N \ge 3$), `--json`.
- Process exit codes:
  - `0`: Evaluation and determinism verification succeeded.
  - `2`: Malformed CLI flags or invalid flag combinations (e.g., `--cluster both` without `--split`, or `--split` with a single cluster).
  - `10`: `CapabilityMismatch` (unsupported model architecture, `--ime on` on a cluster without IME support, or determinism violation across repeats).
  - `11`: `InsufficientLockableMemory` (pre-flight `mlock` admission failure).
  - `12`: `ContextLengthExceeded` (prompt tokens exceed `--n-ctx`).
  - `13`: `AffinityError` (mixed-cluster `--cores` mask without an explicit `--split` policy, offline cores, or thread-to-core oversubscription).
  - `14`: `TensorBoundsError`.

### Metrics & Self-Comparison

- Benchmarks the engine's own integer/RVV/IME kernels against themselves with no external `llama.cpp` or Ollama baseline (ADR-033).
- Measures prefill and decode latency and throughput separately, reporting each phase as a percentage of its measured hardware ceiling (`peak_macs` for prefill, streaming `memory_bandwidth` for decode) with no pass/fail speed threshold (ADR-034).
- When `--ime on` is selected, measures both the IME (`ime-vmadot`) and baseline RVV (`rvv-vwmul`) arms on the same placement, prompt, and model, reporting both throughputs and the IME-attributable prefill and decode throughput delta (`ime_comparison`).
- Verifies bit-identical generated token sequences at temperature 0 across `--repeat` runs (`determinism_verified` / `determinism`) and audits `/proc/self/task/<tid>/status` (`Cpus_allowed_list`) plus `sched_getcpu()` before and after execution (`cluster_isolation_verified`, `workers_before`, `workers_after`).
- Emits structured machine-readable JSON (`--json`) consumed by `k3 tune` recommendations (ADR-010, ADR-032).
