# Spec: System Isolation & CGroups

## Location: `specs/runtime/isolation.md`

### Slice Architecture (`k3.slice`)

- **control**: `k3-manager.service` (reserved X100 threads, no net, moves to leaf `.../control`) (ADR-007, ADR-041).
- **compute**: Delegated subtree `.../engines/<model>` (`Delegate=yes`, cpuset = reservation | lendable, no net, read-only store) (ADR-041).
- **kv**: `k3-kv.service` (dedicated KV memory cgroup, `mlock`) (ADR-042).
- **edge**: `k3-ext@<name>.service` (only domain with network namespace) (ADR-041).

### Service Reload (`systemctl reload`, Delayed / Nice-to-Have)

- `k3-manager.service`: Planned `ExecReload` (`SIGHUP` / `k3-admin reload`) reloads profiles, budgets, and registry at pass boundaries without killing `.../engines/<model>` workers (ADR-032, ADR-041).
- `k3-ext@<name>.service`: Planned `ExecReload` reloads adapter config without dropping streams.
- `k3-kv.service`: Policy-free; `reload` unsupported (ADR-042).
