# Codebase Concerns

**Analysis Date:** 2026-01-25

## Security Considerations

**API Key Encryption Using Base64 (NOT SECURE):**
- Risk: API keys stored in database are encoded with base64 only, which is trivially decodable. Provides no security for encrypted API keys.
- Files: `packages/backend/src/middleware/encryption.ts`, `packages/backend/src/services/generation/llm-client.ts`
- Current mitigation: Comments acknowledge this is development-only; marked as TODO
- Recommendations:
  - Implement AES-256-GCM encryption before production deployment
  - Store encryption key in environment variable (`ENCRYPTION_KEY`)
  - Consider using AWS KMS, HashiCorp Vault, or node:crypto with proper key rotation
  - Add immediate blocking issue if any production deployment is attempted

**Insufficient Input Validation on Dynamic Enum Casting:**
- Risk: Multiple `as any` type assertions bypass TypeScript validation when casting string inputs to enums, potentially allowing invalid enum values into database queries
- Files: `packages/backend/src/routes/nodes.ts` (lines 90, 93), `packages/backend/src/routes/config.ts` (lines 31, 66, 90, 126, 138, 150), `packages/backend/src/routes/config-advanced.ts` (lines 108, 190, 210)
- Current mitigation: Zod schemas validate at API boundary, but raw enum casting bypasses this
- Recommendations:
  - Replace `as any` assertions with runtime validation using Zod's enum types
  - Create helper function for enum validation before database queries
  - Consider stricter TypeScript strict mode settings

**Unencrypted Credentials in Environment:**
- Risk: Encryption key (`ENCRYPTION_KEY`) would be stored in plain text in environment variables
- Files: `packages/backend/src/middleware/encryption.ts` (line 39 TODO)
- Current mitigation: Environment variables are typically protected in production platforms
- Recommendations:
  - Document that encryption key must never be committed to version control
  - Use secrets management service in production
  - Add pre-commit hooks to prevent .env files from being committed

## Tech Debt

**System Prompts Hardcoded in Service Files:**
- Issue: AI generation system prompts are embedded directly in service modules instead of being centralized
- Files: `packages/backend/src/services/generation/beat-outliner.ts`, `packages/backend/src/services/generation/prose-expander.ts`, `packages/backend/src/services/generation/critic.ts`
- Impact: Difficult to maintain consistency, update all prompts at once, or version control prompt changes separately
- Fix approach: Move all system prompts to `packages/shared/src/constants/prompts.ts` (Phase 4 TODO noted in README)

**Duplicate Node Data Assembly Pattern:**
- Issue: Node data object construction is duplicated in two places with identical field mapping
- Files: `packages/backend/src/routes/generate.ts` (lines 40-76 and 125-161, both creating nodeData objects)
- Impact: Changes to node structure require updates in two places; risk of drift and inconsistency
- Fix approach: Extract into `buildNodeDataFromRequest()` helper function in a new `packages/backend/src/utils/node-builder.ts`

**Multiple Type Assertions with `as any`:**
- Issue: 40+ instances of `as any` type assertions throughout backend routes
- Files: `packages/backend/src/db/seed.ts` (10 instances), `packages/backend/src/routes/config-advanced.ts` (8 instances), `packages/backend/src/routes/config.ts` (30+ instances), `packages/backend/src/routes/nodes.ts` (4 instances)
- Impact: Bypasses TypeScript safety, makes refactoring risky, masks type errors
- Fix approach: Create discriminated union helper types for enum values; add stricter type guards

**Missing Gap Analysis Implementation:**
- Issue: Distribution gap analysis is stubbed out but not implemented
- Files: `packages/frontend/src/hooks/useGeneration.ts` (line 146 TODO), `packages/backend/src/routes/generate.ts` (line 191 TODO)
- Impact: Bulk generation feature cannot recommend what nodes are missing to hit target distributions
- Fix approach: Implement backend endpoint `/api/gaps` that calculates current vs. target distribution, then consume in frontend hook

**Incomplete Bulk Generation Feature:**
- Issue: Bulk generation UI shows TODO comment indicating feature is not fully implemented
- Files: `packages/frontend/src/components/generation/BulkGenerate.tsx` (line 83 TODO)
- Impact: Users cannot actually perform bulk generation as designed in UI
- Fix approach: Complete backend bulk generation endpoint and wire up frontend UI component

**Shared Prompts Not in Shared Package:**
- Issue: AI system prompts should be accessible to CLI as well, but are only in backend
- Files: `packages/backend/src/services/generation/README.md` (line 188 TODO Phase 4)
- Impact: CLI cannot reuse same prompts, leading to inconsistent AI behavior between web and CLI
- Fix approach: Move prompts to `packages/shared/src/constants/` and import in both backend and CLI

## Performance Bottlenecks

**N+1 Query Pattern in Node ID Generation:**
- Problem: Generating node IDs requires fetching all existing nodes matching prefix pattern to find max suffix
- Files: `packages/backend/src/routes/nodes.ts` (lines 51-70)
- Cause: Uses JavaScript to find max instead of SQL MAX() function; iterates all results in application code
- Improvement path: Replace with SQL: `SELECT COALESCE(MAX(CAST(SUBSTRING(...) AS INTEGER)), 0) FROM nodes`

**Full Table Scans in Lookups:**
- Problem: Many config endpoints perform unindexed queries on large lookup tables
- Files: `packages/backend/src/routes/config.ts`, `packages/backend/src/routes/config-advanced.ts`
- Cause: Conditional SELECT queries without indexes on filter columns (biome, nodeType, etc.)
- Improvement path:
  - Add database indexes: `CREATE INDEX idx_enemy_types_biome ON enemy_types(biome);` etc.
  - Implement caching layer in memory or Redis for rarely-changing lookup data
  - Pre-load config at startup into application memory

**No Pagination on List Endpoints:**
- Problem: Node list endpoint has pagination (limit/offset), but many config endpoints return all rows
- Files: `packages/backend/src/routes/config.ts` (lines 24, 42, 64, 76, etc.), `packages/backend/src/routes/config-advanced.ts` (lines 34, 230, 355)
- Cause: Assumes lookup tables are small, but could grow unbounded
- Improvement path: Add limit/offset to all list endpoints; implement cursor-based pagination for large result sets

**Batch Processing Concurrency Default:**
- Problem: Default batch size of 5 concurrent LLM requests may be too conservative or too aggressive depending on rate limits
- Files: `packages/backend/src/services/generation/batch-processor.ts`, documented in README
- Impact: Could under-utilize API allowances or risk rate limit errors
- Improvement path: Make batch size configurable per provider; add adaptive batch sizing based on response times

## Fragile Areas

**Complex Eligibility Expression Tree:**
- Files: `packages/frontend/src/components/forms/EligibilityBuilder.tsx` (780 lines)
- Why fragile:
  - Deeply nested type union handling (Condition vs. allOf/anyOf/noneOf wrappers)
  - Multiple helper functions with conditional logic (isCondition, isWrapper, getWrapperType, getWrapperChildren)
  - Large AddConditionDialog with 8 different condition kind branches and ~30 useState calls
  - TypeScript casting assertions on line 252, 259 that could break with schema changes
- Safe modification:
  - Add comprehensive unit tests for tree traversal operations
  - Extract condition building logic into separate hook (useEligibilityExpression)
  - Consider extracting AddConditionDialog to its own file with factory functions per condition type
- Test coverage: No test files found for this component; high priority for unit tests

**Frontend Form Wizard State Management:**
- Files: `packages/frontend/src/store/form-store.ts`, `packages/frontend/src/routes/nodes/create.tsx`, `packages/frontend/src/routes/nodes/edit.tsx`
- Why fragile:
  - Multi-step form accumulates data across 5 steps, stored in Zustand
  - Step transitions don't validate intermediate state, only final validation
  - Reset behavior on error might not clear all state branches
- Safe modification:
  - Add per-step validation hooks that run before advancing
  - Document state flow in form-store.ts
  - Add defensive checks in each step component
- Test coverage: Zero test coverage for form state management

**Database Single-Table Design with Many Nullable Fields:**
- Files: `packages/backend/src/db/schema.ts` (nodes table with 40+ nullable type-specific fields)
- Why fragile:
  - Adding new node type requires modifying nodes table with new nullable columns
  - No database-level constraint that ensures only relevant fields are populated for each type
  - Easy to accidentally set wrong type-specific fields for a node
  - Row size grows with each new node type
- Safe modification:
  - Before adding new node types, verify migration strategy won't cause locked table during large dataset changes
  - Consider adding CHECK constraint: `CHECK ((type = 'combat' AND enemy_type_hooks IS NOT NULL) OR type != 'combat')`
  - Document which fields apply to which node types in schema comments
- Test coverage: No migration tests; database schema changes only tested manually

**LLM Provider Configuration Race Condition:**
- Files: `packages/backend/src/services/generation/llm-client.ts`, `packages/backend/src/routes/llm-providers.ts`
- Why fragile:
  - Fetches active provider on each generation request without caching
  - If multiple requests run concurrently while provider is being updated, could get inconsistent state
  - No transactional consistency when switching between providers
- Safe modification:
  - Cache active provider with TTL (e.g., 60 seconds)
  - Add version number to provider config; invalidate cache on update
  - Consider adding application-level lock if provider update needs to be atomic
- Test coverage: No tests for concurrent provider updates

**Error Handling Consistency:**
- Files: Throughout backend routes
- Why fragile:
  - Mix of console.error calls without context; some routes log, others silent
  - Error responses vary: some 500, some pass through with raw error messages
  - Streaming responses catch errors but might send malformed SSE events
- Safe modification:
  - Create ErrorResponse builder to standardize error format
  - Add request ID to all error logs for tracing
  - Test error scenarios explicitly: missing config, invalid input, provider failure
- Test coverage: Zero test coverage for error paths

## Test Coverage Gaps

**No Integration Tests for Generation Pipeline:**
- What's not tested: Complete flow from HTTP request → beat outliner → prose expander → critic → database save
- Files: `packages/backend/src/services/generation/`, `packages/backend/src/routes/generate.ts`
- Risk: Breaking changes to stage interfaces or data passing could go undetected
- Priority: High - generation is core feature

**No Mock LLM Tests:**
- What's not tested: Retry logic, timeout handling, rate limit responses, malformed JSON responses
- Files: `packages/backend/src/services/generation/llm-client.ts`
- Risk: Production could fail with unexpected LLM provider responses
- Priority: High - external dependency resilience is critical

**No Frontend Component Tests:**
- What's not tested: Form submission flows, state transitions, error display, SSE streaming updates
- Files: `packages/frontend/src/components/forms/`, `packages/frontend/src/routes/`
- Risk: UI bugs not caught until manual testing; regressions with dependency updates
- Priority: Medium - most feature delivery happens through UI

**No Database Concurrency Tests:**
- What's not tested: Simultaneous updates to same node, provider switching during generation, migration under load
- Risk: Concurrency bugs only appear in production or under load
- Priority: Medium - affects multi-user scenarios

**No Batch Processor Tests:**
- What's not tested: Concurrency limits, retry logic, partial failures, progress callback timing
- Files: `packages/backend/src/services/generation/batch-processor.ts`
- Risk: Bulk generation could fail silently or hang
- Priority: Medium - bulk operations are user-facing

**No Search Implementation:**
- What's not tested: Node search endpoint exists but has no implementation
- Files: `packages/backend/src/routes/search.ts`
- Risk: Search endpoint returns wrong/empty results when called
- Priority: Medium - feature not yet used but will break when someone tries it

## Missing Critical Features

**Distribution Gap Analysis:**
- Problem: Cannot recommend which nodes to generate to meet target distributions
- Blocks: Bulk generation feature; intelligent generation recommendations
- Design needed: Algorithm to calculate shortfalls per (biome, node_type) combination

**Search Functionality:**
- Problem: Search endpoint exists in API but no implementation
- Blocks: Users cannot find nodes by content/name
- Design needed: Full-text search on node name and narrative content

**Critic-Only Validation Mode:**
- Problem: Cannot run existing content through critic without regenerating
- Blocks: Bulk validation of existing nodes; quality assessment
- Design needed: Endpoint to score content without regeneration

## Scaling Limits

**Single PostgreSQL Database:**
- Current capacity: Estimated 10k-100k nodes before query performance degrades
- Limit: Read replicas not configured; concurrent generation requests share single DB connection
- Scaling path:
  - Add read replicas for config lookups
  - Implement connection pooling (PgBouncer)
  - Consider sharding by biome if >1M nodes needed

**LLM Provider Rate Limits Not Tracked:**
- Current capacity: Batch processor respects configurable concurrency but doesn't track actual rate limits per provider
- Limit: Could hit provider rate limits and fail silently or with generic errors
- Scaling path:
  - Implement request queue with rate limit aware scheduling
  - Track per-provider rate limit headers (X-RateLimit-Remaining)
  - Add exponential backoff with jitter for rate limit 429 responses

**Memory Usage of Batch Processing:**
- Current capacity: 5 concurrent requests × avg content size could consume 50MB+ for in-memory buffering
- Limit: Large batches could cause OOM on smaller servers
- Scaling path:
  - Implement streaming results instead of buffering all in memory
  - Store intermediate results in temporary database table instead of memory
  - Add configurable memory threshold for adaptive batch sizing

## Dependencies at Risk

**System Prompts Embedded (Not Versioned):**
- Risk: Prompt changes not tracked in git; different services could have different versions
- Impact: Inconsistent AI output between web interface and CLI
- Migration plan: Extract all prompts to shared constants package with version field

**Base64 Encryption in Production:**
- Risk: Complete loss of security for stored API keys if base64 "encryption" is deployed to production
- Impact: Any database breach exposes all connected LLM provider credentials
- Migration plan: Immediate security audit before production; implement AES-256-GCM; rotate all provider credentials after deployment

**Hard-Coded Provider Temperature Values:**
- Risk: Temperature values (heat parameter) have no validation; magic numbers like 70 (interpreted as 0.7) in database
- Impact: Inconsistent generation quality; confusing API contract
- Migration plan: Normalize temperature to 0.0-1.0 range; add schema validation

---

*Concerns audit: 2026-01-25*
