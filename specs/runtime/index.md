# Specs: Runtime Subsystem

Components implementing `k3-engine` runtime and isolation.

## Components

- [Core Scheduler](scheduler.md): Dynamic queues, arbitration, and work-stealing.
- [Inference Worker](worker.md): RVV 1.0 & IME compute kernels and recipes.
- [Process Model](process-model.md): Multi-process hierarchy and IPC.
- [Isolation](isolation.md): systemd cgroups, namespaces, and sandboxing.
