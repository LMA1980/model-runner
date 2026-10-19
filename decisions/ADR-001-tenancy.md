# ADR-001: Tenancy

**Status**: Locked

## Context
session-mgmt.md mentioned tenants and per-project budgets while the product targets a single 32GB board.

## Decision
Single tenant in v1. Hierarchy: **Tenant → Project → Sessions**. Data model must be multi-tenant-ready. User/group scopes come later.

## Consequences
Every schema keys on tenant_id/project_id from day one; v1 ships a single tenant/project.
