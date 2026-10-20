#!/usr/bin/env bash
# scripts/k3-sync.sh: Sync workspace from local Mac to SpacemiT K3 NVMe storage
#
# Usage:
#   ./scripts/k3-sync.sh [--dry-run]

set -euo pipefail

TARGET_HOST="${K3_HOST:-pey-wail-deu}"
REMOTE_REPO="/home/lma1980/repository/model-runner"

echo "Syncing model-runner to ${TARGET_HOST}:${REMOTE_REPO} on NVMe..."

rsync -avz \
  --delete \
  --exclude 'target' \
  --exclude '.git' \
  --exclude '.cargo-ok' \
  "$@" \
  ./ "${TARGET_HOST}:${REMOTE_REPO}/"

echo "Sync complete."
