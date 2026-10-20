# US-24: Anthropic Claude-Compatible Client Protocol Front-End

- **Milestone**: [M3: Storage Lifecycle & External Protocols](milestone-03.us-index.md)
- **Status**: Active
- **GitHub Issue**: [#24](https://github.com/LMA1980/model-runner/issues/24)
- **Feature Ref**: [Dual API & Front-End Extensions](../features/api-compat.md)
- **Spec Ref**: [Claude API Adapter](../specs/api/claude.md), [Front-End & Source Extensions](../specs/api/extensions.md)
- **Related ADRs**: [ADR-015](../decisions/ADR-015-admission-queue.md), [ADR-019](../decisions/ADR-019-extensions.md), [ADR-020](../decisions/ADR-020-mcp.md), [ADR-021](../decisions/ADR-021-http.md), [ADR-027](../decisions/ADR-027-context-window.md), [ADR-041](../decisions/ADR-041-isolation-domains.md)

## Narrative

**As an** AI Application Developer,
**I want** to connect Anthropic Claude-compatible SDKs and coding agents to the runtime via `/v1/messages` with full support for streaming lifecycle events, reasoning/thinking blocks, and pass-through tool declarations,
**So that** Claude-native workflows and developer tools can run seamlessly against local models on the board with full protocol fidelity and network sandboxing.

## Business Context & Domain Rules

- Like all external protocol adapters, the Anthropic Claude front-end runs as an isolated edge extension that holds network access while keeping the core control plane, context memory, and compute workers strictly off the network.
- The front-end translates incoming Claude messages requests (`/v1/messages`, including system instructions, multi-part content blocks, and tool schemas) into the runtime's canonical prompt representation.
- For streaming requests, the adapter emits the complete sequence of Anthropic streaming events (`message_start`, `content_block_start`, `content_block_delta` for both text and thinking deltas, `content_block_stop`, `message_delta`, and `message_stop`), interspersed with keep-alive notifications while queued.
- When a model's admission queue reaches its configured cap, the adapter emits status `529` (`overloaded_error`); when a prompt exceeds the model's fixed context window, it returns an explicit invalid-request context overflow error.

## Core System Assertions

- **Scenario 1: Full Claude streaming event lifecycle and thinking blocks**
  - **Given** a Claude-compatible client sends a streaming request to `/v1/messages` targeting a reasoning-capable local model,
  - **When** the model generates reasoning steps followed by final answer text,
  - **Then** the front-end emits well-formed `message_start`, `content_block_start`, `content_block_delta` (`thinking_delta` and `text_delta`), `content_block_stop`, `message_delta`, and `message_stop` events matching the Anthropic protocol specification.
- **Scenario 2: Tool declaration and tool-use content block pass-through**
  - **Given** a `/v1/messages` request containing client-defined tool schemas,
  - **When** the model emits a tool invocation during generation,
  - **Then** the front-end formats and returns the structured `tool_use` content block directly to the client without attempting server-side tool execution.
- **Scenario 3: Protocol-native overload and context-overflow error handling**
  - **Given** a `/v1/messages` request that either exceeds the target model's configured context window or arrives when the model's admission queue is full,
  - **When** the front-end evaluates admission,
  - **Then** it returns an invalid-request error on context overflow (without silent truncation) or HTTP `529` (`overloaded_error`) when the queue cap is reached.
