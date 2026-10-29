# Milestone M2 Test Infrastructure & Opaque-Box Test Strategy

## 1. Test Philosophy & Design Principles

### 1.1 Opaque-Box & Requirement-Driven Architecture

The test infrastructure for Milestone M2 ("Multi-Model Runtime, Memory & Isolation", codename `Orchestrate`) is constructed strictly as an **opaque-box, requirement-driven test framework**.
Tests observe and validate system behavior solely through authoritative external interface contracts, public APIs, IPC message schemas, and state transitions mandated by:

- `ORIGINAL_REQUEST.md`
- `PROJECT.md`
- Architectural Decision Records (`ADR-005`, `ADR-006`, `ADR-007`, `ADR-010`, `ADR-011`, `ADR-013`, `ADR-014`, `ADR-015`, `ADR-027`, `ADR-030`, `ADR-031`, `ADR-032`, `ADR-041`, `ADR-042`, `ADR-043`)
- Formal User Stories (`US-08` through `US-17`)

### 1.2 Isolation & Independent Verification

Tests are completely decoupled from internal module implementations (such as private struct fields or helper functions). Any future refactoring of internal scheduler algorithms or memory indexing engines that preserves the interface contract will leave these tests green.

### 1.3 Progressive Testability & Conservative Memory Bounding

To guarantee deterministic execution across continuous integration (CI) runners, unprivileged test environments, and physical target hardware (`SpacemiT K3 SoC` on `pey-wail-deu`):

- All memory allocations adhere to **`AGENTS.md` Rule 5**: conservative context bounds (`n_ctx: 64`) are enforced across test harnesses to prevent `RLIMIT_MEMLOCK` exhaustion and system locking stalls.
- Tests do not require physical hardware matrix units or SpacemiT-patched kernels; mock backends and CPU emulation are exercised where appropriate while cross-compilation for `riscv64gc-unknown-linux-gnu` ensures zero ABI drift.
- Each test is fully self-contained: it initializes its own state, isolates temporary socket paths and database files using unique process/sequence identifiers, and cleans up resources on teardown.

______________________________________________________________________

## 2. Test Tier Taxonomy & Architecture

The opaque-box test suite is organized into a four-tier progressive hierarchy:

| Tier       | Name                           | Focus                                                                                        | Minimum Requirement                             | Milestone Scope                |
| :--------- | :----------------------------- | :------------------------------------------------------------------------------------------- | :---------------------------------------------- | :----------------------------- |
| **Tier 1** | **Feature Coverage**           | Primary happy-path contracts, authoritative profile retention, admission, and state machines | $\\ge 5$ tests per feature ($\\ge 50$ total)    | Features 1–34 (US-08 to US-17) |
| **Tier 2** | **Boundary & Corner Cases**    | Edge values, saturation caps, invalid masks, crash boundaries, error diagnostics             | $\\ge 5$ tests per feature ($\\ge 50$ total)    | Features 1–34 (US-08 to US-17) |
| **Tier 3** | **Cross-Feature Interactions** | Pairwise module interactions, preemption during lending, routing under queuing               | $\\ge 10$ pairwise tests ($\\ge 10$ total)      | Cross-story interplay          |
| **Tier 4** | **Real-World Workloads**       | Multi-tenant end-to-end applications, crash recovery, cold reboots                           | $\\ge 5$ application scenarios ($\\ge 5$ total) | Full system orchestration      |
| **Total**  |                                | **Comprehensive Test Suite**                                                                 | **$\\ge 115$ test cases**                       | **Milestone M2**               |

______________________________________________________________________

## 3. Feature Inventory & Tier Mapping (Features 1–37)

The table below maps all 37 platform features defined in `PROJECT.md` across Tiers 1–3, tracing their authoritative specifications, inputs, outputs, and verification suites:

| #      | Feature Name                       | User Story | Tier 1 (Feature Coverage)                                           | Tier 2 (Boundary & Corner)                                           | Tier 3 (Cross-Feature Interplay)                                  |
| :----- | :--------------------------------- | :--------- | :------------------------------------------------------------------ | :------------------------------------------------------------------- | :---------------------------------------------------------------- |
| **1**  | **Operator Tuning Immutability**   | US-08      | `test_tier1_us08_tuning_profile_immutability_under_traffic`         | `test_tier2_us08_extreme_cost_variance_divergence`                   | Interplay with US-10: Latency class preserves immutability        |
| **2**  | **Dynamic Cost Weights**           | US-08      | `test_tier1_us08_dynamic_cost_weights_refinement`                   | `test_tier2_us08_zero_cost_weight_defensive_clamp`                   | Interplay with US-10: Cost-weighted fair sharing                  |
| **3**  | **Advisory Recommendations**       | US-08      | `test_tier1_us08_advisory_recommendation_tradeoffs`                 | `test_tier2_us08_suggest_tuning_for_unprofiled_model`                | Interplay with US-17: Operator applies & persists advisory        |
| **4**  | **Active Model Limit**             | US-09      | `test_tier1_us09_concurrency_cap_up_to_max_active_models`           | `test_tier2_us09_reject_load_exceeding_max_active_models`            | Interplay with US-14: Memory reservation vs concurrency cap       |
| **5**  | **Non-Overlapping Parallelism**    | US-09      | `test_tier1_us09_non_overlapping_parallel_execution`                | `test_tier2_us09_disjoint_masks_x100_and_a100_boundary`              | Interplay with US-11: Parallel disjoint vs borrowed cores         |
| **6**  | **Overlapping Time-Slicing**       | US-09      | `test_tier1_us09_overlapping_pass_boundary_timeslicing`             | `test_tier2_us09_single_bit_overlapping_mask_arbitration`            | Interplay with US-10: Preemption at overlapping boundary          |
| **7**  | **Single-Prompt Exclusivity**      | US-09      | `test_tier1_us09_single_prompt_exclusivity_tail_underfill`          | `test_tier2_us09_unaligned_prompt_token_length_tail_block_underfill` | Interplay with US-13: Serialized pass under queuing               |
| **8**  | **Priority Preemption**            | US-10      | `test_tier1_us10_latency_preemption_at_pass_boundary`               | `test_tier2_us10_latency_arrival_at_exact_boundary`                  | Interplay with US-12: Decision router preempts batch models       |
| **9**  | **Weighted Fair Sharing**          | US-10      | `test_tier1_us10_same_priority_weighted_fair_sharing`               | `test_tier2_us10_extreme_cost_ratio_1_to_50_pass_interleaving`       | Interplay with US-13: Fair dequeue across models                  |
| **10** | **Client Priority Immunity**       | US-10      | `test_tier1_us10_client_priority_override_immunity`                 | `test_tier2_us10_malformed_client_priority_headers_ignored`          | Interplay with US-08: Operator profile remains authoritative      |
| **11** | **Opt-In Core Lending**            | US-11      | `test_tier1_us11_default_isolation_both_disabled`                   | `test_tier2_us11_unprofiled_model_lending_borrowing_rejected`        | Interplay with US-09: Overlapping scheduling during idle          |
| **12** | **Opt-In Core Borrowing**          | US-11      | `test_tier1_us11_temporary_single_pass_core_borrowing`              | `test_tier2_us11_borrowing_attempt_overlap_control_mask_prohibited`  | Interplay with US-16: Worker crash during borrowed pass           |
| **13** | **Instant Pass-Boundary Reclaim**  | US-11      | `test_tier1_us11_immediate_pass_boundary_core_reclaim`              | `test_tier2_us11_owner_traffic_arriving_during_borrowed_pass`        | Interplay with US-10: Preemption during reclaimed pass            |
| **14** | **Pre-pinned Thread Spillover**    | US-11      | `test_tier1_us11_pre_pinned_thread_work_stealing`                   | `test_tier2_us11_core_expansion_capped_at_hardware_cluster_limit`    | Interplay with US-14: Arena access from pre-pinned threads        |
| **15** | **Dedicated Model Memory Arenas**  | US-14      | `test_tier1_us14_dedicated_memfd_per_model_isolation`               | `test_tier2_us14_burst_traffic_does_not_leak_into_peer_arena`        | Interplay with US-15: Intra-arena prefix allocation               |
| **16** | **Load-time Memory Admission**     | US-14      | `test_tier1_us14_load_time_memory_admission_verification`           | `test_tier2_us14_rlimit_memlock_lower_than_arena_rejected`           | Interplay with US-09: Upfront rejection preserves running state   |
| **17** | **Intra-Arena Block Eviction**     | US-14      | `test_tier1_us14_intra_arena_lru_block_eviction`                    | `test_tier2_us14_burst_traffic_does_not_leak_into_peer_arena`        | Interplay with US-15: Evict unreferenced vs COW blocks            |
| **18** | **Prompt Context Cap Rejection**   | US-14      | `test_tier1_us14_prompt_token_length_n_ctx_cap_rejection`           | `test_tier2_us14_prompt_length_exactly_n_ctx_rejected`               | Interplay with US-13: Rejection before queue admission            |
| **19** | **Project Prefix Indexing**        | US-15      | `test_tier1_us15_implicit_stateless_multi_turn_prefix_match`        | `test_tier2_us15_16_token_block_alignment_exact_and_suffix`          | Interplay with US-14: Paged block allocation in arena             |
| **20** | **Copy-On-Write Prefix Sharing**   | US-15      | `test_tier1_us15_intra_project_branching_cow_prefix_sharing`        | `test_tier2_us15_cow_refcount_underflow_overflow_safety`             | Interplay with US-16: Crash resume preserves shared blocks        |
| **21** | **Strict Cross-Project Isolation** | US-15      | `test_tier1_us15_strict_cross_project_cache_isolation`              | `test_tier2_us15_identical_prompt_different_tenants_isolation`       | Interplay with US-17: Tenant/project metadata isolation           |
| **22** | **Persistent Memory Holder**       | US-16      | `test_tier1_us16_kv_holder_persistence_across_worker_crash`         | `test_tier2_us16_repeated_worker_crashes_recovery_ceiling`           | Interplay with US-14: Memory arena survives worker lifecycle      |
| **23** | **Token & Sampler Checkpointing**  | US-16      | `test_tier1_us16_token_and_sampler_checkpointing_in_block_meta`     | `test_tier2_us16_corrupt_sampler_rng_state_detection_fallback`       | Interplay with US-15: Block meta tracks committed tokens          |
| **24** | **Worker Crash Resumption**        | US-16      | `test_tier1_us16_decode_resumption_without_prefill_reexecution`     | `test_tier2_us16_worker_crash_at_token_zero_prefill_boundary`        | Interplay with US-11: Crash during borrowed core expansion        |
| **25** | **Client Reconnect Recovery**      | US-16      | `test_tier1_us16_client_reconnect_within_retention_window`          | `test_tier2_us16_client_reconnect_after_retention_window_expired`    | Interplay with US-13: Reconnect re-attaches to queued pass        |
| **26** | **Dual-Role Decision Models**      | US-12      | `test_tier1_us12_direct_decision_model_invocation`                  | `test_tier2_us12_empty_prompt_auto_routing_handling`                 | Interplay with US-09: Direct placement alongside specialists      |
| **27** | **Critical Path Auto-Routing**     | US-12      | `test_tier1_us12_auto_routing_critical_path_specialist_selection`   | `test_tier2_us12_router_returns_unrecognized_model_id`               | Interplay with US-10: Latency-class preemption on critical path   |
| **28** | **Routing Fallback & Error**       | US-12      | `test_tier1_us12_operator_fallback_model_on_missing_router`         | `test_tier2_us12_auto_routing_router_missing_no_fallback_error`      | Interplay with US-13: Fast error response avoids queue hang       |
| **29** | **Deep FIFO Admission Queues**     | US-13      | `test_tier1_us13_fifo_admission_order_preservation`                 | `test_tier2_us13_exact_capacity_saturation_64th_vs_65th`             | Interplay with US-09: Single-prompt dispatch from FIFO queue      |
| **30** | **Streaming Queue Feedback**       | US-13      | `test_tier1_us13_advancing_queue_position_streaming`                | `test_tier2_us13_client_disconnect_queue_pruning_positions_advance`  | Interplay with US-16: Keep-alives prevent disconnect during wait  |
| **31** | **Saturation Rejection**           | US-13      | `test_tier1_us13_disabled_wait_timeout_patient_queuing`             | `test_tier2_us13_retry_after_header_formatting_429_529`              | Interplay with US-10: Heavy load rejected cleanly at cap          |
| **32** | **SQLite Metadata Store**          | US-17      | `test_tier1_us17_persistent_schema_initialization_tenants_projects` | `test_tier2_us17_foreign_key_integrity_violation_rejection`          | Interplay with US-08: Tuning profile persisted in SQLite          |
| **33** | **Single-Row Session Record**      | US-17      | `test_tier1_us17_bounded_single_row_last_turn_overwrite_invariant`  | `test_tier2_us17_100_turn_session_remains_strictly_one_row`          | Interplay with US-15: Turn completion writes latest interaction   |
| **34** | **Last-Turn Diagnostic Replay**    | US-17      | `test_tier1_us17_diagnostic_replay_prompt_reproduction`             | `test_tier2_us17_replay_nonexistent_session_id_error`                | Interplay with US-16: Replay verifies deterministic sampler state |
| **35** | **E2E Test Suite Tiers 1–4**       | Meta       | Covered by `m2_e2e_tier1_feature_coverage_test`                     | Covered by `m2_e2e_tier2_boundary_corner_test`                       | Covered by `m2_e2e_tier3_cross_feature_test` & `tier4`            |
| **36** | **Adversarial Hardening Tier 5**   | Meta       | Addressed in Milestone M4 adversarial suites                        | Boundary & race injection in M4                                      | Stress & fault injection in M4                                    |
| **37** | **Git Branch & PR Delivery**       | Meta       | Governed by `feat/m2-multi-model-runtime`                           | Verified across submodules                                           | Validated via `gh pr create`                                      |

______________________________________________________________________

## 4. Real-World Application Workloads (Tier 4 Scenarios)

Tier 4 tests model end-to-end multi-model production scenarios representing realistic operational deployments on the K3 SoC:

### Scenario 1: Multi-Tenant Developer Workstation (IDE Code Completion)

- **Workload**: Two independent developers working in Project A and Project B. Developer A branches multiple tabs from a shared repository index (long system prompt + project header).
- **Assertions**:
  1. Requests within Project A share common 16-token context blocks via Copy-On-Write without duplicating KV memory.
  1. Developer B receives completely isolated context memory even when submitting identical system instructions.
  1. Short completions are interleaved fairly without starvation.

### Scenario 2: High-Priority Decision Routing with Latency Preemption

- **Workload**: An interactive `model: auto` query arrives while a heavy background summarization model (`Throughput` priority class) is executing continuous forward passes on overlapping compute cores.
- **Assertions**:
  1. The internal decision router (`Latency` priority class) evaluates the prompt on the critical path.
  1. The scheduler yields compute to the routed interactive request at the very next forward-pass boundary.
  1. The background summarization pass finishes cleanly; the interactive model completes with minimal latency; summarization resumes without token corruption.

### Scenario 3: Bursty Multi-Model Traffic with Dynamic Core Lending & Instant Reclaim

- **Workload**: Model A (interactive customer chatbot) and Model B (offline document batch embedder) are configured with `lend_idle_cores = true` and `borrow_idle_cores = true`.
- **Assertions**:
  1. During quiet periods, Model B borrows Model A's idle cores, dynamically doubling its forward-pass execution speed.
  1. As soon as a user message arrives for Model A, Model B finishes its single executing pass, and Model A's cores are reclaimed immediately at the pass boundary.
  1. Zero cgroup rewrites or kernel lock stalls occur.

### Scenario 4: Worker Crash During Multi-Turn Dialog & Transparent Resumption

- **Workload**: An active client engages in a 3-turn conversation. On turn 3, midway through generating a 20-token response (at token 12), the compute worker process suffers an unhandled abort / crash.
- **Assertions**:
  1. `HealthSupervisor` reaps the dead worker process while preserving the independent `k3-kv` shared memory arena.
  1. The replacement worker attaches to the surviving arena via `SCM_RIGHTS`.
  1. Resumes decode generation from token 12 to 20 using the checkpointed `committed_token_count` and PRNG sampler state, without re-executing prefill.
  1. The completed interaction is persisted to SQLite as a single-row last turn.

### Scenario 5: Patient Admission Queuing Under Sustained Saturation

- **Workload**: A model configured with conservative memory bounds (`n_ctx = 64`) receives a sudden flood of 65 concurrent inference requests.
- **Assertions**:
  1. Requests 1 through 64 are admitted to the FIFO queue and receive periodic SSE keep-alives with advancing queue position updates (`: keep-alive position=N\n\n`).
  1. Request 65 is immediately rejected with HTTP 429 / 529 and a valid `Retry-After: <sec>` header.
  1. All 64 admitted requests execute to completion without premature timeout or quota throttling.

### Scenario 6: Cold Boot Power Cycle with SQLite Restoration & Diagnostic Replay

- **Workload**: Full platform reboot simulation after operational configuration and multi-turn sessions.
- **Assertions**:
  1. SQLite database reloads all tenants, projects, token budgets, applied model tuning profiles, and cumulative statistics.
  1. Operator triggers `k3-diag replay <session_id>`; the runtime reconstructs the exact prompt and generation parameters from the persisted single-row record and verifies deterministic token match.

______________________________________________________________________

## 5. Test Runner Commands & Pass/Fail Semantics

### 5.1 Verification Commands

All test suites are executed from the workspace root or `code/` directory:

```bash
# Run Tier 1: Feature Coverage Suite (>= 50 test cases)
cargo test -p k3-manager --test m2_e2e_tier1_feature_coverage_test

# Run Tier 2: Boundary & Corner Cases Suite (>= 50 test cases)
cargo test -p k3-manager --test m2_e2e_tier2_boundary_corner_test

# Run Tier 3: Cross-Feature Interactions Suite (>= 10 test cases)
cargo test -p k3-manager --test m2_e2e_tier3_cross_feature_test

# Run Tier 4: Real-World Multi-Model Workloads Suite (>= 5 scenarios)
cargo test -p k3-manager --test m2_e2e_tier4_real_world_workloads_test

# Run the Entire Milestone M2 Opaque-Box E2E Test Suite (>= 115 tests total)
cargo test -p k3-manager --test m2_e2e_*

# Verify Clean Cross-Target Compilation for SpacemiT K3 (RISC-V 64-bit)
cargo check --target riscv64gc-unknown-linux-gnu --workspace --tests
```

### 5.2 Pass/Fail Semantics & Quality Gate

1. **Zero Test Failures**: Every test case across Tiers 1–4 must exit with code `0`. A single failed assertion blocks milestone progression.
1. **Zero Clippy Warnings**: Test code and crate sources must pass `cargo clippy --workspace --all-targets -- -D warnings` with zero warnings.
1. **Deterministic Cleanup**: All sockets, memory maps, and SQLite temporary databases must be unlinked and cleaned up upon test completion.
1. **Conservative Memory Conformance**: All tests must run cleanly within default unprivileged user memory bounds without requiring elevated `RLIMIT_MEMLOCK` or root capabilities.
