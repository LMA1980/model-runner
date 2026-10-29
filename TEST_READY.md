# Milestone M3 Test Readiness Report (`TEST_READY.md`)

## 1. Executive Summary

The comprehensive opaque-box End-to-End (E2E) test suite for **Milestone M3 ("Storage Lifecycle & External Protocols", US-18 through US-24, GitHub issues #18–#24)** has been fully designed, authored, and verified.

- **Total Test Cases**: **87 tests** (40 storage tests, 30 protocol & ingestion tests, 17 cross-feature & scenario tests).
- **Test Architecture**: 4 progressive tiers covering feature happy paths (Tier 1: 35 tests), boundary & corner cases (Tier 2: 35 tests), cross-feature pairwise interactions (Tier 3: 12 tests), and real-world multi-model application workloads (Tier 4: 5 tests).
- **Test Isolation & Integrity**: 100% self-contained opaque-box tests conforming strictly to **`AGENTS.md` Rule 5** (conservative context bounds `n_ctx: 64`, small mock store roots, and isolated temporary directories to prevent `LimitMEMLOCK` exhaustion and system locking stalls) and **`AGENTS.md` Rule 9** (`usize` for memory/indexing, `u32` for domain IDs and network parameters).
- **Execution Status**: All 87 tests compile cleanly with **0 failures and 0 warnings**.
- **Specification Documentation**: Comprehensive test architecture and feature mapping published in `/Users/lma1980/repository/TEST_INFRA.md`.

---

## 2. Test Suite Structure & Inventory

The test suite is organized into 3 dedicated integration test files in `/Users/lma1980/repository/model-runner/code/manager/tests/`:

### 2.1 Storage Lifecycle Suite (`tests/e2e_m3_storage_test.rs` — 40 tests)

Covers US-18 (Content-Addressed Model Store), US-20 (Recipe Capability Filter), US-21 (Derived Weight Layout Caching), and US-22 (Safe Garbage Collection):

- **Tier 1: Feature Coverage (20 tests)**:
  - **US-18**: `test_tier1_us18_cas_deduplication_cross_source`, `test_tier1_us18_alias_hierarchy_resolution`, `test_tier1_us18_duckdb_catalog_tracking`, `test_tier1_us18_configurable_store_root_nvme`, `test_tier1_us18_model_build_identity_composite`.
  - **US-20**: `test_tier1_us20_capability_filter_matching_recipe`, `test_tier1_us20_upfront_rejection_unsupported_recipe`, `test_tier1_us20_tokenizer_template_recipe_alignment`, `test_tier1_us20_candidate_discovery_capability_tagging`, `test_tier1_us20_quantization_format_support_check`.
  - **US-21**: `test_tier1_us21_derived_layout_caching_and_reuse`, `test_tier1_us21_retention_policy_keep_and_purge`, `test_tier1_us21_memory_admission_derived_footprint`, `test_tier1_us21_stale_recipe_auto_rebuild_or_advisory`, `test_tier1_us21_target_layout_enumeration`.
  - **US-22**: `test_tier1_us22_alias_removal_preserves_shared_blob`, `test_tier1_us22_storage_watermark_warning_no_autodelete`, `test_tier1_us22_dual_gate_safe_gc_flock_and_maps`, `test_tier1_us22_who_uses_administrative_query`, `test_tier1_us22_offline_safe_gc`.

- **Tier 2: Boundary & Corner Cases (20 tests)**:
  - **US-18**: `test_tier2_us18_path_traversal_alias_rejected`, `test_tier2_us18_corrupted_digest_rejected`, `test_tier2_us18_sql_injection_defense_duckdb`, `test_tier2_us18_empty_blob_registration_rejected`, `test_tier2_us18_nonexistent_root_create_or_err`.
  - **US-20**: `test_tier2_us20_minor_revision_mismatch_qwen3_8`, `test_tier2_us20_missing_quantization_kernel_rejected`, `test_tier2_us20_malformed_manifest_json_rejected`, `test_tier2_us20_recipe_tokenizer_mismatch_rejected`, `test_tier2_us20_recipe_version_downgrade_handling`.
  - **US-21**: `test_tier2_us21_stale_derived_with_purged_original`, `test_tier2_us21_zero_delay_immediate_purge`, `test_tier2_us21_dual_layout_admission_saturation`, `test_tier2_us21_corrupt_derived_layout_header`, `test_tier2_us21_concurrent_rebuild_requests_dedup`.
  - **US-22**: `test_tier2_us22_gc_gate1_flock_active_rejection`, `test_tier2_us22_gc_gate2_maps_active_rejection`, `test_tier2_us22_watermark_exact_threshold_boundary`, `test_tier2_us22_who_uses_nonexistent_blob_handled`, `test_tier2_us22_dry_run_gc_idempotence`.

### 2.2 External Protocols & Ingestion Suite (`tests/e2e_m3_protocols_test.rs` — 30 tests)

Covers US-19 (Source Ingestion & Arrow Flight), US-23 (OpenAI Protocol Front-End), and US-24 (Anthropic Claude Protocol Front-End):

- **Tier 1: Feature Coverage (15 tests)**:
  - **US-19**: `test_tier1_us19_source_adapter_lifecycle_contract`, `test_tier1_us19_staging_and_atomic_promotion`, `test_tier1_us19_network_credential_isolation`, `test_tier1_us19_arrow_flight_tensor_streaming`, `test_tier1_us19_memfd_arena_sealing_and_mlock`.
  - **US-23**: `test_tier1_us23_openai_models_endpoint_unprofiled_tag`, `test_tier1_us23_openai_chat_sync_and_sse_streaming`, `test_tier1_us23_openai_tool_calls_passthrough`, `test_tier1_us23_openai_queue_feedback_and_429_retry`, `test_tier1_us23_openai_context_overflow_400_error`.
  - **US-24**: `test_tier1_us24_claude_messages_content_blocks`, `test_tier1_us24_claude_streaming_sse_full_lifecycle`, `test_tier1_us24_claude_thinking_delta_reasoning_stream`, `test_tier1_us24_claude_tool_use_passthrough`, `test_tier1_us24_claude_queue_feedback_and_529_overload`.

- **Tier 2: Boundary & Corner Cases (15 tests)**:
  - **US-19**: `test_tier2_us19_interrupted_download_staging_cleanup`, `test_tier2_us19_corrupted_format_header_rejected`, `test_tier2_us19_adapter_invalid_credentials_error`, `test_tier2_us19_flight_network_interruption_recovery`, `test_tier2_us19_memfd_seal_violation_prevention`.
  - **US-23**: `test_tier2_us23_openai_sse_client_early_disconnect`, `test_tier2_us23_openai_empty_tool_definitions`, `test_tier2_us23_openai_prompt_exactly_n_ctx`, `test_tier2_us23_openai_malformed_json_body_400`, `test_tier2_us23_openai_queue_saturation_retry_after_header`.
  - **US-24**: `test_tier2_us24_claude_thinking_delta_empty_text`, `test_tier2_us24_claude_multi_block_mixed_content`, `test_tier2_us24_claude_invalid_role_sequence_error`, `test_tier2_us24_claude_context_overflow_invalid_request`, `test_tier2_us24_claude_queue_saturation_529_body`.

### 2.3 Scenarios & Cross-Feature Suite (`tests/e2e_m3_scenarios_test.rs` — 17 tests)

Covers Tier 3 Pairwise Cross-Feature Interactions and Tier 4 Production Real-World Scenarios:

- **Tier 3: Pairwise Interactions (12 tests)**:
  1. `test_tier3_pairwise_us18_cas_and_us21_derived_caching`: Raw weight blob stored in CAS is repacked into derived layout; derived blob references source digest in DuckDB catalog.
  2. `test_tier3_pairwise_us18_alias_removal_and_us22_safe_gc`: Multi-tag model has one tag removed; alias and manifest are unlinked; shared blob is retained; second tag removed and GC reclaims blob.
  3. `test_tier3_pairwise_us19_ingestion_and_us20_capability_filtering`: External model pull validates format and architecture recipe in staging; unsupported recipe aborts before CAS promotion.
  4. `test_tier3_pairwise_us19_ingestion_and_us21_derived_repacking`: Freshly ingested raw weights trigger immediate hardware repacking; retention policy purges source upon derived completion.
  5. `test_tier3_pairwise_us20_capability_and_us23_openai_discovery`: OpenAI `GET /v1/models` filters registry entries, reporting only verified recipe-aligned models.
  6. `test_tier3_pairwise_us20_capability_and_us24_claude_chat_template`: Claude message translation uses exact recipe-bound tokenizer and template format for generation.
  7. `test_tier3_pairwise_us21_retention_and_us22_safe_gc`: Derived layout created with `purge_immediate`; GC safely reclaims original source weights while derived layout remains actively mapped.
  8. `test_tier3_pairwise_us22_gc_and_us19_concurrent_ingestion`: Safe GC executes while concurrent external model pull writes to staging; staging `.part` files are never touched by GC.
  9. `test_tier3_pairwise_us23_openai_and_us22_who_uses_inspection`: Active OpenAI streaming request keeps worker lock open; operator `k3-store who-uses` lists worker PID.
  10. `test_tier3_pairwise_us24_claude_reasoning_and_us21_derived_layout`: Claude reasoning model (`thinking_delta`) runs forward passes against cached IME-repacked derived weights.
  11. `test_tier3_pairwise_us23_openai_and_us24_claude_concurrent_frontends`: Simultaneous OpenAI and Claude clients query the same loaded model without interference.
  12. `test_tier3_pairwise_us19_staging_abort_and_us22_watermark_warning`: Download failure cleans staging and releases reserved disk space, resetting watermark warning state.

- **Tier 4: Real-World Application Scenarios (5 tests)**:
  1. `test_tier4_scenario1_multi_model_storage_lifecycle_dual_nvme_tiering`: Multi-model storage lifecycle with dual-tier NVMe storage and shared deduplicated weights.
  2. `test_tier4_scenario2_remote_node_provisioning_arrow_flight_memfd`: Remote accelerator node provisioning via Apache Arrow Flight streaming into RAM `memfd`.
  3. `test_tier4_scenario3_openai_client_streaming_tool_calling_queue_feedback`: Production OpenAI client application with SSE streaming, tool calling, and advancing queue feedback.
  4. `test_tier4_scenario4_claude_agent_reasoning_blocks_and_tool_use`: Autonomous coding agent with Anthropic Claude protocol, reasoning blocks (`thinking_delta`), and tool use.
  5. `test_tier4_scenario5_edge_gateway_cold_boot_stale_recipe_safe_gc`: High-density edge gateway cold boot, breaking recipe upgrade auto-rebuild, and safe background GC.

---

## 3. How to Run the Test Suites

Execute from `/Users/lma1980/repository/model-runner/code`:

```bash
# Storage Lifecycle Suite (40 tests)
cargo test -p k3-manager --test e2e_m3_storage_test

# External Protocols & Ingestion Suite (30 tests)
cargo test -p k3-manager --test e2e_m3_protocols_test

# Scenarios & Cross-Feature Suite (17 tests)
cargo test -p k3-manager --test e2e_m3_scenarios_test

# Run All 87 E2E Tests Across Tiers 1-4
cargo test -p k3-manager \
    --test e2e_m3_storage_test \
    --test e2e_m3_protocols_test \
    --test e2e_m3_scenarios_test
```

---

## 4. Verification Results Summary

```
test result: ok. 40 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out (e2e_m3_storage_test)
test result: ok. 30 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out (e2e_m3_protocols_test)
test result: ok. 17 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out (e2e_m3_scenarios_test)
-------------------------------------------------------------------------------------------------
TOTAL: 87 passed; 0 failed; 0 ignored; 0 warnings.
```

---

## 5. Discovered Implementation Defects & Observations

During test verification, no test regressions were observed. One minor compiler warning was observed in concurrent library implementation code:
- **Location**: `model-runner/code/manager/src/store/derived.rs:8:21`
- **Warning**: `unused import: File`
- **Remediation**: Remove `File` from `use std::fs::{self, File};` in `derived.rs` (escalated to implementer).
