# SpacemiT K3 Hardware Topology, TCM Tiling & Thread Scheduling Guide

This document provides the complete hardware, Device Tree, cache, TCM, and OS scheduling specification for the **SpacemiT K3 (`riscv64`)** SoC, verified against live hardware (`pey-wail-deu`, running `Linux 6.18.3-generic #1.0.8.4 SMP PREEMPT_DYNAMIC riscv64`).

## Companion Artifacts in This Directory

- [`spacemit_k3_topology.json`](spacemit_k3_topology.json): Machine-readable canonical JSON specification of the K3 CPU topology, caches, TCM blocks, Device Tree phandles, and optimal thread-affinity lookup tables.
- [`spacemit_k3_topology.rs`](spacemit_k3_topology.rs): Dependency-free Rust topology & thread-affinity helper module.
- [`spacemit_k3_topology.h`](spacemit_k3_topology.h): Header-only C99 / C++17 topology & thread-affinity helper library.
- [`spacemit_k3_topology.py`](spacemit_k3_topology.py): Dependency-free Python 3 topology & thread-affinity helper module.

______________________________________________________________________

## 1. CPU Clusters, Cache Hierarchy & ISA Signatures

The SpacemiT K3 has **16 RISC-V 64-bit cores** organized into **4 clusters of 4 cores each** (`mvendorid = 0x710`, `mmu = sv39`):

- **2× X100 Clusters (`cpu0–3` and `cpu4–7`)**: High-clock general-purpose out-of-order cores (`2.15 GHz`), each core with **64 KiB L1I + 64 KiB L1D**, and **4 MiB Unified L2 per 4-core cluster** (8 MiB L2 total across X100). Includes the RISC-V Hypervisor (`h`) extension.
- **2× A100 Clusters (`cpu8–11` and `cpu12–15`)**: AI/Matrix-coupled compute cores (`1.80 GHz`), each core with **32 KiB L1I + 32 KiB L1D**, and **1 MiB Unified L2 per 4-core cluster** (2 MiB L2 total across A100), plus **1.5 MiB of Tightly Coupled Memory (`spacemit,k1-tcm`) per 4-core cluster** (3 MiB TCM total). Tagged with the **`cpu-ai`** property in `/proc/device-tree/cpus/cpu@8..15`.

### 1.1 Cluster & Core-Pair Breakdown

| Cluster       | Logical CPUs | Core Type (`uarch`) | `marchid` / `mimpid`                        | Max Freq | L1I / L1D (per core) | Shared L2 (per 4-core cluster)    | Coupled TCM (`tcm@00000000`)                                                                                                                                        |
| :------------ | :----------- | :------------------ | :------------------------------------------ | :------- | :------------------- | :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Cluster 0** | `cpu0–3`     | `spacemit,x100`     | `0x8000000058000002` / `0x33d8a600`         | 2150 MHz | `64 KiB` / `64 KiB`  | **`4,096 KiB` (4 MiB)** (`0–3`)   | None                                                                                                                                                                |
| **Cluster 1** | `cpu4–7`     | `spacemit,x100`     | `0x8000000058000002` / `0x33d8a600`         | 2150 MHz | `64 KiB` / `64 KiB`  | **`4,096 KiB` (4 MiB)** (`4–7`)   | None                                                                                                                                                                |
| **Cluster 2** | `cpu8–11`    | `spacemit,a100`     | `0x8000000041000002` / `0x10000000d5686200` | 1800 MHz | `32 KiB` / `32 KiB`  | **`1,024 KiB` (1 MiB)** (`8–11`)  | **`1,536 KiB` (1.5 MiB)** (`cluster0_tcm` @ `0x00000000`, `c2_tcm_pipe_clk`):<br>• `768 KiB` (`2×384K`) → **`cpu8,9`**<br>• `768 KiB` (`2×384K`) → **`cpu10,11`**   |
| **Cluster 3** | `cpu12–15`   | `spacemit,a100`     | `0x8000000041000002` / `0x10000000d5686200` | 1800 MHz | `32 KiB` / `32 KiB`  | **`1,024 KiB` (1 MiB)** (`12–15`) | **`1,536 KiB` (1.5 MiB)** (`cluster1_tcm` @ `0x02000000`, `c3_tcm_pipe_clk`):<br>• `768 KiB` (`2×384K`) → **`cpu12,13`**<br>• `768 KiB` (`2×384K`) → **`cpu14,15`** |

### 1.2 Shared RISC-V ISA Extensions (`/proc/cpuinfo`)

Both X100 and A100 cores expose RV64GCV + vector crypto/BF16/FP16 extensions:

- **X100 (`cpu0–7`) `hart isa`**:
  `rv64imafdcvh_zicbom_zicbop_zicboz_zicntr_zicond_zicsr_zifencei_zihintntl_zihintpause_zihpm_zimop_zaamo_zalrsc_zawrs_zfa_zfbfmin_zfh_zfhmin_zca_zcb_zcd_zcmop_zba_zbb_zbc_zbs_zkt_zvbb_zvbc_zve32f_zve32x_zve64d_zve64f_zve64x_zvfbfmin_zvfbfwma_zvfh_zvfhmin_zvkb_zvkg_zvkned_zvknha_zvknhb_zvksed_zvksh_zvkt_smaia_smstateen_ssaia_sscofpmf_ssnpm_sstc_svade_svinval_svnapot_svpbmt_sdtrig`
- **A100 (`cpu8–15`) `hart isa`**:
  Identical to X100 except **`h` (Hypervisor) is absent** from `hart isa` (`rv64imafdcv_...`).

______________________________________________________________________

## 2. Tightly Coupled Memory (`tcm@00000000`) & AI-DMA (`aidma-dev@0`)

In `/proc/device-tree/soc/tcm@00000000` (`compatible = "spacemit,k1-tcm"`), the K3 exposes **8 TCM blocks of `0x60000` bytes (`384 KiB` = `393,216` bytes) each**, totaling **`3,145,728` bytes (`3 MiB`)**, accompanied by `/dev/tcm` (misc `10:260`), `/dev/ai_dma` (`239:0`), and `/dev/aidma_list` (`238:0`):

| TCM Block ID | DT Node Name           | Physical Address Offset |      Block Size       | Bound CPU DT Phandles | Bound Logical CPUs (A100 Pair) | `SPACEMIT_EP` Logical Pair |
| :----------: | :--------------------- | :---------------------: | :-------------------: | :-------------------: | :----------------------------: | :------------------------: |
|    **0**     | `cluster0_tcm@0`       |      `0x00000000`       | `0x60000` (`384 KiB`) |     `<0x14 0x15>`     |  **`cpu8, cpu9`** (Cluster 2)  |          `"0;1"`           |
|    **1**     | `cluster0_tcm@60000`   |      `0x00060000`       | `0x60000` (`384 KiB`) |     `<0x14 0x15>`     |  **`cpu8, cpu9`** (Cluster 2)  |          `"0;1"`           |
|    **2**     | `cluster0_tcm@c0000`   |      `0x000c0000`       | `0x60000` (`384 KiB`) |     `<0x16 0x17>`     | **`cpu10, cpu11`** (Cluster 2) |          `"2;3"`           |
|    **3**     | `cluster0_tcm@120000`  |      `0x00120000`       | `0x60000` (`384 KiB`) |     `<0x16 0x17>`     | **`cpu10, cpu11`** (Cluster 2) |          `"2;3"`           |
|    **4**     | `cluster1_tcm@2000000` |      `0x02000000`       | `0x60000` (`384 KiB`) |     `<0x18 0x19>`     | **`cpu12, cpu13`** (Cluster 3) |          `"4;5"`           |
|    **5**     | `cluster1_tcm@2060000` |      `0x02060000`       | `0x60000` (`384 KiB`) |     `<0x18 0x19>`     | **`cpu12, cpu13`** (Cluster 3) |          `"4;5"`           |
|    **6**     | `cluster1_tcm@20c0000` |      `0x020c0000`       | `0x60000` (`384 KiB`) |     `<0x1a 0x1b>`     | **`cpu14, cpu15`** (Cluster 3) |          `"6;7"`           |
|    **7**     | `cluster1_tcm@2120000` |      `0x02120000`       | `0x60000` (`384 KiB`) |     `<0x1a 0x1b>`     | **`cpu14, cpu15`** (Cluster 3) |          `"6;7"`           |

______________________________________________________________________

## 3. Vendor Kernel (`spacemit-hmp`) vs Vanilla Kernel Scheduling

### 3.1 SpacemiT Vendor Kernel (`linux-image-6.18.3-generic` with `spacemit-hmp`)

The SpacemiT kernel includes a custom HMP scheduler hook declared in `/usr/src/linux-headers-6.18.3-generic/include/linux/soc/spacemit/spacemit-hmp.h`:

```c
typedef enum {
    /* regular thread is the default type, should be 0 */
    HMP_REGULAR = 0,
    HMP_AI = 1,
} hmp_type_e;

void hmp_cpumask_init(void);
bool hmp_set_default_cpumask(struct task_struct *p);
bool hmp_cpu_can_offline(unsigned int cpu);
int hmp_cpu_affinity_restrict(struct task_struct *p, const struct cpumask *new_mask);
int hmp_set_ai_thread(pid_t pid);
int hmp_get_cpumask(struct cpumask *mask, hmp_type_e type);
int hmp_map_ai_to_regular(struct cpumask *mask);
```

- **Default Cpumask (`0x00ff`)**: Every newly spawned thread starts as `HMP_REGULAR` (`0`) with `Cpus_allowed_list: 0-7` (`cpu0–7`, the 8 X100 cores).
- **Affinity Restriction (`EINVAL`)**: `hmp_cpu_affinity_restrict()` intercepts `sched_setaffinity()` (and `taskset`) for `HMP_REGULAR` threads and returns **`-EINVAL`** if `new_mask` attempts to include `cpu8–15`.
- **Promoting Threads to `HMP_AI`**: When `SpaceMITExecutionProvider` (`libspacemit_ep.so` $\\rightarrow$ `spacemit-runtime` $\\rightarrow$ `/dev/tcm`) initializes its worker threads, the `/dev/tcm` driver calls the exported kernel symbol `hmp_set_ai_thread(pid_t)`, switching those worker threads to `HMP_AI` (`1`) and binding them onto `cpu8–15` (the A100 cores).

### 3.2 Vanilla Linux Kernel (without `spacemit-hmp`)

On a vanilla kernel lacking the `spacemit-hmp` patch:

- All 16 cores are in the default `Cpus_allowed_list: 0-15` (`0xffff`).
- Crucially, `/sys/devices/system/cpu/cpu*/cpu_capacity` reports **`1024` for all 16 cores** (both X100 and A100).
- Without explicit `sched_setaffinity()` calls from user space:
  1. The Linux scheduler treats `cpu8–15` (1.80 GHz, 32 KiB L1, 1 MiB L2) as identical in capacity to `cpu0–7` (2.15 GHz, 64 KiB L1, 4 MiB L2) and will schedule general-purpose threads onto the slower A100 cores.
  1. Multi-threaded workloads of $\\le 4$ threads will be scattered across all 4 clusters instead of staying within a single 4 MiB L2 (X100) or 1 MiB L2 + 1.5 MiB TCM (A100) cluster.

______________________________________________________________________

## 4. Thread Containment Rules for Multi-Threaded Applications

1. **4-Thread Workloads Must Be Contained Within One 4-Core Cluster**:
   - **X100**: Pin to **`cpu0–3` (`0x000f`)** or **`cpu4–7` (`0x00f0`)** so all 4 threads share a single **4 MiB L2** cache.
   - **A100**: Pin to **`cpu8–11` (`0x0f00`, EP `"0;1;2;3"`)** or **`cpu12–15` (`0xf000`, EP `"4;5;6;7"`)** so all 4 threads share a single **1 MiB L2** and the same **1.5 MiB TCM** physical address range (`0x00000000` or `0x02000000`).
1. **2-Thread Workloads on A100 Must Be Contained Within an Even-Odd 2-Core TCM Pair**:
   - Pin to **`cpu8,9` (`0x0300`, EP `"0;1"`)**, **`cpu10,11` (`0x0c00`, EP `"2;3"`)**, **`cpu12,13` (`0x3000`, EP `"4;5"`)**, or **`cpu14,15` (`0xc000`, EP `"6;7"`)** so both threads share the exact same `768 KiB` (`2 × 384 KiB`) TCM block pair.
   - Never pin a 2-thread workload across an odd-even boundary such as `cpu9,10` (EP `"1;2"`) or `cpu11,12` (EP `"3;4"`).
1. **3-Thread Workloads**:
   - **X100**: Pin to `cpu0–2` (`0x0007`) or `cpu4–6` (`0x0070`) inside one 4 MiB L2 cluster.
   - **A100**: Pin to `cpu8–10` (`0x0700`, EP `"0;1;2"`) or `cpu12–14` (`0x7000`, EP `"4;5;6"`) inside one A100 cluster.
1. **Concurrent Multi-Model Pipelines**:
   - Partition concurrent sessions onto non-overlapping clusters or 2-core pairs so the sum of active A100 threads across all `Ort::Session` instances is $\\le 8$:
     - **2× 4-thread models**: Session A $\\rightarrow$ `"0;1;2;3"` (`cpu8–11`), Session B $\\rightarrow$ `"4;5;6;7"` (`cpu12–15`).
     - **1× 4-thread + 2× 2-thread models**: Session A $\\rightarrow$ `"0;1;2;3"` (`cpu8–11`), Session B $\\rightarrow$ `"4;5"` (`cpu12,13`), Session C $\\rightarrow$ `"6;7"` (`cpu14,15`).
     - **1× 6-thread + 1× 2-thread models**: Session A $\\rightarrow$ `"0;1;2;3;4;5"` (`cpu8–13`), Session B $\\rightarrow$ `"6;7"` (`cpu14,15`).
