/*
 * SPDX-License-Identifier: Apache-2.0
 *
 * SpacemiT K3 SoC Topology, TCM Tiling & Thread Containment Helper (C99 / C++17)
 *
 * Captures the 4-cluster (2x4 X100 + 2x4 A100) cache/TCM hierarchy and
 * vendor `spacemit-hmp` vs vanilla Linux kernel scheduling rules.
 */

#ifndef SPACEMIT_K3_TOPOLOGY_H
#define SPACEMIT_K3_TOPOLOGY_H

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>

#if defined(__linux__)
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <sched.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * 1. Hardware Signatures & Topology Constants
 * ============================================================================ */

#define K3_MVENDORID             0x710U
#define K3_MARCHID_X100          0x8000000058000002ULL
#define K3_MIMP_ID_X100          0x33D8A600ULL
#define K3_MARCHID_A100          0x8000000041000002ULL
#define K3_MIMP_ID_A100          0x10000000D5686200ULL

#define K3_TOTAL_CORES           16U
#define K3_X100_CORE_START       0U
#define K3_X100_CORE_COUNT       8U
#define K3_A100_CORE_START       8U
#define K3_A100_CORE_COUNT       8U

/* Cache & TCM sizes in bytes */
#define K3_X100_L1_BYTES         (64U * 1024U)
#define K3_X100_CLUSTER_L2_BYTES (4096U * 1024U) /* 4 MiB per 4-core X100 cluster */
#define K3_A100_L1_BYTES         (32U * 1024U)
#define K3_A100_CLUSTER_L2_BYTES (1024U * 1024U) /* 1 MiB per 4-core A100 cluster */

#define K3_TCM_BLOCK_BYTES       393216U         /* 0x60000 (384 KiB) per block */
#define K3_TCM_PAIR_BYTES        786432U         /* 2 blocks (768 KiB) per 2-core A100 pair */
#define K3_TCM_CLUSTER_BYTES     1572864U        /* 4 blocks (1.5 MiB) per 4-core A100 cluster */
#define K3_TCM_TOTAL_BYTES       3145728U        /* 8 blocks (3.0 MiB) total */

#define K3_TCM_CLUSTER2_PHYS     0x00000000ULL   /* Coupled to cpu 8..11 */
#define K3_TCM_CLUSTER3_PHYS     0x02000000ULL   /* Coupled to cpu 12..15 */

/* ============================================================================
 * 2. CPU Bitmasks (16-bit logical CPU masks)
 * ============================================================================ */

/* Global core-type masks */
#define K3_MASK_ALL_X100         0x00FFU /* cpu 0..7   */
#define K3_MASK_ALL_A100         0xFF00U /* cpu 8..15  */
#define K3_MASK_ALL_CORES        0xFFFFU /* cpu 0..15  */

/* 4-core Cluster masks (contain <= 4 threads inside a single cluster) */
#define K3_MASK_X100_CLUSTER0    0x000FU /* cpu 0..3   (4 MiB L2) */
#define K3_MASK_X100_CLUSTER1    0x00F0U /* cpu 4..7   (4 MiB L2) */
#define K3_MASK_A100_CLUSTER2    0x0F00U /* cpu 8..11  (1 MiB L2 + 1.5 MiB TCM @ 0x0) */
#define K3_MASK_A100_CLUSTER3    0xF000U /* cpu 12..15 (1 MiB L2 + 1.5 MiB TCM @ 0x2000000) */

/* 2-core A100 TCM-Pair masks (each even-odd pair shares 2x 384 KiB = 768 KiB TCM) */
#define K3_MASK_A100_PAIR0       0x0300U /* cpu 8,9    -> EP "0;1" */
#define K3_MASK_A100_PAIR1       0x0C00U /* cpu 10,11  -> EP "2;3" */
#define K3_MASK_A100_PAIR2       0x3000U /* cpu 12,13  -> EP "4;5" */
#define K3_MASK_A100_PAIR3       0xC000U /* cpu 14,15  -> EP "6;7" */

/* ============================================================================
 * 3. Runtime Topology & HMP Detection Helpers
 * ============================================================================ */

/**
 * Returns 1 if logical `cpu` (0..15) is marked with the `cpu-ai` property
 * in Device Tree (i.e. SpacemiT A100), or 0 otherwise.
 */
static inline int k3_cpu_is_a100_dt(unsigned int cpu) {
    char path[128];
    snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%u/of_node/cpu-ai", cpu);
    return access(path, F_OK) == 0 ? 1 : 0;
}

/**
 * Returns 1 if the running kernel has SpacemiT's `spacemit-hmp` isolation active
 * (where regular threads are restricted to X100 `0..7` and `sched_setaffinity`
 * to `8..15` returns EINVAL unless `hmp_set_ai_thread` was called by `/dev/tcm`).
 */
static inline int k3_is_vendor_hmp_active(void) {
#if defined(__linux__)
    if (!k3_cpu_is_a100_dt(8)) {
        return 0;
    }
    cpu_set_t current_mask;
    CPU_ZERO(&current_mask);
    if (sched_getaffinity(0, sizeof(current_mask), &current_mask) != 0) {
        return 0;
    }
    /* Probe if setting affinity to cpu8 is rejected for the current regular thread */
    cpu_set_t probe_mask;
    CPU_ZERO(&probe_mask);
    CPU_SET(8, &probe_mask);
    if (sched_setaffinity(0, sizeof(probe_mask), &probe_mask) != 0) {
        return 1; /* Rejected with EINVAL -> spacemit-hmp is active */
    }
    /* Restore original affinity if the probe succeeded (vanilla kernel) */
    (void)sched_setaffinity(0, sizeof(current_mask), &current_mask);
#endif
    return 0;
}

/* ============================================================================
 * 4. Optimal Cluster / TCM-Pair Mask & EP Affinity Selectors
 * ============================================================================ */

/**
 * Returns an optimal 16-bit logical CPU bitmask for `num_threads` (1..8) on the
 * X100 general-purpose cores, keeping <= 4 threads inside a single 4 MiB L2 cluster.
 * `slot` (0 or 1) selects between Cluster 0 (cpu 0..3) and Cluster 1 (cpu 4..7).
 */
static inline uint16_t k3_select_x100_cpumask(unsigned int num_threads, unsigned int slot) {
    const unsigned int shift = (slot & 1U) ? 4U : 0U;
    switch (num_threads) {
        case 0:
        case 1: return (uint16_t)(0x0001U << shift);
        case 2: return (uint16_t)(0x0003U << shift);
        case 3: return (uint16_t)(0x0007U << shift);
        case 4: return (uint16_t)(0x000FU << shift);
        case 5: return 0x001FU;
        case 6: return 0x003FU;
        case 7: return 0x007FU;
        default: return K3_MASK_ALL_X100;
    }
}

/**
 * Returns an optimal 16-bit logical CPU bitmask for `num_threads` (1..8) on the
 * A100 AI cores, respecting 2-core TCM pairs (768 KiB) and 4-core clusters (1.5 MiB TCM + 1 MiB L2).
 */
static inline uint16_t k3_select_a100_cpumask(unsigned int num_threads, unsigned int slot) {
    if (num_threads <= 1U) {
        return (uint16_t)(1U << (8U + (slot % 8U)));
    }
    if (num_threads == 2U) {
        static const uint16_t kPairs[4] = {
            K3_MASK_A100_PAIR0, K3_MASK_A100_PAIR1,
            K3_MASK_A100_PAIR2, K3_MASK_A100_PAIR3
        };
        return kPairs[slot % 4U];
    }
    if (num_threads == 3U) {
        return (slot & 1U) ? 0x7000U : 0x0700U;
    }
    if (num_threads == 4U) {
        return (slot & 1U) ? K3_MASK_A100_CLUSTER3 : K3_MASK_A100_CLUSTER2;
    }
    if (num_threads == 6U) {
        return (slot & 1U) ? 0xFC00U : 0x3F00U;
    }
    return K3_MASK_ALL_A100;
}

/**
 * Returns the semicolon-separated `SPACEMIT_EP_INTRA_THREAD_AFFINITY` string
 * corresponding to `num_threads` and `slot`, keeping <= 2 threads inside one
 * 768 KiB TCM pair and <= 4 threads inside one 4-core A100 cluster.
 */
static inline const char* k3_select_a100_ep_affinity(unsigned int num_threads, unsigned int slot) {
    switch (num_threads) {
        case 1: {
            static const char* const kSingle[8] = {"0", "1", "2", "3", "4", "5", "6", "7"};
            return kSingle[slot % 8U];
        }
        case 2: {
            static const char* const kPairs[4] = {"0;1", "2;3", "4;5", "6;7"};
            return kPairs[slot % 4U];
        }
        case 3:
            return (slot & 1U) ? "4;5;6" : "0;1;2";
        case 4:
            return (slot & 1U) ? "4;5;6;7" : "0;1;2;3";
        case 6:
            return (slot & 1U) ? "2;3;4;5;6;7" : "0;1;2;3;4;5";
        case 8:
        default:
            return "0;1;2;3;4;5;6;7";
    }
}

#if defined(__linux__)
/**
 * Applies a 16-bit logical CPU bitmask to the calling thread/process via `sched_setaffinity`.
 * Returns 0 on success or -1 on error (setting errno).
 */
static inline int k3_apply_cpumask(uint16_t mask) {
    cpu_set_t set;
    CPU_ZERO(&set);
    for (unsigned int cpu = 0; cpu < K3_TOTAL_CORES; ++cpu) {
        if (mask & (1U << cpu)) {
            CPU_SET(cpu, &set);
        }
    }
    return sched_setaffinity(0, sizeof(set), &set);
}
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* SPACEMIT_K3_TOPOLOGY_H */
