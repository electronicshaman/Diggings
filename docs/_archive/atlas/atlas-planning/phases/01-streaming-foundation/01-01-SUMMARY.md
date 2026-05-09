---
phase: 01-streaming-foundation
plan: 01
subsystem: backend-api
tags: [sse, streaming, job-persistence, realtime, api]
requires:
  - Initial codebase with generation services
provides:
  - SSE streaming endpoint with job persistence
  - Job lookup API for reconnection support
  - Heartbeat mechanism for connection monitoring
affects:
  - 02-error-handling (will use job persistence for retry logic)
  - 05-batch-orchestration (will use same job tracking pattern)
tech-stack:
  added:
    - Server-Sent Events (SSE)
    - ReadableStream API
    - Job persistence with 24hr expiry
  patterns:
    - Event-driven progress updates
    - Job-based state persistence
    - Anti-buffering headers for proxies
key-files:
  created:
    - packages/backend/src/services/generation/job-tracker.ts
    - packages/backend/drizzle/0002_public_virginia_dare.sql
  modified:
    - packages/backend/src/db/schema.ts
    - packages/backend/src/services/generation/streaming.ts
    - packages/backend/src/routes/generate.ts
    - packages/backend/src/services/generation/index.ts
decisions:
  - key: job-persistence-duration
    choice: 24 hours
    rationale: Balance between allowing reconnection and database cleanup
    alternatives: [1 hour, 7 days, permanent]
  - key: heartbeat-interval
    choice: 12 seconds
    rationale: Prevents proxy timeouts without excessive traffic
    alternatives: [5 seconds, 30 seconds, 60 seconds]
  - key: error-classification
    choice: Pattern matching on error messages
    rationale: Simple heuristic until actual API responses are observed
    alternatives: [Status code only, Structured error types]
metrics:
  duration: 5 minutes
  completed: 2026-01-25
---

# Phase 1 Plan 1: SSE Streaming Foundation Summary

**One-liner:** Established SSE streaming infrastructure with job persistence, heartbeat pings, and anti-buffering headers for reliable real-time generation progress updates.

## What Was Built

Implemented robust Server-Sent Events (SSE) streaming for AI generation with:

1. **Database Layer**
   - Added `generationJobs` table with job status tracking
   - Includes jobId (UUID), status enum (pending/running/completed/failed), progress tracking (0-100%)
   - Stores full request JSONB for potential resume capability
   - Auto-expires after 24 hours for cleanup
   - Indexed on jobId and expiresAt for performance

2. **Job Tracker Service**
   - `createJob()`: Creates new job with UUID and 24hr expiry
   - `updateJobStatus()`: Updates progress, stage, result, or error
   - `getJob()`: Retrieves job by ID for reconnection support
   - `cleanupOldJobs()`: Deletes expired jobs (called on startup or periodically)

3. **SSE Streaming Service**
   - `streamGeneration()`: Main streaming function with proper SSE format
   - Anti-buffering headers: `X-Accel-Buffering: no`, `Cache-Control: no-cache, no-store, must-revalidate`
   - Heartbeat pings every 12 seconds to prevent timeout
   - Event types: `progress`, `partial`, `complete`, `error`, `ping`
   - Error classification: Retryable (429, 503, network) vs non-retryable (400, 401, validation)

4. **API Endpoints**
   - `POST /api/generate/stream`: Create job and stream generation progress
   - `GET /api/generate/job/:jobId`: Lookup job status (for reconnection)
   - Updated `POST /api/generate/node`: Non-streaming generation

## Key Technical Decisions

**Job Persistence (24hr TTL)**
- Allows clients to reconnect and check status after disconnect
- Trades off storage space for user experience
- Automatic cleanup via expiresAt index

**Heartbeat Interval (12s)**
- Prevents proxy/load balancer timeouts (typically 30-60s)
- Minimal bandwidth overhead (~5 events/minute)
- Faster than most timeout thresholds, slower than chatty

**Error Classification Heuristic**
- Pattern matching on error messages until we have real API data
- Retryable: Rate limits (429), service unavailable (503), network errors
- Non-retryable: Auth (401, 403), bad request (400), validation errors
- Default to non-retryable for safety

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing bun-types dependency**
- **Found during:** Task 2 verification (typecheck)
- **Issue:** TypeScript compilation failed with "Cannot find type definition file for 'bun-types'"
- **Fix:** Added `bun-types` as dev dependency in packages/backend/package.json
- **Files modified:** packages/backend/package.json, pnpm-lock.yaml
- **Commit:** 5bf9bcb

**2. [Rule 3 - Blocking] Drizzle rowCount compatibility**
- **Found during:** Task 2 implementation
- **Issue:** Drizzle ORM doesn't return `rowCount` on delete operations
- **Fix:** Simplified `cleanupOldJobs()` to return 0 for now (cleanup count not critical for MVP)
- **Files modified:** packages/backend/src/services/generation/job-tracker.ts
- **Commit:** 5bf9bcb

**3. [Rule 2 - Missing Critical] Request format conversion**
- **Found during:** Task 3 implementation
- **Issue:** GenerationRequest (from shared schema) != NodeGenerationRequest (batch-processor expects)
- **Fix:** Added `toNodeGenerationRequest()` helper in generate.ts to convert between formats
- **Files modified:** packages/backend/src/routes/generate.ts
- **Commit:** 4edc5c2

## Verification Results

**Database:**
- Migration 0002 created and applied successfully
- generationJobs table exists with all columns and indexes
- Jobs persist during generation and can be queried afterward

**SSE Endpoint:**
- `POST /api/generate/stream` returns `Content-Type: text/event-stream`
- Anti-buffering headers present: `X-Accel-Buffering: no`, `Cache-Control: no-cache, no-store, must-revalidate`
- Events use proper SSE format: `event: progress\ndata: {"jobId":"...","stage":"outlining","progress":20}\n\n`
- Progress events sent with jobId, stage, progress, and message

**Job Lookup:**
- `GET /api/generate/job/:jobId` returns job status, progress, result/error
- Supports reconnection use case: client can poll this endpoint if stream disconnects

**Heartbeat:**
- Ping events sent every 12 seconds (verified in code, but stream closed too quickly to observe in test due to missing API key)
- Heartbeat clears on stream close

## Known Limitations

1. **Heartbeat validation incomplete**: Stream closed before 12s due to generation failure (no API key configured). Heartbeat logic present but not observed in testing.

2. **Cleanup job not scheduled**: `cleanupOldJobs()` exists but not called on a schedule. Should be added as background task in future phase.

3. **No resume capability**: Job stores full request for potential resume, but resume logic not implemented. Client can check status but can't restart from checkpoint.

4. **No database save on success**: Streaming endpoint creates job but doesn't save generated node to `nodes` table. Non-streaming endpoint (`/node`) does save, but streaming doesn't yet.

## Integration Points

**For Phase 2 (Error Handling):**
- Job persistence enables retry tracking
- Error classification provides retryable flag for retry decision
- Job lookup allows checking if retry succeeded

**For Phase 3 (Critic Stage):**
- Progress events already include `reviewing` stage
- Partial results sent after each stage (outline, content)
- Critic score will be included in completion event

**For Phase 5 (Batch Orchestration):**
- Job tracking pattern can extend to batch jobs
- Same generationJobs table can track batch progress
- SSE can stream updates for multiple nodes

## Next Phase Readiness

**Phase 2 Prerequisites Met:**
- ✓ Job status tracking for retry logic
- ✓ Error classification (retryable vs non-retryable)
- ✓ Progress persistence for debugging

**Outstanding for Phase 2:**
- Retry queue implementation
- Exponential backoff configuration
- Circuit breaker for repeated failures

## Testing Notes

**Manual Testing:**
- Verified SSE endpoint with curl (events stream in correct format)
- Verified headers with curl -v (anti-buffering headers present)
- Verified job lookup with curl (returns job status)
- Verified database persistence with psql (jobs written and queryable)

**Not Tested:**
- Heartbeat pings beyond 12 seconds (stream closed early)
- Complete generation flow (no API key configured)
- Resume from disconnection (no resume logic yet)

## Commit Log

| Commit | Type | Description |
|--------|------|-------------|
| acabb8e | feat | Add generationJobs table to database schema |
| 5bf9bcb | feat | Create job-tracker service for job persistence |
| 4edc5c2 | feat | Implement SSE streaming with heartbeat and job integration |
