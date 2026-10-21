#!/usr/bin/env bash
# scripts/k3-sync.sh: Update SpacemiT K3 target repository via Git and submodules
#
# Usage:
#   ./scripts/k3-sync.sh [-y|--yes|--force]
#
# Description:
#   Checks for local pending changes (uncommitted modifications, staged changes,
#   uncommitted submodule changes, or unpushed commits) and prompts before continuing.
#   On the remote target host, updates the workspace using git pull and git submodule.

set -euo pipefail

TARGET_HOST="${K3_HOST:-pey-wail-deu}"
REMOTE_REPO="${K3_REMOTE_REPO:-/home/lma1980/repository/model-runner}"
FORCE_CONTINUE=false

usage() {
  cat <<EOF
Usage: $0 [options]

Updates the remote K3 repository on \${TARGET_HOST}:\${REMOTE_REPO} using
'git pull' and 'git submodule update'.

Options:
  -y, --yes, --force   Continue automatically without prompting if local pending changes exist
  -h, --help           Show this help message

Environment variables:
  K3_HOST              Target SSH host (default: pey-wail-deu)
  K3_REMOTE_REPO       Remote repository path (default: /home/lma1980/repository/model-runner)
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes|--force|-f)
      FORCE_CONTINUE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Ensure we are inside a Git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Current directory is not a Git repository." >&2
  exit 1
fi

# 1. Check for local pending changes in parent repository and submodules
local_dirty=$(git status --porcelain)
submodule_dirty=$(git submodule foreach --quiet 'status=$(git status --porcelain); if [[ -n "$status" ]]; then echo "$sm_path"; fi')

unpushed_count=0
if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
  unpushed_count=$(git rev-list @{u}..HEAD --count 2>/dev/null || echo 0)
fi

submodule_unpushed=$(git submodule foreach --quiet 'if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then c=$(git rev-list @{u}..HEAD --count 2>/dev/null || echo 0); if [[ "$c" -gt 0 ]]; then echo "$sm_path ($c commits ahead)"; fi; fi')

has_pending_changes=false
if [[ -n "$local_dirty" || -n "$submodule_dirty" || "$unpushed_count" -gt 0 || -n "$submodule_unpushed" ]]; then
  has_pending_changes=true
fi

# 2. Prompt user if local pending changes are detected
if [[ "$has_pending_changes" = true ]]; then
  echo "=========================================================="
  echo " [k3-sync] WARNING: Local pending changes detected"
  echo "=========================================================="
  if [[ -n "$local_dirty" ]]; then
    echo "Working tree changes (uncommitted/untracked):"
    echo "$local_dirty" | sed 's/^/  /'
    echo ""
  fi
  if [[ -n "$submodule_dirty" ]]; then
    echo "Submodules with uncommitted changes:"
    echo "$submodule_dirty" | sed 's/^/  /'
    echo ""
  fi
  if [[ "$unpushed_count" -gt 0 ]]; then
    echo "Local unpushed commits in parent repository ($unpushed_count):"
    git log -n 5 --oneline @{u}..HEAD | sed 's/^/  /'
    echo ""
  fi
  if [[ -n "$submodule_unpushed" ]]; then
    echo "Submodules with unpushed commits:"
    echo "$submodule_unpushed" | sed 's/^/  /'
    echo ""
  fi
  echo "Notice: Target host (${TARGET_HOST}) updates from Git remotes via 'git pull' and 'git submodule'."
  echo "Any local uncommitted or unpushed changes will NOT be reflected on the target host."
  echo "=========================================================="

  if [[ "$FORCE_CONTINUE" = true ]]; then
    echo "Flag --yes/--force specified: continuing and ignoring local changes."
  else
    prompt_input=""
    if [[ -t 0 ]]; then
      read -r -p "Cancel execution or continue ignoring local changes? [c=cancel / y=continue] (default: c): " prompt_input
    elif read -r prompt_input; then
      # Read line from piped or redirected stdin
      :
    elif [[ -r /dev/tty && -t 1 ]]; then
      read -r -p "Cancel execution or continue ignoring local changes? [c=cancel / y=continue] (default: c): " prompt_input < /dev/tty
    else
      echo "Notice: Non-interactive session without input. Defaulting to cancel." >&2
      prompt_input="c"
    fi

    case "${prompt_input}" in
      [yY]|[yY][eE][sS]|continue|CONTINUE)
        echo "Continuing: local changes will be ignored."
        ;;
      *)
        echo "Execution cancelled by user."
        exit 0
        ;;
    esac
  fi
else
  echo "Local workspace is clean (no uncommitted or unpushed changes)."
fi

# 3. Synchronize TARGET_HOST via git pull and git submodule
echo "Updating remote repository on ${TARGET_HOST}:${REMOTE_REPO} via Git..."

REMOTE_CMD="cd ${REMOTE_REPO} && git pull && git submodule sync --recursive && git submodule update --init --recursive && git submodule status"

CURRENT_HOST="$(hostname 2>/dev/null || true)"
if [[ "${CURRENT_HOST}" == "pey-wail-deu" || "${CURRENT_HOST}" == "${TARGET_HOST}" ]]; then
  eval "${REMOTE_CMD}"
else
  ssh "${TARGET_HOST}" "${REMOTE_CMD}"
fi

echo "Sync complete: ${TARGET_HOST}:${REMOTE_REPO} is up to date."
