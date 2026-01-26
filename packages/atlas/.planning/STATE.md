# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Generate complete, high-quality narrative nodes with minimal manual effort through AI-powered content creation
**Current focus:** Phase 6 - Field-Level Assists

## Current Position

Phase: 6 of 9 (Field-Level Assists)
Plan: 1 of 3 in current phase
Status: In progress
Last activity: 2026-01-26 — Completed 06-01-PLAN.md (Field Generation API)

Progress: [██████████░] 90%

## Performance Metrics

**Velocity:**
- Total plans completed: 9
- Average duration: 3.3 minutes
- Total execution time: 0.5 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 - Streaming Foundation | 1 | 5 min | 5 min |
| 2 - Core Generation Pipeline | 3 | 9 min | 3 min |
| 3 - Quality Control | 2 | 8 min | 4 min |
| 4 - Frontend Streaming Client | 1 | 3 min | 3 min |
| 5 - Single-Node Generation UI | 1 | 5 min | 5 min |
| 6 - Field-Level Assists | 1 | 3 min | 3 min |

**Recent Trend:**
- Last 5 plans: 03-02 (6m), 04-01 (3m), 05-01 (5m), 06-01 (3m)
- Trend: Stable velocity (avg 4.25 min/plan over last 4)

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Single-table node design: All 7 node types in one table with nullable type-specific fields (Pending)
- 3-stage generation pipeline: Beat outline → prose expand → critic ensures quality (Pending)
- OpenRouter as primary provider: Access to multiple models including Claude Sonnet 4 (Pending)
- SSE for streaming: Real-time progress updates without polling (Implemented - 01-01)
- Brownfield completion approach: Fix integration issues rather than rewrite (Pending)
- Job persistence (24hr): Balance reconnection support with database cleanup (01-01)
- Heartbeat interval (12s): Prevents proxy timeouts without excessive traffic (01-01)
- Error classification: Structured classification with 10+ error types and user-friendly messages (02-02)
- Circuit breaker thresholds: 50% error rate in 10s window with 5 request minimum (02-01)
- LLM timeout: 60s accommodates slow responses without premature failures (02-01)
- Auto-recovery: 30s cooldown balances downtime vs provider recovery (02-01)
- Jitter in retry: 0-1000ms random jitter prevents thundering herd (02-02)
- Database save error isolation: Generation succeeds even if save fails (02-03)
- crypto.randomUUID for node IDs: Built-in Bun API, no external dependency (02-03)
- Quality retry limit: 2 retries (3 total attempts) balances quality improvement vs generation time (03-01)
- Validation gates quality retry: validation.success required before considering score-based retry (03-01)
- Best attempt tracking: Return highest-scoring attempt on quality retry exhaustion (03-01)
- Type extraction from schemas: Use indexed access types to derive types from schema arrays (03-02)
- Backward compatibility in UI: Keep fallback displays when migrating to richer components (03-02)
- Compact mode default: Use space-efficient compact mode for embedded component displays (03-02)
- Job age threshold (60min): Reconnection attempts only for jobs <60min old to balance recovery vs stale cleanup (04-01)
- State persistence partialize: Only persist activeJob, not ephemeral connectionAttempts (04-01)
- Reconnection backoff: 1s initial, 30s max, 2x multiplier with 0-30% jitter prevents thundering herd (04-01)
- Frontend job persistence (24hr): Matches backend retention, enables reconnection after disconnect (04-01)
- Reconnection age threshold (60min): Balance recovery vs stale job cleanup (04-01)
- Exponential backoff parameters: 1s initial, 30s max, 2x multiplier, 0-30% jitter for reconnection (04-01)
- Partialize Zustand persist: Only persist activeJob, not ephemeral connectionAttempts (04-01)
- Type-specific defaults: Provide minimal type-specific fields for quick generation without manual input (05-01)
- Toast feedback pattern: Use sonner for success/error/info notifications (05-01)
- Fresh form values on retry: handleRetry re-submits current form values instead of captured values (05-01)
- Threshold visibility: Explicitly pass threshold=70 to GenerationProgress for clarity (05-01)
- Field-level streaming: Text fields (narrative_hook, beat) use SSE streaming for real-time feedback (06-01)
- Non-streaming for structured data: beat-list returns complete JSON array, not streamed (06-01)
- Direct LLM calls for fields: Bypass 3-stage pipeline for faster targeted generation (06-01)
- Beat role guidance: Embed role descriptions in system prompts for context-aware generation (06-01)

### Pending Todos

None yet.

### Blockers/Concerns

**Current blockers:**
- ~~Streaming SSE not wired up frontend-to-backend~~ (RESOLVED in 01-01)
- ~~Generation service files exist but aren't integrated with API routes~~ (RESOLVED in 01-01)
- ~~Database save on stream completion: Streaming endpoint doesn't persist to nodes table yet~~ (RESOLVED in 02-03)
- ~~Frontend generation state persistence and reconnection~~ (RESOLVED in 04-01)
- ~~Frontend generation UI components exist but hooks don't call working endpoints~~ (RESOLVED in 05-01)
- Cleanup job scheduler: `cleanupOldJobs()` exists but not scheduled (low priority)

**From research:**
- Phase 3: Critic scoring rubric calibration per node type requires domain expertise
- Phase 7: Optimal concurrency levels depend on OpenRouter tier and rate limits
- Pre-existing type errors in config-advanced.ts, llm-providers.ts need cleanup (low priority, streaming.ts fixed in 02-03)

## Session Continuity

Last session: 2026-01-26 (Phase 6 execution in progress)
Stopped at: Completed 06-01-PLAN.md (Field Generation API)
Resume file: None
