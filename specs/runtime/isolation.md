# Spec: System Isolation & CGroups

## Location: `specs/runtime/isolation.md`

### Slice Architecture (`k3.slice`)

- **control**: `k3-manager.service` (reserved X100 threads, no net, moves to leaf `.../control`) (ADR-007, ADR-041).
- **compute**: Delegated subtree `.../engines/<model>` (`Delegate=yes`, cpuset = reservation | lendable, no net, read-only store) (ADR-041).
- **kv**: `k3-kv.service` (dedicated KV memory cgroup, `mlock`) (ADR-042).
- **edge**: `k3-ext@<name>.service` (only domain with network namespace) (ADR-041).
