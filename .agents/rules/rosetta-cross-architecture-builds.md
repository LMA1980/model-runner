# Rosetta Cross-Architecture Container Builds

## Context & Constraint
On Apple Silicon (macOS `aarch64`), running cross-architecture containers (e.g. `podman run --platform linux/amd64` or `docker run --platform linux/amd64`) relies on Apple's Rosetta 2 translation layer within the Linux virtual machine.

Rosetta requires `/proc/self/exe` to resolve and translate x86_64 ELF binaries.

## Mandatory Invariants

1. **Never Use Nested `chroot` in Emulated Containers**:
   - Calling `chroot <dir> <command>` inside an emulated x86_64 container without a mounted `/proc` causes immediate termination:
     `rosetta error: Unable to open /proc/self/exe: 2` (signal 133 / SIGTRAP core dump).

2. **Apply Configurations Directly to Container Layers**:
   - When building root filesystems, OS images, or squashfs payloads:
     - Perform all package installations, user creation, password hashing, and service configuration **directly in the container root** (via Dockerfile `RUN` steps or the primary container process).
     - Once configured, directly pack or archive the filesystem (e.g., `mksquashfs / ...` or `tar`), excluding pseudo-filesystems (`/proc`, `/sys`, `/dev`, `/run`).

3. **Fallback If Chroot Is Unavoidable**:
   - If a tool or script strictly requires a nested chroot, mount the kernel pseudo-filesystems into the target directory before executing:
     ```bash
     mount -t proc /proc "${TARGET}/proc"
     mount -t sysfs /sys "${TARGET}/sys"
     mount --bind /dev "${TARGET}/dev"
     ```
