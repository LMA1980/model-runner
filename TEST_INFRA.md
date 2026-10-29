# Milestone M3 Test Infrastructure & Opaque-Box Test Strategy

## 1. Test Philosophy & Design Principles

### 1.1 Opaque-Box & Requirement-Driven Architecture

The test infrastructure for Milestone M3 ("Storage Lifecycle & External Protocols", codename `Ecosystem`) is constructed strictly as an **opaque-box, requirement-driven test framework**. Tests observe and validate system behavior solely through authoritative external interface contracts, public APIs, cryptographic assertions, protocol wire framing, and state transitions mandated by:

- `ORIGINAL_REQUEST.md` (Milestone M3 requirements)
- `PROJECT.md` (M3 Architecture, Feature Inventory, Interface Contracts, and Code Layout)
- Architectural Decision Records (`ADR-003`, `ADR-015`, `ADR-017`, `ADR-019`, `ADR-020`, `ADR-021`, `ADR-023`, `ADR-024`, `ADR-025`, `ADR-027`, `ADR-031`, `ADR-035`, `ADR-036`, `ADR-037`, `ADR-038`, `ADR-039`, `ADR-040`, `ADR-041`)
- Formal User Stories (`US-18` through `US-24`)
- Technical Specifications (`specs/models/registry.md`, `specs/models/source-adapter.md`, `specs/models/store-gc.md`, `specs/api/openai.md`, `specs/api/claude.md`, `specs/api/extensions.md`)

### 1.2 Isolation & Independent Verification

Tests are completely decoupled from internal module private helpers or ephemeral layout mutations. Every test sets up its own isolated state:
- Dedicated temporary directory hierarchies (`std::env::temp_dir().join(...)`) for CAS store roots, staging areas, and Unix Domain Sockets.
- Isolated in-memory or dedicated temporary DuckDB catalog instances with 100% parameterized queries (zero SQLite).
- Strict cleanup on teardown guaranteeing zero side-effects across test boundaries or between sequential test runs.

### 1.3 Progressive Testability & Conservative Resource Bounding

To guarantee deterministic, reliable execution across continuous integration (CI) runners, unprivileged test environments, and physical target hardware (`SpacemiT Key Stone K3 SoC` on `pey-wail-deu`):
- All memory allocations adhere strictly to **`AGENTS.md` Rule 5**: conservative context bounds (`n_ctx: 64`, requiring ~64 KB KV cache footprint) are enforced across test harnesses to prevent `RLIMIT_MEMLOCK` exhaustion and system locking stalls.
- All store and staging fixtures operate on bounded synthetic weight fixtures (small byte slices, valid GGUF/SafeTensors magic headers, and SHA-256 digests) rather than multi-gigabyte production weights.
- All integer and collection indexing adheres to **`AGENTS.md` Rule 9**: `usize` for collection indexing, array lengths, and buffer allocations; `u32` for domain IDs, token IDs, counters, status codes, and network packet fields.

---

## 2. Test Tier Taxonomy & Architecture

The opaque-box test suite is organized into a four-tier progressive hierarchy:

| Tier | Name | Focus | Minimum Requirement | Milestone Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | **Feature Coverage** | Primary happy-path contracts, CAS deduplication, ingestion staging, recipe filtering, derived weight caching, safe GC, OpenAI and Claude protocols | $\ge 5$ tests per feature ($\ge 35$ total) | US-18 through US-24 |
| **Tier 2** | **Boundary & Corner Cases** | Path traversal, symlink escaping, digest corruption, network aborts, header limits, stale recipe rebuilds, flock/maps GC gates, SSE stream disconnects, queue saturation | $\ge 5$ tests per feature ($\ge 35$ total) | US-18 through US-24 |
| **Tier 3** | **Cross-Feature Interactions** | Pairwise module interactions: CAS deduplication with derived layouts, alias removal with GC, staging with capability filtering, dual OpenAI/Claude front-ends | $\ge 12$ pairwise tests ($\ge 12$ total) | Cross-story interplay |
| **Tier 4** | **Real-World Application Scenarios** | Multi-node Arrow Flight streaming, dual NVMe storage tiering, enterprise OpenAI/Claude agent workflows, cold-boot stale recipe recovery | $\ge 5$ application scenarios ($\ge 5$ total) | Full system orchestration |
| **Total** | | **Comprehensive Test Suite** | **$\ge 87$ test cases** | **Milestone M3** |

---

## 3. Feature Inventory & Specification Mapping

The table below maps all 24 M3 platform features across Tiers 1–3, tracing their authoritative specifications, inputs, outputs, and verification suites:

| # | Feature Name | User Story | Tier 1 (Feature Coverage) | Tier 2 (Boundary & Corner) | Tier 3 (Cross-Feature Interplay) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Content-Addressed Store (CAS)** | US-18 | `test_tier1_us18_cas_deduplication_cross_source` | `test_tier2_us18_corrupted_digest_rejected` | Interplay with US-21: Derived blob points to source digest |
| **2** | **Human-Browsable Alias Hierarchy** | US-18 | `test_tier1_us18_alias_hierarchy_resolution` | `test_tier2_us18_path_traversal_alias_rejected` | Interplay with US-22: Unlinking alias preserves blob |
| **3** | **DuckDB CAS Catalog & Ref Counting** | US-18 | `test_tier1_us18_duckdb_catalog_tracking` | `test_tier2_us18_sql_injection_defense_duckdb` | Interplay with US-22: Ref-count tracks multi-tag ownership |
| **4** | **Configurable Store Root & Tiering** | US-18 | `test_tier1_us18_configurable_store_root_nvme` | `test_tier2_us18_nonexistent_root_create_or_err` | Interplay with US-19: Staging created under secondary root |
| **5** | **Architecture Recipe Capability Filter** | US-20 | `test_tier1_us20_capability_filter_matching_recipe` | `test_tier2_us20_minor_revision_mismatch_qwen3_8` | Interplay with US-19: Verify capability during ingestion |
| **6** | **Tokenizer & Template Alignment** | US-20 | `test_tier1_us20_tokenizer_template_recipe_alignment` | `test_tier2_us20_recipe_tokenizer_mismatch_rejected` | Interplay with US-24: Claude prompts formatted via recipe template |
| **7** | **Derived Weight Layout Caching** | US-21 | `test_tier1_us21_derived_layout_caching_and_reuse` | `test_tier2_us21_corrupt_derived_layout_header` | Interplay with US-18: Derived blob keyed by source digest |
| **8** | **Source Weight Retention Policies** | US-21 | `test_tier1_us21_retention_policy_keep_and_purge` | `test_tier2_us21_zero_delay_immediate_purge` | Interplay with US-22: Purged source marked for GC |
| **9** | **Memory Admission for Derived Layouts** | US-21 | `test_tier1_us21_memory_admission_derived_footprint` | `test_tier2_us21_dual_layout_admission_saturation` | Interplay with US-14: Memory reservation accounts for tiles |
| **10** | **Stale Recipe Detection & Auto-Rebuild** | US-21 | `test_tier1_us21_stale_recipe_auto_rebuild_or_advisory` | `test_tier2_us21_stale_derived_with_purged_original` | Interplay with US-20: Recipe bump triggers stale flag |
| **11** | **Reference-Counted Alias Removal** | US-22 | `test_tier1_us22_alias_removal_preserves_shared_blob` | `test_tier2_us22_double_removal_idempotent` | Interplay with US-18: Multi-tag manifests decrement ref count |
| **12** | **Storage Watermark Monitoring** | US-22 | `test_tier1_us22_storage_watermark_warning_no_autodelete` | `test_tier2_us22_watermark_exact_threshold_boundary` | Interplay with US-19: Watermark warning emitted during pull |
| **13** | **Dual-Gate Safe Storage GC** | US-22 | `test_tier1_us22_dual_gate_safe_gc_flock_and_maps` | `test_tier2_us22_gc_gate1_flock_active_rejection` | Interplay with US-21: GC deletes unreferenced derived layouts |
| **14** | **`k3-store who-uses` & Store CLI** | US-22 | `test_tier1_us22_who_uses_administrative_query` | `test_tier2_us22_who_uses_nonexistent_blob_handled` | Interplay with US-23: Active OpenAI worker reported in who-uses |
| **15** | **Isolated Source Adapter Contract** | US-19 | `test_tier1_us19_source_adapter_lifecycle_contract` | `test_tier2_us19_adapter_invalid_credentials_error` | Interplay with US-20: Search queries inspect recipe support |
| **16** | **Staging & Atomic POSIX Promotion** | US-19 | `test_tier1_us19_staging_and_atomic_promotion` | `test_tier2_us19_interrupted_download_staging_cleanup` | Interplay with US-18: Promoted blob enters CAS store |
| **17** | **Arrow Flight Tensor Batch Streaming** | US-19 | `test_tier1_us19_arrow_flight_tensor_streaming` | `test_tier2_us19_flight_network_interruption_recovery` | Interplay with US-21: Flight streams pre-tiled IME layouts |
| **18** | **Target `memfd` Arena Sealing & IPC** | US-19 | `test_tier1_us19_memfd_arena_sealing_and_mlock` | `test_tier2_us19_memfd_seal_violation_prevention` | Interplay with US-05: SCM_RIGHTS transfers sealed memfd |
| **19** | **OpenAI Protocol `GET /v1/models`** | US-23 | `test_tier1_us23_openai_models_endpoint_unprofiled_tag` | `test_tier2_us23_openai_models_empty_registry` | Interplay with US-07: Unprofiled models flagged in listing |
| **20** | **OpenAI Protocol `POST /v1/chat/completions`**| US-23 | `test_tier1_us23_openai_chat_sync_and_sse_streaming` | `test_tier2_us23_openai_sse_client_early_disconnect` | Interplay with US-13: Streaming receives keep-alives |
| **21** | **OpenAI Queue Feedback & Errors** | US-23 | `test_tier1_us23_openai_queue_feedback_and_429_retry` | `test_tier2_us23_openai_context_overflow_400_error` | Interplay with US-13: Advancing queue position feedback |
| **22** | **Claude Protocol `POST /v1/messages`** | US-24 | `test_tier1_us24_claude_messages_content_blocks` | `test_tier2_us24_claude_invalid_role_sequence_error` | Interplay with US-20: Claude system prompt applied to recipe |
| **23** | **Claude Streaming SSE Event Lifecycle** | US-24 | `test_tier1_us24_claude_streaming_sse_full_lifecycle` | `test_tier2_us24_claude_thinking_delta_reasoning_stream` | Interplay with US-16: Stream resumes after worker crash |
| **24** | **Claude Queue Feedback & Errors** | US-24 | `test_tier1_us24_claude_queue_feedback_and_529_overload`| `test_tier2_us24_claude_context_overflow_invalid_request` | Interplay with US-13: Queue saturation returns HTTP 529 |

---

## 4. Detailed Test Tier Architecture

### 4.1 Tier 1: Feature Coverage (`tests/e2e_m3_storage_test.rs` & `tests/e2e_m3_protocols_test.rs`)

Tier 1 validates primary feature contracts, happy paths, and state transitions across US-18 through US-24:

- **US-18: Content-Addressed Model Store (5 tests)**:
  1. `test_tier1_us18_cas_deduplication_cross_source`: Verifies identical weight bytes pulled from Source A and Source B share a single content-addressed blob.
  2. `test_tier1_us18_alias_hierarchy_resolution`: Verifies human-browsable alias paths `models/<source>/<namespace>/<name>/<tag>` cleanly resolve to manifests and blobs.
  3. `test_tier1_us18_duckdb_catalog_tracking`: Verifies DuckDB catalog schema (`model_blobs`, `model_manifests`, `model_aliases`, `blob_references`) tracking metadata with parameterized queries.
  4. `test_tier1_us18_configurable_store_root_nvme`: Verifies changing store root (`K3_STORE_ROOT`) moves all blobs, manifests, and staging files to the secondary volume.
  5. `test_tier1_us18_model_build_identity_composite`: Verifies canonical model build identity `(blob_digest, recipe_version)` uniquely identifies runnable models.

- **US-19: External Ingestion & Arrow Flight (5 tests)**:
  1. `test_tier1_us19_source_adapter_lifecycle_contract`: Verifies `auth`, `search`, `list`, `pull` lifecycle on isolated source adapter sidecar.
  2. `test_tier1_us19_staging_and_atomic_promotion`: Verifies download to `staging/<uuid>.part`, streaming SHA-256 calculation, and atomic `rename()` promotion into `blobs/`.
  3. `test_tier1_us19_network_credential_isolation`: Verifies scheduler and compute workers possess zero external network credentials or network namespace access.
  4. `test_tier1_us19_arrow_flight_tensor_streaming`: Verifies streaming IME-repacked tensor record batches over Apache Arrow Flight without local target disk writes.
  5. `test_tier1_us19_memfd_arena_sealing_and_mlock`: Verifies receiver creates anonymous `memfd`, calls `mlock()`, applies `F_SEAL_WRITE`, and transfers FD over UDS via `SCM_RIGHTS`.

- **US-20: Architecture Recipe Capability Filter (5 tests)**:
  1. `test_tier1_us20_capability_filter_matching_recipe`: Verifies supported model architectures (e.g. `qwen2.5`) match installed recipes and pass admission.
  2. `test_tier1_us20_upfront_rejection_unsupported_recipe`: Verifies unsupported architectures (e.g. `qwen3.8`) are rejected upfront with `K3Error::CapabilityMismatch` without spawning workers.
  3. `test_tier1_us20_tokenizer_template_recipe_alignment`: Verifies chat template and special tokens are guaranteed aligned with the active architecture recipe.
  4. `test_tier1_us20_candidate_discovery_capability_tagging`: Verifies external search results explicitly flag compatible vs unsupported candidate models.
  5. `test_tier1_us20_quantization_format_support_check`: Verifies unsupported quantization layouts for a recipe fail capability checks upfront.

- **US-21: Derived Weight Layout Caching & Stale Recipe Detection (5 tests)**:
  1. `test_tier1_us21_derived_layout_caching_and_reuse`: Verifies converted/repacked IME tiles are cached under `(source_digest, recipe_version, target_layout)` and reused across model unloads/reloads.
  2. `test_tier1_us21_retention_policy_keep_and_purge`: Verifies operator retention policies (`keep`, `purge_immediate`, `purge_after_delay`) are strictly enforced on original source weights.
  3. `test_tier1_us21_memory_admission_derived_footprint`: Verifies load-time memory admission accounts for both source and derived layouts if simultaneously resident.
  4. `test_tier1_us21_stale_recipe_auto_rebuild_or_advisory`: Verifies recipe version upgrade flags derived blobs as stale, rebuilding if source exists or prompting operator if purged.
  5. `test_tier1_us21_target_layout_enumeration`: Verifies arch recipe declares target layouts (e.g., `rvv_ime_8x16`) and derived cache creates separate artifacts per layout.

- **US-22: Safe Storage Garbage Collection (5 tests)**:
  1. `test_tier1_us22_alias_removal_preserves_shared_blob`: Verifies removing one alias unlinks only its manifest while reference-counted shared blob remains intact.
  2. `test_tier1_us22_storage_watermark_warning_no_autodelete`: Verifies crossing high-water mark emits warning without triggering unapproved automatic deletions.
  3. `test_tier1_us22_dual_gate_safe_gc_flock_and_maps`: Verifies safe GC deletes unreferenced blobs only after passing Gate 1 (`flock`) and Gate 2 (`/proc/*/maps`).
  4. `test_tier1_us22_who_uses_administrative_query`: Verifies `k3-store who-uses <digest>` reports active worker PIDs holding locks or mappings.
  5. `test_tier1_us22_offline_safe_gc`: Verifies GC safety checks operate deterministically even when the `k3-manager` daemon is stopped.

- **US-23: OpenAI-Compatible Protocol Front-End (5 tests)**:
  1. `test_tier1_us23_openai_models_endpoint_unprofiled_tag`: Verifies `GET /v1/models` returns loaded models and tags unprofiled conservative models.
  2. `test_tier1_us23_openai_chat_sync_and_sse_streaming`: Verifies `POST /v1/chat/completions` handles synchronous JSON responses and streaming SSE chunks terminated by `data: [DONE]`.
  3. `test_tier1_us23_openai_tool_calls_passthrough`: Verifies client tool definitions and model `tool_calls` pass through transparently without server execution.
  4. `test_tier1_us23_openai_queue_feedback_and_429_retry`: Verifies streaming requests receive SSE `: keep-alive` and queue positions, and saturated queues return HTTP 429 with `Retry-After`.
  5. `test_tier1_us23_openai_context_overflow_400_error`: Verifies prompts exceeding `n_ctx` return HTTP 400 `context_length_exceeded` without silent truncation.

- **US-24: Anthropic Claude-Compatible Protocol Front-End (5 tests)**:
  1. `test_tier1_us24_claude_messages_content_blocks`: Verifies `POST /v1/messages` translates system prompts, multi-part content blocks, and tool schemas.
  2. `test_tier1_us24_claude_streaming_sse_full_lifecycle`: Verifies complete Anthropic SSE lifecycle: `message_start`, `content_block_start`, `content_block_delta` (`text_delta`), `content_block_stop`, `message_delta`, `message_stop`.
  3. `test_tier1_us24_claude_thinking_delta_reasoning_stream`: Verifies model reasoning generates `content_block_delta` with `thinking_delta` followed by `text_delta`.
  4. `test_tier1_us24_claude_tool_use_passthrough`: Verifies structured `tool_use` content blocks pass through to client without server execution.
  5. `test_tier1_us24_claude_queue_feedback_and_529_overload`: Verifies queued requests receive keep-alives and full queues return HTTP 529 `overloaded_error`.

---

### 4.2 Tier 2: Boundary & Corner Cases (`tests/e2e_m3_storage_test.rs` & `tests/e2e_m3_protocols_test.rs`)

Tier 2 exercises adversarial boundaries, resource stress, and failure cascading across all features:

- **US-18 Boundaries (5 tests)**:
  1. `test_tier2_us18_path_traversal_alias_rejected`: Rejects attempts to create aliases containing `../`, leading `/`, or null bytes.
  2. `test_tier2_us18_corrupted_digest_rejected`: Fails registration if calculated SHA-256 does not match declared digest.
  3. `test_tier2_us18_sql_injection_defense_duckdb`: Enforces parameterized statements; attempts to inject SQL via model names (`'; DROP TABLE model_blobs; --`) are safely quoted.
  4. `test_tier2_us18_empty_blob_registration_rejected`: Rejects zero-byte blob registration.
  5. `test_tier2_us18_nonexistent_root_create_or_err`: Handles missing store root paths gracefully, creating directory tree with secure permissions (`0750`).

- **US-19 Boundaries (5 tests)**:
  1. `test_tier2_us19_interrupted_download_staging_cleanup`: Simulates network abort during staging; verifies partial `.part` file is deleted and never promoted.
  2. `test_tier2_us19_corrupted_format_header_rejected`: Detects corrupted GGUF/SafeTensors magic header in staging and aborts promotion.
  3. `test_tier2_us19_adapter_invalid_credentials_error`: Simulates external 401 Unauthorized; returns structured error without storing secrets in logs.
  4. `test_tier2_us19_flight_network_interruption_recovery`: Arrow Flight stream broken mid-batch triggers clean receiver teardown without unpinned memory leaks.
  5. `test_tier2_us19_memfd_seal_violation_prevention`: Verifies attempting to write to `F_SEAL_WRITE` sealed `memfd` returns `EPERM`.

- **US-20 Boundaries (5 tests)**:
  1. `test_tier2_us20_minor_revision_mismatch_qwen3_8`: Validates that minor algorithmic drift (e.g. `qwen3` vs `qwen3.8`) is caught and rejected as distinct recipe.
  2. `test_tier2_us20_missing_quantization_kernel_rejected`: Rejects quantization format not supported by the recipe's RVV kernels.
  3. `test_tier2_us20_malformed_manifest_json_rejected`: Rejects corrupted or non-UTF-8 manifest JSON payloads with clear syntax diagnostics.
  4. `test_tier2_us20_recipe_tokenizer_mismatch_rejected`: Rejects model loading if chat template defines special tokens unknown to `k3-tokenizer`.
  5. `test_tier2_us20_recipe_version_downgrade_handling`: Prevents loading models with newer recipe version than supported by running engine.

- **US-21 Boundaries (5 tests)**:
  1. `test_tier2_us21_stale_derived_with_purged_original`: Stale derived blob whose original source was purged emits actionable operator notification to re-acquire.
  2. `test_tier2_us21_zero_delay_immediate_purge`: Verifies `purge_immediate` deletes source bytes immediately upon derived blob promotion.
  3. `test_tier2_us21_dual_layout_admission_saturation`: Verifies memory admission rejects loading second layout if total footprint exceeds `RLIMIT_MEMLOCK`.
  4. `test_tier2_us21_corrupt_derived_layout_header`: Detects damaged tile headers in cached derived blob and forces automatic re-conversion.
  5. `test_tier2_us21_concurrent_rebuild_requests_dedup`: Multiple simultaneous requests for a stale model trigger a single rebuild task.

- **US-22 Boundaries (5 tests)**:
  1. `test_tier2_us22_gc_gate1_flock_active_rejection`: GC skips blob when worker holds `flock(LOCK_SH)`, reporting `InUseByLock`.
  2. `test_tier2_us22_gc_gate2_maps_active_rejection`: GC skips blob when worker maps file in `/proc/*/maps`, reporting `InUseByMapping`.
  3. `test_tier2_us22_watermark_exact_threshold_boundary`: Verifies warning emits at exactly `used_bytes >= high_water_bytes` and clears below threshold.
  4. `test_tier2_us22_who_uses_nonexistent_blob_handled`: Querying `who-uses` on an unknown digest returns clean `NotFound` error without crashing.
  5. `test_tier2_us22_dry_run_gc_idempotence`: Verifies dry-run GC reports eligible bytes without unlinking files.

- **US-23 Boundaries (5 tests)**:
  1. `test_tier2_us23_openai_sse_client_early_disconnect`: Client disconnect during SSE stream aborts forward pass without leaking worker resources.
  2. `test_tier2_us23_openai_empty_tool_definitions`: Request with empty `tools: []` executes standard text completion without error.
  3. `test_tier2_us23_openai_prompt_exactly_n_ctx`: Prompt whose length equals `n_ctx` is rejected (requires at least 1 slot for generation).
  4. `test_tier2_us23_openai_malformed_json_body_400`: Malformed JSON request body returns HTTP 400 Bad Request with descriptive parsing error.
  5. `test_tier2_us23_openai_queue_saturation_retry_after_header`: Verifies HTTP 429 response includes well-formed `Retry-After: 5` header.

- **US-24 Boundaries (5 tests)**:
  1. `test_tier2_us24_claude_thinking_delta_empty_text`: Handles reasoning-only completion (`thinking_delta` blocks without `text_delta`).
  2. `test_tier2_us24_claude_multi_block_mixed_content`: Handles request containing mixed text, system instructions, and tool definitions.
  3. `test_tier2_us24_claude_invalid_role_sequence_error`: Requests with invalid turn ordering (e.g. consecutive user turns) return HTTP 400.
  4. `test_tier2_us24_claude_context_overflow_invalid_request`: Context overflow returns standard Anthropic JSON error `{ type: "error", error: { type: "invalid_request_error", ... } }`.
  5. `test_tier2_us24_claude_queue_saturation_529_body`: Admission queue cap returns HTTP 529 `{ type: "error", error: { type: "overloaded_error", ... } }`.

---

### 4.3 Tier 3: Cross-Feature Interactions (`tests/e2e_m3_scenarios_test.rs`)

Tier 3 exercises pairwise interactions between distinct subsystems:

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

---

### 4.4 Tier 4: Real-World Application Scenarios (`tests/e2e_m3_scenarios_test.rs`)

Tier 4 exercises production-grade end-to-end workflows representing real deployment topologies on the K3 platform:

1. **Scenario 1: Multi-Model Storage Lifecycle with Dual-Tier NVMe Storage & Shared Weights**
   - Configures secondary NVMe store root (`/mnt/nvme/k3`).
   - Registers two distinct model tags (`v1` and `v2`) sharing identical base weight blobs.
   - Generates derived IME tile layouts for SpacemiT A100 matrix cores.
   - Removes tag `v1`; executes safe GC; confirms base weights remain intact for `v2`.
   - Removes tag `v2`; executes safe GC; confirms full reclamation.

2. **Scenario 2: Remote Accelerator Node Provisioning via Arrow Flight Streaming into RAM `memfd`**
   - Head node ingests model weights, executes capability filtering, and repacks tensors.
   - Streams pre-tiled tensor record batches to remote K3 accelerator node via Apache Arrow Flight.
   - Receiving node constructs anonymous `memfd`, calls `mlock()`, applies `F_SEAL_WRITE`, and transfers FD over UDS via `SCM_RIGHTS`.
   - Zero flash disk writes occur on the target accelerator node.

3. **Scenario 3: Production OpenAI Client Application with SSE Streaming, Tool Calling & Queue Feedback**
   - Client connects to `POST /v1/chat/completions` requesting tool use.
   - Request enters admission queue; client receives SSE `: keep-alive` and advancing `: queue_position` notifications.
   - Model generates tool invocation; front-end formats structured `tool_calls` payload without server-side tool execution.
   - Client submits tool output; model streams final answer tokens terminated by `data: [DONE]`.

4. **Scenario 4: Autonomous Coding Agent with Anthropic Claude Protocol, Reasoning Blocks & Tool Use**
   - Developer agent connects to `POST /v1/messages` targeting reasoning-capable local model.
   - Model streams reasoning tokens via `content_block_delta` with `thinking_delta`.
   - Model transitions to final answer text via `content_block_delta` with `text_delta`.
   - Emits well-formed Anthropic event lifecycle: `message_start` through `message_stop`.

5. **Scenario 5: High-Density Edge Gateway Cold Boot, Stale Recipe Migration & Safe Background GC**
   - Edge gateway boots up with existing cached derived blobs from prior runtime version.
   - Runtime detects breaking recipe upgrade; flags cached derived layout as stale.
   - Automatically rebuilds derived blob from retained source weights.
   - Background GC service verifies no active workers hold `flock` or `/proc/*/maps` mappings before sweeping obsolete artifacts.

---

## 5. Conservative Resource Bounds & Execution Invariants

All M3 test suites strictly adhere to workspace invariants:

1. **`AGENTS.md` Rule 5: Conservative Memlock Bounds**:
   - Test placements configure `n_ctx: 64` (requiring ~64 KB KV cache footprint).
   - Test synthetic weight artifacts are kept compact ($\le 64 \text{ KB}$) so memory admission succeeds in unprivileged environments without `RLIMIT_MEMLOCK` exhaustion.

2. **`AGENTS.md` Rule 9: Rust `usize` vs `u32`**:
   - `usize`: Collection indexing, slice offsets, buffer lengths, memory allocations, `n_ctx`.
   - `u32`: Token IDs, domain IDs, process IDs, status codes, retry intervals, network ports.

3. **DuckDB Parameterized Queries**:
   - All catalog operations use parameterized prepared statements (`duckdb::params!`), completely eliminating SQL injection risks.

---

## 6. How to Run the M3 Test Suites

Run from `/Users/lma1980/repository/model-runner/code`:

```bash
# Storage Lifecycle Suite: US-18, US-20, US-21, US-22 (Tiers 1 & 2: 40 tests)
cargo test -p k3-manager --test e2e_m3_storage_test

# External Protocols & Ingestion Suite: US-19, US-23, US-24 (Tiers 1 & 2: 30 tests)
cargo test -p k3-manager --test e2e_m3_protocols_test

# Scenarios & Cross-Feature Suite: Tiers 3 & 4 (17 tests)
cargo test -p k3-manager --test e2e_m3_scenarios_test

# Run All M3 E2E Test Suites (87 tests)
cargo test -p k3-manager \
    --test e2e_m3_storage_test \
    --test e2e_m3_protocols_test \
    --test e2e_m3_scenarios_test
```
