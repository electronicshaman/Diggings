# Phase 1: Streaming Foundation - Context

**Gathered:** 2026-01-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Backend SSE streaming infrastructure for real-time AI generation progress updates. Provides server-sent events with heartbeat monitoring, job persistence for connection reliability, and anti-buffering headers to prevent proxy issues. Frontend streaming client is a separate phase.

</domain>

<decisions>
## Implementation Decisions

### Job Persistence Strategy
- Store job status only (running/complete/failed) — minimal tracking for reconnection
- Auto-delete completed/failed jobs after 24 hours
- User can resume from same job if they reconnect while generation is still running
- If job finishes while disconnected, show completion status on reconnect

### Heartbeat & Timeout Behavior
- Send heartbeat pings every 10-15 seconds during active generation
- If client hasn't received events (progress or heartbeat), show "reconnecting" state with visual feedback
- Auto-reconnect attempts: 3 maximum with exponential backoff
- After 3 failed reconnect attempts: show error with manual retry button

### Error Event Handling
- Distinguish error types (rate limit, validation, LLM failure, network, etc.)
- Error messages should be user-friendly only (plain English, actionable guidance)
- Include `retryable: true/false` flag in error events to guide client behavior
- Terminal errors (validation failure, bad config) mark job as failed immediately — no auto-retry

### Claude's Discretion
- SSE event structure and field names (stage, progress %, partial results format, timestamps)
- Anti-buffering header specifics (X-Accel-Buffering values, cache-control, etc.)
- Job table schema details (fields beyond status tracking)
- Heartbeat event format vs data events
- Exponential backoff timing for reconnection attempts
- Exact error type categories and mapping to retryable flag

</decisions>

<specifics>
## Specific Ideas

- Research recommended "10-15 second" heartbeat interval for SSE — follow that guideline
- Connection drops are a known SSE pitfall — job persistence prevents data loss
- Must handle proxy buffering issues (anti-buffering headers critical)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-streaming-foundation*
*Context gathered: 2026-01-25*
