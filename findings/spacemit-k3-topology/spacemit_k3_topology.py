"""
SPDX-License-Identifier: Apache-2.0

SpacemiT K3 SoC Topology, TCM Tiling & Thread Containment Helper (Python 3)

Captures the 4-cluster (2x4 X100 + 2x4 A100) cache/TCM hierarchy and
vendor `spacemit-hmp` vs vanilla Linux kernel scheduling rules.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

K3_MVENDORID = 0x710
K3_MARCHID_X100 = 0x8000000058000002
K3_MIMPID_X100 = 0x33D8A600
K3_MARCHID_A100 = 0x8000000041000002
K3_MIMPID_A100 = 0x10000000D5686200

# 16-bit logical CPU masks
K3_MASK_ALL_X100 = 0x00FF
K3_MASK_ALL_A100 = 0xFF00

# 4-core Cluster tuples & masks
K3_X100_CLUSTERS: tuple[tuple[int, ...], ...] = ((0, 1, 2, 3), (4, 5, 6, 7))
K3_A100_CLUSTERS: tuple[tuple[int, ...], ...] = ((8, 9, 10, 11), (12, 13, 14, 15))

# 2-core A100 TCM pairs (each pair shares 2x 384 KiB = 768 KiB TCM)
K3_A100_TCM_PAIRS: tuple[tuple[int, int], ...] = ((8, 9), (10, 11), (12, 13), (14, 15))

K3_TCM_BLOCK_BYTES = 393216      # 384 KiB (0x60000)
K3_TCM_PAIR_BYTES = 786432       # 768 KiB per 2-core A100 pair
K3_TCM_CLUSTER_BYTES = 1572864   # 1.5 MiB per 4-core A100 cluster
K3_TCM_TOTAL_BYTES = 3145728     # 3.0 MiB total


def detect_core_type(cpu: int) -> Optional[str]:
    """Returns 'A100' or 'X100' for a logical CPU on SpacemiT K3, or None if not on K3."""
    base = Path(f"/sys/devices/system/cpu/cpu{cpu}/of_node")
    if (base / "cpu-ai").exists():
        return "A100"
    compat_file = base / "compatible"
    if compat_file.exists():
        compat = compat_file.read_bytes().decode("utf-8", errors="ignore")
        if "spacemit,a100" in compat:
            return "A100"
        if "spacemit,x100" in compat:
            return "X100"
    return None


def is_vendor_hmp_active() -> bool:
    """
    Returns True if the SpacemiT vendor kernel `spacemit-hmp` isolation is active
    (regular processes restricted to X100 cores 0..7; `sched_setaffinity` to 8..15 raises EINVAL).
    """
    if detect_core_type(8) != "A100":
        return False
    try:
        orig = os.sched_getaffinity(0)
        try:
            os.sched_setaffinity(0, {8})
        except OSError:
            return True
        finally:
            os.sched_setaffinity(0, orig)
    except OSError:
        pass
    return False


def select_x100_cpus(num_threads: int, slot: int = 0) -> list[int]:
    """
    Selects X100 general-purpose cores for `num_threads` (1..8), keeping <= 4 threads
    inside a single 4-core 4 MiB L2 cluster (`slot % 2`).
    """
    n = max(1, min(num_threads, 8))
    if n <= 4:
        return list(K3_X100_CLUSTERS[slot % 2][:n])
    return list(range(n))


def select_a100_cpus_and_ep_affinity(num_threads: int, slot: int = 0) -> tuple[list[int], str]:
    """
    Selects A100 AI cores and the `SPACEMIT_EP_INTRA_THREAD_AFFINITY` string for `num_threads` (1..8),
    containing 2 threads inside a 768 KiB TCM core-pair and <= 4 threads inside a 1.5 MiB TCM cluster.
    """
    n = max(1, min(num_threads, 8))
    if n == 1:
        cpu = 8 + (slot % 8)
        return [cpu], str(cpu - 8)
    if n == 2:
        pair = K3_A100_TCM_PAIRS[slot % 4]
        return list(pair), ";".join(str(c - 8) for c in pair)
    if n <= 4:
        cluster = K3_A100_CLUSTERS[slot % 2][:n]
        return list(cluster), ";".join(str(c - 8) for c in cluster)
    if n == 6:
        cpus = list(range(8, 14)) if (slot % 2 == 0) else list(range(10, 16))
        return cpus, ";".join(str(c - 8) for c in cpus)
    cpus = list(range(8, 8 + n))
    return cpus, ";".join(str(c - 8) for c in cpus)


def format_cpu_list(cpus: list[int]) -> str:
    """Formats a list of CPU indices into a Linux CPU list string (e.g. '0-3' or '8,9')."""
    if not cpus:
        return ""
    s = sorted(set(cpus))
    if len(s) > 2 and s[-1] - s[0] == len(s) - 1:
        return f"{s[0]}-{s[-1]}"
    return ",".join(str(c) for c in s)
