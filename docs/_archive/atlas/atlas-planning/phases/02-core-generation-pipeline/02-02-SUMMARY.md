---
phase: 02-core-generation-pipeline
plan: 02
subsystem: api
tags: [error-handling, llm, retry-logic, jitter, sse, user-experience]

# Dependency graph
requires:
  - phase: 02-core-generation-pipeline-01
    provides: Circuit breaker protection with completeWithCircuitBreaker
  - phase: 01-streaming-foundation
    provides: SSE streaming infrastructure
provides:
  - Structured error classification with user-friendly messages
  - Retry logic with exponential backoff and jitter
  - SSE error events with actionable user guidance
affects: [03-critic-scoring, 04-frontend-integration, 07-batch-orchestration]

# Tech tracking
tech-stack:
  added: []
  patterns: [error-classification, exponential-backoff-with-jitter, user-friendly-errors]

key-files:
  created:
    - packages/backend/src/services/generation/error-handler.ts
  modified:
    - packages/backend/src/services/generation/llm-client.ts
    - packages/backend/src/services/generation/streaming.ts
    - packages/backend/src/services/generation/index.ts

key-decisions:
  - "Error classification replaces inline string matching for better maintainability"
  - "Jitter (0-1000ms random) prevents thundering herd when many requests retry simultaneously"
  - "User-friendly messages guide users to actionable fixes (check API key, adjust config, wait 30s)"
  - "Circuit breaker errors explicitly tell users to wait 30 seconds"

patterns-established:
  - "classifyLLMError centralizes all error detection logic in one module"
  - "SSE error events include both userMessage (for UI display) and technicalMessage (for debugging)"
  - "Retry decisions based on classified.retryable flag, not string matching"

# Metrics
duration: 2min
completed: 2026-01-25
---

# Phase 02 Plan 02: Enhanced Error Handling Summary

**Structured error classification with user-friendly messages and jitter-based retry logic ensures users receive actionable guidance when generation fails**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-25T08:15:03Z
- **Completed:** 2026-01-25T08:18:02Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Created comprehensive error classification module with 10+ error types
- Replaced string matching with structured error classification in retry logic
- Added 0-1000ms jitter to exponential backoff preventing thundering herd
- SSE error events now include user-friendly messages for all error scenarios
- GEN-04 requirement satisfied: Users receive actionable error messages
- ERR-02 requirement satisfied: Exponential backoff with proper jitter implementation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create error handler module with classification** - `a1aa172` (feat)
2. **Task 2: Update retry logic with jitter and error classification** - `5751417` (feat)
3. **Task 3: Update SSE streaming with user-friendly error messages** - `83115ff` (feat)

## Files Created/Modified
- `packages/backend/src/services/generation/error-handler.ts` - Comprehensive error classification with classifyLLMError (10+ error types) and calculateRetryDelay (exponential backoff + jitter)
- `packages/backend/src/services/generation/llm-client.ts` - Updated completeWithRetry to use classifyLLMError for retry decisions and calculateRetryDelay for backoff
- `packages/backend/src/services/generation/streaming.ts` - Replaced isRetryableError with classifyLLMError, added userMessage/technicalMessage/httpStatus to SSE error events
- `packages/backend/src/services/generation/index.ts` - Re-exported error handler functions for use in other modules

## Decisions Made

**Error classification categories (10 types):**
- **Non-retryable auth/config:** 401 Unauthorized, 403 Forbidden, 400 Bad Request, Content Filter, No Active Provider, Circuit Breaker Open
- **Retryable transient:** 429 Rate Limit, 503 Service Unavailable, 529 Overloaded (Anthropic-specific), Network/Timeout errors
- **Default:** Unknown errors treated as non-retryable to prevent runaway costs

**User messages provide actionable guidance:**
- Auth errors → "Check your API key in Settings > LLM Providers"
- Bad request → "Check your node configuration and try again"
- Circuit breaker → "Wait 30 seconds and try again"
- Rate limit → "Automatically retrying with backoff..."

**Jitter prevents thundering herd:**
- Base delay: 2^attempt * 1000ms
- Jitter: + random(0-1000ms)
- Prevents synchronized retry storms when many requests fail simultaneously

**SSE error event structure:**
```typescript
{
  jobId: string,
  error: classified.technicalMessage,      // For debugging/logs
  userMessage: classified.userMessage,     // For UI display
  retryable: classified.retryable,         // Whether user can retry
  httpStatus: classified.httpStatus,       // HTTP status code if available
}
```

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**Pre-existing type errors (unchanged):**
- config-advanced.ts, llm-providers.ts, generate.ts have Drizzle ORM type mismatches
- streaming.ts has duplicate export conflicts
- These errors existed before this plan and don't affect error handler functionality
- Documented as low-priority cleanup for future work

## User Setup Required

None - error handling is automatic and requires no configuration.

## Next Phase Readiness

**Ready for next phase:**
- Error handler provides foundation for Phase 3 critic scoring error handling
- Frontend integration (Phase 4) can display user-friendly error messages from SSE events
- Batch orchestration (Phase 7) benefits from retry logic with jitter

**Example error flows now working:**
1. **API key expired** → User sees "Check your API key in Settings > LLM Providers" (non-retryable)
2. **Rate limit hit** → System automatically retries with exponential backoff + jitter, user sees "Retrying..." (retryable)
3. **Circuit breaker open** → User sees "Wait 30 seconds and try again" (non-retryable, time-gated)
4. **Network timeout** → System retries up to maxRetries times with jitter (retryable)

**No blockers:**
- All error handling integrated with existing circuit breaker and SSE streaming
- Classification logic can be extended for new error types as needed
- Jitter prevents coordination issues in batch generation scenarios

---
*Phase: 02-core-generation-pipeline*
*Completed: 2026-01-25*
