# K3 Workspace Agent Guidelines

> [!IMPORTANT]
> **Scope of `AGENTS.md`**: This file is reserved strictly for **immediate, universal behavioral rules and hard invariants** that govern every agent interaction. Do NOT place occasional notes, component designs, framework preferences, or operational runbooks here; those belong in repository-specific documentation (`README.md`, `specs/`, or `docs/`).

## 1. Safe Recovery & State Verification (Verify First)

- **Diagnose Before Remediating**: When a command, script, or external process fails, times out (e.g., authentication prompts, 1Password, network), or when the user requests a "restart" or "retry":
  - **Never** perform blind destructive cleanup (e.g., `rm -rf`, `git reset --hard`, `git clean -fd`, or deleting newly created remotes/directories).
  - **Always verify current state first**: Check `git status`, verify local directory contents, and check external status (e.g., `gh repo view`) to determine what succeeded and what failed.
  - Formulate targeted, non-destructive recovery steps that build upon already-completed work.

## 2. Remote Repositories & Submodules

- **Public Visibility Default**: All companion repositories and git submodules created under the `LMA1980` organization / user for the K3 platform must default to **public** visibility (`gh repo create --public`), unless explicitly instructed otherwise by the user.
- **SSH Auth Awareness**: When running Git commands requiring interactive SSH authentication (such as SSH keys backed by 1Password or agent prompts), check or notify the user before running if timeouts or prompt denials occur.

## 3. Service Account Isolation & Daemon Deployment (`pey-wail-deu`)

- **Verify Toolchains Under Target Service Account**: When configuring or debugging services running under an isolated user (e.g., `action-runner` with `ProtectHome=read-only`), always verify tool availability directly as that user (`sudo -u action-runner ...`), including:
  - `RUSTUP_HOME` (`/var/lib/action-runner/.rustup` with `toolchains/`, `wasm32-unknown-unknown` target, and `nightly` with `miri` and `rust-src`)
  - `CARGO_HOME` subcommands (`cargo-audit`, `cargo-llvm-cov`, and `advisory-db`)
  - Python user site-packages in `/var/lib/action-runner/.local` (specifically `mdformat-gfm` for GFM table formatting)
  - SSH `known_hosts` and deploy key permissions in `/var/lib/action-runner/.ssh`
- **Directory Traversal Permissions**: Ensure parent configuration directories (such as `/etc/action-runner`) are owned by or traversable by the service account (`chown -R action-runner:action-runner /etc/action-runner && chmod 700 /etc/action-runner`), not `0700 root:root`.
- **Secret Path vs. Literal Value Resolution**: Environment variables that accept either a file path or a literal secret (e.g., `GITHUB_WEBHOOK_SECRET`) must read and trim the file when given a path, and fail closed (`None`) if the path cannot be read—never fall back to using the file path string itself as the secret token.
- **Atomic Binary Installation**: Use `sudo install -m 755 target/release/<bin> /usr/local/bin/<bin>` instead of `cp` when updating a running systemd service binary to avoid `Text file busy` (`ETXTBSY`) errors.

## 4. Multi-Host Synchronization & Branching (feat/\*\*)

- **Strict Commit Signing (`commit.gpgsign = true`)**: `commit.gpgsign` must **always** remain enabled (`true`). Agents must **never** attempt to disable, override, or bypass commit signing (`commit.gpgsign = false`, `--no-gpg-sign`, or modifying signing configuration is strictly forbidden under any circumstances).
- **Feature Branches & Pull Requests (`feat/**`)**: All ongoing changes intended for `main` must use `feat/**` branches (e.g. `feat/<feature-name>`) and be merged via Pull Requests. Never commit or push directly to the `main` branch.
  - **Mandatory Pull Request Submission (`gh pr create`)**: A task on a `feat/**` branch is **not complete** at `git push`. Before concluding any feature or user story (and as an explicit requirement in delegated `/teamwork-preview` or subagent prompts), agents **must** open the GitHub Pull Requests (`gh pr create`) for every modified git submodule (e.g., `code/core`, `code/engine`, `code/manager`) as well as the parent repository, and return the created PR URLs to the user.
- **Git-Only Synchronization (No rsync)**: Always use Git to synchronize code across multiple hosts and target hardware (`pey-wail-deu`). Do NOT use `rsync`.
  - When syncing changes to the target board, push the `feat/**` branch to GitHub, then fetch and check out that branch on the target board.
- **Patient SSH & Git Authentication**: Remote execution on `pey-wail-deu` and local Git commits require interactive 1Password Touch ID approval on macOS.
  - Waiting for user approval is expected and acceptable. Agents must wait patiently for the user to confirm biometric prompts and never treat approval latency as an error or dead state.
  - Where possible, pre-validate compilation locally (`cargo check --target riscv64gc-unknown-linux-gnu --workspace --tests`) before dispatching runs to target hardware.

## 5. Embedded Target Resource Constraints (RLIMIT_MEMLOCK)

- **Bounded Memlock Ceiling (Never 'unlimited')**: Setting `RLIMIT_MEMLOCK` to `unlimited` risks system-wide hard lockups if 100% of physical RAM is locked, preventing kernel slab allocation, page table creation, and SSH daemon response.
  - For model execution on the target board, configure a bounded limit reserving a safe headroom for kernel/OS services (e.g. on headless `pey-wail-deu` with 32 GB RAM, `29360128 KB` / 28 GiB is allocated in `/etc/security/limits.d/99-modelrunner.conf`, preserving ~3.3 GiB strictly for the headless Linux kernel and services).
  - Diagnostic utilities (`k3-diag`) and default integration test harnesses must still use conservative context bounds (e.g. `n_ctx: 64`, requiring ~64 KB KV cache) so tests run cleanly out-of-the-box in unprivileged environments without admission refusal (`InsufficientLockableMemory`, exit code 11).
  - Tokenizers must provide fallback token handling (e.g. `padding_token_id` or byte fallback) to prevent fatal `CapabilityMismatch` aborts when arbitrary prompts are supplied in automated tests.

## 6. SpacemiT K3 Hardware & Kernel Invariants (`pey-wail-deu`)

- **Canonical Cluster Mapping**:
  - **Cluster 0 (`X100`, cores `0–7`, mask `0x00FF`)**: Out-of-Order general-purpose cores (`2.15 GHz`), `VLEN = 256` (`vlenb = 32`). Does **not** support `XSMTVDotII` matrix instructions (executing `smt.vpack.vv` / `smt.vmadot` traps with `SIGILL`).
  - **Cluster 1 (`A100`, cores `8–15`, mask `0xFF00`)**: In-Order AI/Matrix cores (`1.80 GHz`), `VLEN = 1024` (`vlenb = 128`), supports `XSMTVDotII` (`smt.vpack.vv` `.word 0x6704102b` and `smt.vmadot` `.word 0xe304302b`, `8×16` `i8` × `8×16` `i8` → `8×8` `i32` in `v0:v1`).
- **Conditional `/proc/set_ai_thread` Registration (SpacemiT-Patched Kernel Only)**: On the SpacemiT-patched Linux kernel (`spacemit-hmp`), any worker thread or forked capability-probe process pinning to A100 cores (`8–15`) **must** write its kernel thread ID (`SYS_gettid`) to `/proc/set_ai_thread` before calling `sched_setaffinity`. A vanilla Linux kernel does **not** have `/proc/set_ai_thread` or require this step, so code must treat `/proc/set_ai_thread` as conditional (write only when the procfs node is present).

## 7. Subagent Effort Scaling & Delegation

- **Scale Effort to the Assigned Subagent Task**: Spawn as many subagents as needed for the workflow (including full `/teamwork-preview` pipelines), but scale each individual subagent's effort level and model tier (`Model` parameter in `invoke_subagent` and prompt directives) proportionally to the complexity of the specific task assigned to it:
  - **Low effort (`flash_lite` / `flash`)**: Simple, mechanical, or bounded tasks such as renaming files, formatting, boilerplate updates, or straightforward status checks.
  - **High effort (`pro` / `inherit`)**: Complex tasks such as refactoring the entire solution, designing core architecture, implementing low-level RVV/IME kernels, or deep multi-crate debugging.

## 8. WebAssembly, Static SPA Caching & Mobile UI

- **Dual-Layer Caching**: Web endpoints serving WASM/SPA frontends must implement dual-layer caching: `Cache-Control: no-cache, no-store, must-revalidate` for HTML entry points, and content-hash URL busting (`?v=<hash>`) with `no-cache, must-revalidate` for WASM/JS/CSS assets.
- **Mobile Viewport Invariants**: Mobile web frontends must adhere to mobile viewport constraints: contained segmented controls with horizontal scrolling, responsive labels, and `font-size: 16px` on form inputs to prevent iOS Safari auto-zoom.

## 9. Rust: usize vs u32

Use usize for indexing collections, array lengths, or anything interacting with memory allocation; use u32 for domain-specific domain data, math, IDs, counters, or network packets where the size must be exactly 32 bits regardless of the computer running the code.
