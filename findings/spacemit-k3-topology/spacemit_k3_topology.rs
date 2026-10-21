//! SPDX-License-Identifier: Apache-2.0
//!
//! SpacemiT K3 SoC Topology, TCM Tiling & Thread Containment Helper (Rust)
//!
//! Captures the 4-cluster (2x4 X100 + 2x4 A100) cache/TCM hierarchy and
//! vendor `spacemit-hmp` vs vanilla Linux kernel scheduling rules.

use std::fs;
use std::path::Path;

pub const K3_MVENDORID: u32 = 0x710;
pub const K3_MARCHID_X100: u64 = 0x8000_0000_5800_0002;
pub const K3_MIMPID_X100: u64 = 0x33d8_a600;
pub const K3_MARCHID_A100: u64 = 0x8000_0000_4100_0002;
pub const K3_MIMPID_A100: u64 = 0x1000_0000_d568_6200;

pub const K3_MASK_ALL_X100: u16 = 0x00ff;
pub const K3_MASK_ALL_A100: u16 = 0xff00;

pub const K3_MASK_X100_CLUSTER0: u16 = 0x000f; // cpu 0..3   (4 MiB L2)
pub const K3_MASK_X100_CLUSTER1: u16 = 0x00f0; // cpu 4..7   (4 MiB L2)
pub const K3_MASK_A100_CLUSTER2: u16 = 0x0f00; // cpu 8..11  (1 MiB L2 + 1.5 MiB TCM @ 0x0)
pub const K3_MASK_A100_CLUSTER3: u16 = 0xf000; // cpu 12..15 (1 MiB L2 + 1.5 MiB TCM @ 0x2000000)

pub const K3_MASK_A100_PAIR0: u16 = 0x0300; // cpu 8,9    (768 KiB TCM) -> EP "0;1"
pub const K3_MASK_A100_PAIR1: u16 = 0x0c00; // cpu 10,11  (768 KiB TCM) -> EP "2;3"
pub const K3_MASK_A100_PAIR2: u16 = 0x3000; // cpu 12,13  (768 KiB TCM) -> EP "4;5"
pub const K3_MASK_A100_PAIR3: u16 = 0xc000; // cpu 14,15  (768 KiB TCM) -> EP "6;7"

pub const K3_X100_CLUSTERS: [[usize; 4]; 2] = [[0, 1, 2, 3], [4, 5, 6, 7]];
pub const K3_A100_CLUSTERS: [[usize; 4]; 2] = [[8, 9, 10, 11], [12, 13, 14, 15]];
pub const K3_A100_TCM_PAIRS: [[usize; 2]; 4] = [[8, 9], [10, 11], [12, 13], [14, 15]];

pub const K3_TCM_BLOCK_BYTES: usize = 393_216; // 384 KiB (0x60000)
pub const K3_TCM_PAIR_BYTES: usize = 786_432; // 768 KiB (2 blocks per 2-core pair)
pub const K3_TCM_CLUSTER_BYTES: usize = 1_572_864; // 1.5 MiB (4 blocks per 4-core A100 cluster)
pub const K3_TCM_TOTAL_BYTES: usize = 3_145_728; // 3.0 MiB (8 blocks total)

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum K3CoreType {
    X100,
    A100,
}

/// Checks Device Tree (`of_node/cpu-ai` or `of_node/compatible`) to determine if `cpu` is A100.
pub fn detect_core_type(cpu: usize) -> Option<K3CoreType> {
    let ai_prop = format!("/sys/devices/system/cpu/cpu{cpu}/of_node/cpu-ai");
    if Path::new(&ai_prop).exists() {
        return Some(K3CoreType::A100);
    }
    let compat_path = format!("/sys/devices/system/cpu/cpu{cpu}/of_node/compatible");
    if let Ok(bytes) = fs::read(&compat_path) {
        let s = String::from_utf8_lossy(&bytes);
        if s.contains("spacemit,a100") {
            return Some(K3CoreType::A100);
        }
        if s.contains("spacemit,x100") {
            return Some(K3CoreType::X100);
        }
    }
    None
}

/// Detects whether SpacemiT's `spacemit-hmp` kernel isolation is active by checking if
/// `/proc/self/status` restricts `Cpus_allowed_list` to `0-7` while `cpu8` is an A100 core.
pub fn is_vendor_hmp_active() -> bool {
    if detect_core_type(8) != Some(K3CoreType::A100) {
        return false;
    }
    if let Ok(status) = fs::read_to_string("/proc/self/status") {
        for line in status.lines() {
            if let Some(rest) = line.strip_prefix("Cpus_allowed_list:") {
                return rest.trim() == "0-7";
            }
        }
    }
    false
}

/// Selects X100 cores for `num_threads` (1..=8), containing <= 4 threads within a single
/// 4-core 4 MiB L2 cluster (`slot % 2`).
pub fn select_x100_cpus(num_threads: usize, slot: usize) -> Vec<usize> {
    let n = num_threads.clamp(1, 8);
    if n <= 4 {
        K3_X100_CLUSTERS[slot % 2][..n].to_vec()
    } else {
        (0..n).collect()
    }
}

/// Selects A100 cores and the corresponding `SPACEMIT_EP_INTRA_THREAD_AFFINITY` string,
/// containing 2 threads inside a 768 KiB TCM core-pair and <= 4 threads inside a 1.5 MiB TCM cluster.
pub fn select_a100_cpus_and_ep_affinity(
    num_threads: usize,
    slot: usize,
) -> (Vec<usize>, &'static str) {
    match num_threads {
        0 | 1 => {
            const EP: [&str; 8] = ["0", "1", "2", "3", "4", "5", "6", "7"];
            let idx = slot % 8;
            (vec![8 + idx], EP[idx])
        }
        2 => {
            const EP: [&str; 4] = ["0;1", "2;3", "4;5", "6;7"];
            let idx = slot % 4;
            (K3_A100_TCM_PAIRS[idx].to_vec(), EP[idx])
        }
        3 => {
            if slot % 2 == 0 {
                (vec![8, 9, 10], "0;1;2")
            } else {
                (vec![12, 13, 14], "4;5;6")
            }
        }
        4 => {
            if slot % 2 == 0 {
                (K3_A100_CLUSTERS[0].to_vec(), "0;1;2;3")
            } else {
                (K3_A100_CLUSTERS[1].to_vec(), "4;5;6;7")
            }
        }
        6 => {
            if slot % 2 == 0 {
                ((8..14).collect(), "0;1;2;3;4;5")
            } else {
                ((10..16).collect(), "2;3;4;5;6;7")
            }
        }
        _ => ((8..16).collect(), "0;1;2;3;4;5;6;7"),
    }
}
