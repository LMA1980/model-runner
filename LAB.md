# SpacemiT K3 Local Lab Environment

This document defines the local lab infrastructure for the SpacemiT K3 platform, execution workflows, and system constraints.

______________________________________________________________________

## 1. Remote Host Topology (`pey-wail-deu`)

The lab runs on a dedicated SpacemiT K3 system accessible via SSH alias:

```bash
ssh pey-wail-deu
```

### Hardware Specifications

- **SoC**: SpacemiT K3 16-core RISC-V Heterogeneous Architecture:
  - **Cluster 0 (Cores 0–7)**: SpacemiT A100 (614 MHz – 1800 MHz)
  - **Cluster 1 (Cores 8–15)**: SpacemiT X100 (614 MHz – 2150 MHz, high-performance)
- **Vector Units**: RVV 1.0 (`+v`) hardware support per core
- **Memory**: 32 GB Unified RAM + 32 GB Swap
- **OS / Kernel**: Linux 6.18.3-generic riscv64 GNU/Linux (Bianbu / SpacemiT OS)

______________________________________________________________________

## 2. Storage Architecture & Best Practices

> [!IMPORTANT]
> **Always operate on the NVMe storage.**
> The root filesystem (`/`) resides on flash/eMMC. A high-performance 2TB NVMe SSD (`/dev/nvme0n1p1`) is mounted at:
>
> ```text
> /home/lma1980/repository
> ```
>
> All repository checkouts, build artifacts, model weights, cache directories, and test runs **must** reside under `/home/lma1980/repository/model-runner` to avoid I/O bottlenecks and prevent wear on flash storage.

______________________________________________________________________

## 3. Experimental Toolchains on Remote Host

Custom toolchains built on the NVMe drive are located in `~/opt` on `pey-wail-deu`:

| Toolchain                | Path                         | Description                                          |
| :----------------------- | :--------------------------- | :--------------------------------------------------- |
| **LLVM / Clang 24**      | `~/opt/llvm-24`              | Clang/LLVM 24.0.0git with SpacemiT RVV optimizations |
| **GCC 17**               | `~/opt/gcc-17`               | Upstream GCC 17.0.0 (experimental)                   |
| **GCC 17 SpacemiT X100** | `~/opt/gcc-17-spacemit-x100` | GCC 17 tuned specifically for the X100 core cluster  |
| **System Rust / Cargo**  | `/usr/bin/cargo`             | Native Rust 1.97.0 / Cargo on RISC-V                 |

______________________________________________________________________

## 4. Execution Workflows

### Workflow A: Validating Cross-Compiled Binaries

When cross-compiling locally on macOS (via `cross` or Cargo), you can test and verify execution on the real K3 hardware:

1. **Automatic Cargo Runner**:
   In `code/`, Cargo is configured to use [`scripts/k3-runner.sh`](scripts/k3-runner.sh) automatically:

   ```bash
   cd code
   cross test --target riscv64gc-unknown-linux-gnu
   ```

   *Cargo compiles locally, copies the binary directly to NVMe (`~/repository/model-runner/target/remote-run/`), executes it on the K3 SoC, prints the test output, and cleans up.*

2. **Syncing Remote NVMe Storage via Git**:
   To update the `pey-wail-deu` repository and submodules via `git pull` and `git submodule`:

   ```bash
   ./scripts/k3-sync.sh
   ```

______________________________________________________________________

### Workflow B: Running Benchmarks on Native Hardware

Use [`scripts/k3-bench.sh`](scripts/k3-bench.sh) to execute benchmarks directly on `pey-wail-deu`:

```bash
# Run benchmark on high-performance SpacemiT X100 cores (cores 8-15)
./scripts/k3-bench.sh --cores x100

# Benchmark on A100 cores (cores 0-7)
./scripts/k3-bench.sh --cores a100

# Benchmark using Clang/LLVM 24
./scripts/k3-bench.sh --cores x100 --toolchain llvm-24

# Benchmark using GCC 17
./scripts/k3-bench.sh --cores x100 --toolchain gcc-17
```
