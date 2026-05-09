---
phase: 04-frontend-streaming-client
plan: 01
subsystem: ui
tags: [zustand, sse, streaming, react, persistence, reconnection]

# Dependency graph
requires:
  - phase: 01-streaming-foundation
    provides: Backend SSE streaming endpoint with job tracking
  - phase: 02-core-generation-pipeline
    provides: 3-stage generation pipeline with progress events
provides:
  - Zustand generation store with 24hr persistence for job recovery
  - Exponential backoff reconnection utilities for SSE
  - useGenerateNode hook with automatic job recovery on mount
affects: [05-single-node-generation-ui, 06-bulk-generation-ui]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Zustand persist middleware with custom merge for stale data cleanup"
    - "Job recovery on mount via backend status endpoint"
    - "Exponential backoff with jitter for reconnection"

key-files:
  created:
    - packages/frontend/src/store/generation-store.ts
  modified:
    - packages/frontend/src/lib/streaming.ts
    - packages/frontend/src/hooks/useGeneration.ts

key-decisions:
  - "24hr age threshold for job recovery (matches backend retention)"
  - "60min age threshold for mount-time reconnection attempts"
  - "Exponential backoff: 1s initial, 30s max, 2x multiplier, 0-30% jitter"
  - "Persist only activeJob (connectionAttempts ephemeral)"

patterns-established:
  - "Zustand store with partialize for selective persistence"
  - "Custom merge function in persist config for data validation/cleanup"
  - "Job recovery pattern: check age → fetch status → update or clear"

# Metrics
duration: 3min
completed: 2026-01-26
---

# Phase 04 Plan 01: Frontend Streaming Client Summary

**Zustand-backed generation state with localStorage persistence, automatic job recovery on mount, and exponential backoff reconnection utilities**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-26T03:23:49Z
- **Completed:** 2026-01-26T03:26:47Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Generation state persists across page refresh via Zustand persist middleware
- Stale jobs (>24hr) automatically discarded on hydration
- Job recovery on mount checks backend status and syncs local state
- Exponential backoff utilities with jitter ready for reconnection flows

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Generation Zustand Store with Persist Middleware** - `e8b147f` (feat)
2. **Task 2: Add Reconnection Logic to Streaming Client** - `ef4b70a` (feat)
3. **Task 3: Migrate useGeneration Hook to Zustand with Job Recovery** - `97c2273` (feat)

## Files Created/Modified
- `packages/frontend/src/store/generation-store.ts` - Zustand store with GenerationJob interface, persist middleware, 24hr age cleanup
- `packages/frontend/src/lib/streaming.ts` - Added JobStatus interface, calculateBackoff, reconnectToJob, onReconnecting callback
- `packages/frontend/src/hooks/useGeneration.ts` - Migrated from useState to Zustand, added job recovery useEffect on mount

## Decisions Made

**24hr age threshold for job cleanup**
- Matches backend job retention policy (24hr expiration)
- Ensures stale persisted jobs are discarded on hydration

**60min age threshold for reconnection**
- Jobs older than 60 minutes unlikely to still be running
- Avoids unnecessary network requests for very old jobs
- Clear immediately if too old rather than attempting reconnection

**Exponential backoff parameters**
- Initial: 1s, Max: 30s, Multiplier: 2x
- 0-30% jitter prevents thundering herd problem
- Matches industry-standard backoff patterns

**Partialize persist config**
- Only persist `activeJob`, not `connectionAttempts`
- `connectionAttempts` is ephemeral session state
- Reduces localStorage churn

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused MAX_RETRIES constant**
- **Found during:** Task 2 (TypeScript compilation)
- **Issue:** MAX_RETRIES constant declared but never used, causing TS6133 error
- **Fix:** Commented out with note "Reserved for future retry logic"
- **Files modified:** packages/frontend/src/lib/streaming.ts
- **Verification:** TypeScript compiles without errors
- **Committed in:** ef4b70a (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minimal - constant reserved for future use, no functional change

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness

**Ready for Phase 5 (Single-Node Generation UI):**
- Generation state management complete
- Job recovery pattern established
- Backward-compatible hook interface preserved

**Integration points for Phase 5:**
- `useGenerateNode()` hook ready to wire into UI components
- `state.stage` drives progress display
- `state.content` and `state.criticResult` ready for result display
- `abort()` and `reset()` functions for user controls

**Future enhancements:**
- Reconnection UI feedback using `onReconnecting` callback
- Manual reconnect button for failed jobs
- Retry logic using `calculateBackoff` utility

---
*Phase: 04-frontend-streaming-client*
*Completed: 2026-01-26*
