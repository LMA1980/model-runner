# K3 Workspace Agent Guidelines

## 1. Safe Recovery & State Verification (Verify First)

- **Diagnose Before Remediating**: When a command, script, or external process fails, times out (e.g., authentication prompts, 1Password, network), or when the user requests a "restart" or "retry":
  - **Never** perform blind destructive cleanup (e.g., `rm -rf`, `git reset --hard`, `git clean -fd`, or deleting newly created remotes/directories).
  - **Always verify current state first**: Check `git status`, verify local directory contents, and check external status (e.g., `gh repo view`) to determine what succeeded and what failed.
  - Formulate targeted, non-destructive recovery steps that build upon already-completed work.

## 2. Remote Repositories & Submodules

- **Public Visibility Default**: All companion repositories and git submodules created under the `LMA1980` organization / user for the K3 platform must default to **public** visibility (`gh repo create --public`), unless explicitly instructed otherwise by the user.
- **SSH Auth Awareness**: When running Git commands requiring interactive SSH authentication (such as SSH keys backed by 1Password or agent prompts), check or notify the user before running if timeouts or prompt denials occur.
