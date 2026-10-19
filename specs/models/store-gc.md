# Spec: Store Garbage Collection

## Location: `specs/models/store-gc.md`

### Architecture & k3-admin
- Operator tool `k3-admin store gc` cleans unreferenced and stale blobs (ADR-039).
- Automated via systemd `k3-store-gc.service` (timer or event-based path trigger).

### Safety Protocol
Two mandatory deletion gates (ADR-040):
1. **Flock Check**: Engines hold `flock(LOCK_SH)` on mapped blobs; GC requests `LOCK_EX|LOCK_NB`.
2. **Process Maps Check**: GC inspects `/proc/*/maps` to verify no engine maps the blob (works offline).
