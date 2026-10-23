# K3 Workspace Agent Guidelines

## 1. Safe Recovery & State Verification (Verify First)

- **Diagnose Before Remediating**: When a command, script, or external process fails, times out (e.g., authentication prompts, 1Password, network), or when the user requests a "restart" or "retry":
  - **Never** perform blind destructive cleanup (e.g., `rm -rf`, `git reset --hard`, `git clean -fd`, or deleting newly created remotes/directories).
  - **Always verify current state first**: Check `git status`, verify local directory contents, and check external status (e.g., `gh repo view`) to determine what succeeded and what failed.
  - Formulate targeted, non-destructive recovery steps that build upon already-completed work.

## 2. Remote Repositories & Submodules

- **Public Visibility Default**: All companion repositories and git submodules created under the `LMA1980` organization / user for the K3 platform must default to **public** visibility (`gh repo create --public`), unless explicitly instructed otherwise by the user.
- **SSH Auth Awareness**: When running Git commands requiring interactive SSH authentication (such as SSH keys backed by 1Password or agent prompts), check or notify the user before running if timeouts or prompt denials occur.

## 3. Multi-Host Synchronization & SSH Authentication (SpacemiT K3)

- **Git-Only Synchronization (No rsync)**: Always use Git to synchronize code across multiple hosts and target hardware (`pey-wail-deu`). Do NOT use `rsync`.
  - If changes should not be pushed to `main`, create and push to a dedicated task or feature branch (e.g. `feat/...` or `test/...`), then fetch and check out that branch on the target board.
- **Patient SSH Authentication**: Remote execution on `pey-wail-deu` requires interactive 1Password Touch ID approval on macOS.
  - Waiting for user approval is expected and acceptable. Agents must wait patiently for the user to confirm biometric prompts and never treat approval latency as an error or dead state.
  - Where possible, pre-validate compilation locally (`cargo check --target riscv64gc-unknown-linux-gnu --workspace --tests`) before dispatching runs to target hardware.

## 4. Embedded Target Resource Constraints (RLIMIT_MEMLOCK)

- **Bounded Memlock Ceiling (Never 'unlimited')**: Setting `RLIMIT_MEMLOCK` to `unlimited` risks system-wide hard lockups if 100% of physical RAM is locked, preventing kernel slab allocation, page table creation, and SSH daemon response.
  - For model execution on the target board, configure a bounded limit reserving a safe headroom for kernel/OS services (e.g. on headless `pey-wail-deu` with 32 GB RAM, `29360128 KB` / 28 GiB is allocated in `/etc/security/limits.d/99-modelrunner.conf`, preserving ~3.3 GiB strictly for the headless Linux kernel and services).
  - Diagnostic utilities (`k3-diag`) and default integration test harnesses must still use conservative context bounds (e.g. `n_ctx: 64`, requiring ~64 KB KV cache) so tests run cleanly out-of-the-box in unprivileged environments without admission refusal (`InsufficientLockableMemory`, exit code 11).
  - Tokenizers must provide fallback token handling (e.g. `padding_token_id` or byte fallback) to prevent fatal `CapabilityMismatch` aborts when arbitrary prompts are supplied in automated tests.

## 5. Subagent Swarm Governance

- **Avoid Swarm Bloat**: Do not allow multi-agent systems to spawn recursive reviewer/challenger/auditor swarms that stall on external or remote dependencies.
- For single user stories and feature implementations, prefer focused, single-implementer or small-team workflows with programmatic test suites over bureaucratic multi-agent gate cycles.
