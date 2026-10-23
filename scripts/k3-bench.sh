#!/usr/bin/env bash
# scripts/k3-bench.sh: Remote benchmark orchestrator for SpacemiT K3 (pey-wail-deu)
#
# Usage:
#   ./scripts/k3-bench.sh [--cores x100|a100|all] [--toolchain system|llvm-24|gcc-17] [bench-args...]
#
# Examples:
#   ./scripts/k3-bench.sh --cores x100
#   ./scripts/k3-bench.sh --cores x100 --toolchain llvm-24
#   ./scripts/k3-bench.sh --cores a100

set -euo pipefail

TARGET_HOST="${K3_HOST:-pey-wail-deu}"
REMOTE_REPO="/home/lma1980/repository/model-runner"
CORES="x100"      # Default: high-performance X100 cores 0-7 (2.15 GHz)
TOOLCHAIN="system"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cores)
      CORES="$2"
      shift 2
      ;;
    --toolchain)
      TOOLCHAIN="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Core affinity mapping per SpacemiT K3 SoC topology:
# - SpacemiT X100 cluster: Cores 0-7 (614 - 2150 MHz, high-perf)
# - SpacemiT A100 cluster: Cores 8-15 (614 - 1800 MHz)
case "${CORES}" in
  x100)
    TASKSET_MASK="0-7"
    ;;
  a100)
    TASKSET_MASK="8-15"
    ;;
  all)
    TASKSET_MASK="0-15"
    ;;
  *)
    TASKSET_MASK="${CORES}"
    ;;
esac

# Toolchain environment setup
TOOLCHAIN_ENV=""
case "${TOOLCHAIN}" in
  llvm-24)
    TOOLCHAIN_ENV="export PATH=/home/lma1980/opt/llvm-24/bin:\$PATH; export CC=clang; export CXX=clang++; "
    ;;
  gcc-17)
    TOOLCHAIN_ENV="export PATH=/home/lma1980/opt/gcc-17/bin:\$PATH; export CC=gcc; export CXX=g++; "
    ;;
  gcc-17-x100)
    TOOLCHAIN_ENV="export PATH=/home/lma1980/opt/gcc-17-spacemit-x100/bin:\$PATH; export CC=gcc; export CXX=g++; "
    ;;
  system)
    TOOLCHAIN_ENV=""
    ;;
  *)
    echo "Unknown toolchain '${TOOLCHAIN}'. Choose from: system, llvm-24, gcc-17, gcc-17-x100"
    exit 1
    ;;
esac

echo "=========================================================="
echo " [K3 Remote Benchmark] Host: ${TARGET_HOST}"
echo " [K3 Remote Benchmark] Cores: ${CORES} (taskset -c ${TASKSET_MASK})"
echo " [K3 Remote Benchmark] Toolchain: ${TOOLCHAIN}"
echo " [K3 Remote Benchmark] Working Dir (NVMe): ${REMOTE_REPO}"
echo "=========================================================="

REMOTE_CMD="cd ${REMOTE_REPO}/code && ${TOOLCHAIN_ENV} taskset -c ${TASKSET_MASK} cargo bench ${EXTRA_ARGS[*]:-}"

ssh -t "${TARGET_HOST}" "${REMOTE_CMD}"
