#!/usr/bin/env bash
# scripts/k3-runner.sh: Cargo target runner for SpacemiT K3 (pey-wail-deu)
#
# Automatically invoked by Cargo/cross when running tests or executables:
#   cargo test --target riscv64gc-unknown-linux-gnu
#
# Best practice: Uses the high-speed NVMe storage on ~/repository to avoid
# wearing out eMMC/SD storage and to maximize I/O throughput.

set -euo pipefail

TARGET_HOST="${K3_HOST:-pey-wail-deu}"
REMOTE_NVME_DIR="${K3_NVME_DIR:-/home/lma1980/repository/model-runner/target/remote-run}"

BINARY_PATH="$1"
BINARY_NAME="$(basename "$BINARY_PATH")"
REMOTE_BINARY="${REMOTE_NVME_DIR}/${BINARY_NAME}"

# Shift off binary path so remaining arguments (flags, test filters) are preserved
shift

# If invoked under cargo-miri, delegate directly to the Miri runner
if [[ -n "${MIRI_SYSROOT:-}" || -n "${MIRI:-}" || "${RUSTC_WRAPPER:-}" == *"cargo-miri"* ]]; then
  CARGO_MIRI_BIN="${RUSTC_WRAPPER:-cargo-miri}"
  exec "${CARGO_MIRI_BIN}" runner "${BINARY_PATH}" "$@"
fi

# If running natively on pey-wail-deu itself, execute directly without SSH
CURRENT_HOST="$(hostname 2>/dev/null || true)"
if [[ "${CURRENT_HOST}" == "pey-wail-deu" || "${CURRENT_HOST}" == "${TARGET_HOST}" ]]; then
  exec "${BINARY_PATH}" "$@"
fi

# Format remaining arguments safely for remote execution
REMOTE_ARGS=""
for arg in "$@"; do
  REMOTE_ARGS+=" $(printf %q "$arg")"
done

# 1. Ensure remote NVMe execution directory exists
ssh "${TARGET_HOST}" "mkdir -p ${REMOTE_NVME_DIR}"

# 2. Transfer the cross-compiled RISC-V binary to NVMe storage
scp -q "${BINARY_PATH}" "${TARGET_HOST}:${REMOTE_BINARY}"

# 3. Execute on native SpacemiT K3 silicon with forwarded arguments and clean up
ssh "${TARGET_HOST}" "chmod +x ${REMOTE_BINARY} && ${REMOTE_BINARY}${REMOTE_ARGS}; STATUS=\$?; rm -f ${REMOTE_BINARY}; exit \$STATUS"
