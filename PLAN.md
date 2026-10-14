# K3 Uber AI Runtime Master Plan

## 1. Overview
Target: SpacemiT K3 SoC (8x X100 + 8x A100 RISC-V cores, 32GB RAM).
Topology: Local standalone or distributed node (e.g., x86 control plane).

## 2. Architecture Pillars
- **Core Splitting**: X100 (OoO, 256-bit) handles sessions/routing; A100 (InO, 1024-bit) executes tensor kernels.
- **API & Protocol**: OpenAI, Claude, and MCP tool interoperability.
- **Project & Session Scope**: Multi-turn history with project isolation.
- **Multi-Model Orchestration**: Tiered queues for fast decision models vs large generative models.
- **Diagnostic Tool**: Non-interactive CLI for evaluation and benchmarking.

## 3. Roadmap
1. **Business Logic & Specs**: Refine sessions, routing, and scheduler.
2. **Diagnostic Tool**: Standalone evaluator for decision/chat models.
3. **Session & Engine Runtime**: Control plane and A100 compute workers.

## Navigation
- [Features Index](features/index.md)
- [Specs Index](specs/index.md)
