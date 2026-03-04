# Domain Pitfalls: LLM Content Generation

**Domain:** AI-powered content generation with streaming UI
**Researched:** 2026-01-25
**Confidence:** MEDIUM (based on established patterns, some specifics need verification)

## Critical Pitfalls

Mistakes that cause rewrites, data loss, or major production issues.

### Pitfall 1: SSE Connection Drops Without Recovery

**What goes wrong:** Browser closes SSE connection due to proxy timeout, network hiccup, or background tab throttling. Generation continues server-side but frontend shows stale "generating..." state. User refreshes, loses partial results, LLM costs already incurred.

**Why it happens:**
- Default SSE timeout is often 30-60 seconds on proxies/load balancers
- Browsers throttle timers in background tabs (can delay heartbeat detection)
- No server-side job persistence means in-flight work is lost on connection drop
- Frontend doesn't handle reconnection or poll for completion

**Consequences:**
- User loses generated content if they refresh during disconnect
- Double-charges: user retries, server generates same content twice
- Poor UX: "It was working, then it just stopped"
- No audit trail of what was generated vs. what was saved

**Prevention:**
1. **Server-side job persistence:** Store generation state in DB with job ID
   - When connection drops, job continues in background
   - Frontend can reconnect with job ID and resume from last checkpoint

2. **Aggressive heartbeat:** Send SSE `ping` events every 10-15 seconds
   - Frontend tracks last ping timestamp, warns if >20s gap
   - Auto-reconnect with exponential backoff on timeout

3. **Checkpoint progress:** Save partial results (outline, expanded beats) to job record
   - If critic fails, user can still retrieve outline
   - Allows "resume from Stage 2" if expansion was interrupted

4. **Idempotency:** Use deterministic node IDs or UUIDs
   - Prevent duplicate generation on retry
   - Check DB for existing node before starting generation

5. **Frontend state machine:** Track connection state explicitly
   - States: connecting → streaming → completed → disconnected → reconnecting
   - Show different UI for each state (spinner vs. "Reconnecting...")

**Detection:**
- Monitor SSE disconnect rate (should be <5% under normal conditions)
- Track "zombie jobs" (generation completed but no DB save)
- User reports of "lost content" or "it froze"
- High ratio of LLM API calls to saved nodes

**Phase mapping:**
- **Phase 2 (Backend Generation):** Add job persistence table, idempotency checks
- **Phase 6 (Streaming UI):** Implement reconnection logic, heartbeat monitoring
- **Phase 7 (Testing):** Test network interruption scenarios explicitly

---

### Pitfall 2: Base64 "Encryption" Deployed to Production

**What goes wrong:** API keys stored in database with base64 encoding (current implementation) get leaked via DB backup, SQL injection, or insider access. Attacker uses keys to rack up LLM charges on user's account.

**Why it happens:**
- Base64 is encoding, not encryption (trivially reversible)
- Developers ship placeholder encryption "temporarily"
- No audit or reminder system to upgrade security before production
- Environment variable approach not documented clearly

**Consequences:**
- **Financial:** Attacker drains OpenAI/Anthropic account (can be thousands/hour)
- **Reputational:** User loses trust in application security
- **Legal:** Potential liability for negligent security practices
- **Data breach:** Keys may grant access to other user data via LLM APIs

**Prevention:**
1. **Never store keys in DB for production deployments**
   - Use environment variables exclusively for production
   - DB storage is ONLY for personal/development deployments

2. **Real encryption if DB storage is needed:**
   - AES-256-GCM with encryption key in environment variable
   - Rotate encryption keys periodically
   - Use key management service (AWS KMS, HashiCorp Vault) for multi-user

3. **Clear security warnings:**
   - UI banner: "API keys stored in database are encoded, not encrypted. For production, use environment variables."
   - CLAUDE.md explicit warning about security model
   - Environment variable setup documented prominently

4. **Prevent accidental production use:**
   - Runtime check: if `NODE_ENV=production` and DB keys used, throw error
   - Require explicit flag `ALLOW_DB_KEYS=true` to override (with logged warning)

5. **Security review gate:**
   - Checklist item in deployment docs: "API keys via env vars only"
   - Don't ship DB key management UI in production builds (feature flag?)

**Detection:**
- Code review flagging base64 usage
- Security audit finding keys in DB backups
- User reports unexpected LLM API charges
- Git history shows TODOs for "proper encryption" unresolved

**Phase mapping:**
- **Phase 1 (Foundation):** Document env var approach, add runtime checks
- **Phase 5 (Settings UI):** Display security warnings in provider form
- **Pre-deployment:** Verify encryption upgrade or disable DB storage

---

### Pitfall 3: Unbounded Retry Loops Cause Runaway Costs

**What goes wrong:** LLM returns malformed JSON or low-quality content. Automatic retry logic triggers. Retry also fails. Loop continues until maxRetries exhausted. For batch of 50 nodes × 3 retries × 3 stages = 450 LLM calls. At $0.02/call = $9 for batch that should cost $3.

**Why it happens:**
- Transient errors (rate limits) are retryable, but systematic errors (bad prompt) are not
- Retry logic doesn't distinguish error types
- Critic threshold too high (always rejects) causes infinite regeneration
- Batch processing amplifies costs (50 nodes × N retries each)

**Consequences:**
- **Financial:** 3-10x higher LLM costs than necessary
- **Time:** Batch generation takes 3x longer due to retries
- **User frustration:** Long wait followed by failure message
- **API rate limits:** Excessive retries trigger provider throttling

**Prevention:**
1. **Error classification:**
   - **Retriable:** Network timeout, 429 rate limit, 503 service unavailable
   - **Non-retriable:** 401 auth, 400 bad request, JSON parse error (after 2 attempts)
   - **Systematic:** Critic fails 3 times in a row with same node type → stop batch, flag for human review

2. **Circuit breaker pattern:**
   - Track failure rate per provider (e.g., 50% failures in last 10 requests)
   - If failure rate exceeds threshold, pause for 5 minutes
   - Prevents cascading failures across batch

3. **Cost budgets:**
   - Set max cost per batch (e.g., $10 limit)
   - Track cumulative token usage, abort batch if exceeded
   - Warn user: "Batch paused at $9.50 of $10 budget"

4. **Graduated retry strategy:**
   - First failure: Full retry
   - Second failure: Retry with temperature adjusted (±0.1)
   - Third failure: Skip node, log for manual review
   - Never retry critic failures more than 2x

5. **Prompt validation:**
   - Test prompts with sample data before batch
   - Validate that prompts don't exceed token limits
   - Check for common issues (missing context, invalid placeholders)

6. **Partial success handling:**
   - Save successful nodes even if batch partially fails
   - Return detailed breakdown: "38/50 succeeded, 12 failed (6 critic, 4 timeout, 2 auth)"
   - Allow user to retry only failed nodes

**Detection:**
- LLM cost spike without corresponding successful nodes
- Batch job duration > 3x expected time
- High ratio of API calls to completed nodes
- Repeated identical errors in logs

**Phase mapping:**
- **Phase 2 (Backend):** Implement error classification, circuit breaker
- **Phase 6 (Bulk UI):** Add cost tracking, budget limits
- **Phase 7 (Testing):** Test retry scenarios (simulate 429, malformed JSON)

---

### Pitfall 4: Streaming Response Buffering Destroys Real-Time UX

**What goes wrong:** User sees "Generating..." for 15 seconds, then entire content appears at once. No beat-by-beat updates. SSE events are buffered by proxy, reverse proxy (nginx/cloudflare), or Hono middleware. Real-time streaming becomes batch-style updates.

**Why it happens:**
- Reverse proxies buffer responses by default (nginx `proxy_buffering on`)
- Hono's `stream()` helper may not flush immediately without explicit flush calls
- TextEncoder queue fills up, waits for chunk size threshold before sending
- Missing `X-Accel-Buffering: no` header for nginx
- CloudFlare "Automatic Minification" buffers HTML/CSS/JS (may catch SSE)

**Consequences:**
- **UX degradation:** Defeats purpose of streaming (instant feedback)
- **User anxiety:** Long silence makes users think it's frozen
- **Lost competitive advantage:** Non-streaming UI would be simpler and as good

**Prevention:**
1. **HTTP headers for SSE:**
   ```typescript
   c.header('Content-Type', 'text/event-stream');
   c.header('Cache-Control', 'no-cache, no-transform');
   c.header('Connection', 'keep-alive');
   c.header('X-Accel-Buffering', 'no'); // nginx
   ```

2. **Explicit flush in stream:**
   ```typescript
   controller.enqueue(encoder.encode(message));
   await controller.flush?.(); // If supported
   ```

3. **Chunked transfer encoding:**
   - Ensure HTTP/1.1 chunked encoding is enabled
   - Each SSE event should be a separate chunk

4. **Test with real proxy:**
   - Deploy to staging with nginx/cloudflare in front
   - Verify events arrive within <500ms of generation
   - Use browser DevTools Network tab "EventStream" view

5. **Fallback polling:**
   - If SSE doesn't work (corporate firewalls block it), fall back to long-polling
   - POST `/generate/node` → returns job ID → poll GET `/generate/status/:jobId`

6. **Frontend timeout detection:**
   - If no SSE event received in 10 seconds (during active generation), warn user
   - Offer "Switch to polling mode" button

**Detection:**
- User reports "it's slow" despite quick LLM responses
- Network waterfall shows long wait before SSE events
- Testing reveals events arrive in burst, not incrementally

**Phase mapping:**
- **Phase 2 (Backend):** Add anti-buffering headers, test flush behavior
- **Phase 6 (Streaming UI):** Implement timeout detection, polling fallback
- **Phase 7 (Testing):** Test with nginx proxy, measure event latency

---

### Pitfall 5: Partial Batch Failure Loses Progress and Context

**What goes wrong:** Bulk generation of 50 nodes starts. 30 succeed, then network error hits. Entire batch marked "failed." User has no access to 30 completed nodes. Retry starts from scratch, wastes LLM calls on nodes already generated.

**Why it happens:**
- Batch processor uses all-or-nothing transaction model
- No incremental save (wait until all done to commit to DB)
- Job state not persisted between retries
- Frontend shows binary "success/failure," no partial states

**Consequences:**
- **Lost work:** 30 completed nodes discarded
- **Wasted cost:** Regenerate same 30 nodes, double LLM spend
- **User frustration:** "I had to start over completely"
- **Time waste:** 50-node batch takes 3 attempts instead of 1

**Prevention:**
1. **Incremental save:**
   - Save each node to DB immediately after completion
   - Mark as `status: 'generated'` vs. `'manual'`
   - Batch job summary tracks which succeeded

2. **Resume from checkpoint:**
   - Store batch job metadata: total, completed IDs, remaining IDs
   - On retry, skip nodes already in DB with same parameters
   - Only regenerate failed nodes

3. **Partial success reporting:**
   ```json
   {
     "total": 50,
     "successful": 32,
     "failed": 18,
     "failedNodes": [...],
     "message": "32 nodes saved. Retry 18 failed?"
   }
   ```

4. **Progress persistence:**
   - Update job record in DB after each node (not just at end)
   - Frontend can poll `/api/generate/bulk/:jobId/status` for live count
   - If server crashes, job can resume from last saved state

5. **Rollback vs. keep partial:**
   - Default: Keep successful nodes even if batch fails
   - Optional flag: `rollbackOnFailure: true` for all-or-nothing behavior
   - Document tradeoff: rollback = cleaner, keep = cheaper

**Detection:**
- User complaints about "lost progress"
- High variance in batch completion times (some retries hit cached nodes)
- DB shows clusters of nodes with same creation timestamp (successful batches)

**Phase mapping:**
- **Phase 2 (Backend):** Implement incremental save, job persistence
- **Phase 6 (Bulk UI):** Show partial success states, retry-only-failed option
- **Phase 7 (Testing):** Simulate mid-batch failure, verify resume

---

## Moderate Pitfalls

Mistakes that cause delays, tech debt, or poor UX, but are recoverable.

### Pitfall 6: Streaming Progress Events Out of Order

**What goes wrong:** Frontend receives `stage: 'reviewing'` event, then `stage: 'expanding'` event 500ms later. Progress bar jumps backward (66% → 50%). User confused. Root cause: SSE events sent without sequence numbers, network reordering, or concurrent writes to same stream.

**Why it happens:**
- SSE doesn't guarantee order if multiple threads write to stream
- Async code sends events from different stages without coordination
- Buffering in proxies reorders chunks

**Prevention:**
- Add sequence numbers to events: `{ seq: 5, stage: 'expanding', progress: 50 }`
- Frontend buffers out-of-order events, waits for next sequence before displaying
- Backend uses mutex/queue to serialize SSE writes
- Alternative: Use single-threaded event emitter pattern

**Detection:**
- User reports progress bar "jumping around"
- Frontend logs show non-monotonic sequence numbers

**Phase mapping:**
- **Phase 2 (Backend):** Add sequence numbers to SSE events
- **Phase 6 (Streaming UI):** Implement event buffering/reordering

---

### Pitfall 7: No Prompt Version Tracking Breaks Content Reproducibility

**What goes wrong:** Generated node quality drops suddenly. Team investigates, can't reproduce. Realize system prompt was edited last week. No record of what prompt was used for existing nodes. Can't A/B test old vs. new prompts. Can't roll back.

**Why it happens:**
- Prompts stored as editable constants (no version history)
- DB doesn't track which prompt version generated each node
- Git history exists but isn't linked to production data

**Prevention:**
- Store prompt templates in DB with version numbers
- Each node records: `promptVersion`, `modelUsed`, `generatedAt`
- Allow rollback: "Use v3 prompts" vs. "Use v4 prompts"
- A/B test: Generate same node with both prompts, let critic compare

**Detection:**
- Quality regression with unclear cause
- Inability to reproduce specific node generation
- Support requests: "It used to generate X, now it generates Y"

**Phase mapping:**
- **Phase 1 (Foundation):** Add prompt versioning to schema
- **Phase 4 (Config UI):** Track prompt changes, allow rollback

---

### Pitfall 8: LLM Provider Failover Not Implemented

**What goes wrong:** Primary LLM provider (OpenRouter) has outage. Batch generation fails completely. No automatic fallback to secondary provider (OpenAI direct). User must manually switch provider, restart batch.

**Why it happens:**
- Single active provider model (no failover)
- No health check or provider ranking
- Retry logic doesn't try alternate providers

**Prevention:**
- Support multiple active providers with priority ranking
- On repeated failures (circuit breaker), try next provider in list
- Health check endpoint: `GET /api/llm/health` pings all providers
- Automatic failover: If primary fails 3 times, switch to secondary for 5 minutes

**Detection:**
- Batch failures during known provider outages
- No generation possible when single provider is down

**Phase mapping:**
- **Phase 2 (Backend):** Implement provider priority list, failover logic
- **Phase 5 (Settings UI):** Allow configuring provider priority

---

### Pitfall 9: Temperature/Parameter Misconfigurations Not Validated

**What goes wrong:** User sets temperature = 5.0 (OpenAI max is 2.0). API rejects request with cryptic error. Or temperature = 0.0 → deterministic output → all nodes identical. No client-side validation.

**Why it happens:**
- Each provider has different parameter ranges (OpenAI: 0-2, Anthropic: 0-1)
- Form doesn't validate per-provider constraints
- No warnings for extreme values (temp=0 or temp=2)

**Prevention:**
- Provider-specific validation rules in schema
- UI shows range per selected provider: "Temperature (0.0 - 2.0 for OpenAI)"
- Warn if temperature < 0.3: "Very low, outputs may be repetitive"
- Warn if temperature > 1.5: "Very high, outputs may be incoherent"

**Detection:**
- API errors with parameter out of range
- User reports all nodes "sound the same"

**Phase mapping:**
- **Phase 4 (Shared Schemas):** Add provider-specific validation
- **Phase 5 (Settings UI):** Dynamic range sliders per provider

---

### Pitfall 10: Critic Scores Not Calibrated to Domain

**What goes wrong:** Critic scoring rubric (ported from CLI) expects specific narrative patterns. Scores combat nodes harshly (avg 45/100) but inflates choice nodes (avg 85/100). Combat nodes constantly rejected, choice nodes always pass, regardless of actual quality.

**Why it happens:**
- Single scoring rubric for all node types (doesn't account for type-specific expectations)
- Rubric emphasizes literary quality over game utility
- No domain expert review of scoring criteria

**Prevention:**
- Type-specific critic prompts: `combat-critic.txt`, `choice-critic.txt`
- Calibrate thresholds per type: combat=60, choice=75
- Track score distributions in production, alert if avg drops >10 points
- Allow manual override: "Accept even though critic scored 65"

**Detection:**
- High rejection rate for specific node type
- User complaints: "Combat nodes never work"
- Score distributions heavily skewed by type

**Phase mapping:**
- **Phase 2 (Backend):** Implement type-specific critic prompts
- **Phase 4 (Config UI):** Allow editing critic rubrics per type
- **Phase 7 (Testing):** Validate score distributions across all types

---

## Minor Pitfalls

Mistakes that cause annoyance or require small fixes.

### Pitfall 11: SSE Event Names Inconsistent with Frontend Expectations

**What goes wrong:** Backend sends `event: progress`, frontend listens for `event: update`. No events received. Silent failure.

**Prevention:**
- Use shared constants for event names: `packages/shared/src/constants/sse-events.ts`
- TypeScript types for events: `SSEEventType = 'progress' | 'stage' | 'complete' | 'error'`
- Integration tests verify frontend can parse backend SSE events

**Detection:**
- Frontend SSE listener never fires
- Browser DevTools shows events arriving but not handled

**Phase mapping:**
- **Phase 4 (Shared):** Create SSE event type constants
- **Phase 6 (Streaming UI):** Use shared types

---

### Pitfall 12: Long-Running Generations Cause Browser Memory Leaks

**What goes wrong:** User runs 10-node batch. Each node appends to progress log. Log grows to 10,000 DOM elements. Page freezes. Browser tab crashes.

**Prevention:**
- Virtual scrolling for progress log (react-window)
- Limit log to last 100 entries, discard older
- Store full log in job record (DB), UI shows summary

**Detection:**
- Browser performance profiling shows DOM bloat
- User reports page "gets slow after a few generations"

**Phase mapping:**
- **Phase 6 (Bulk UI):** Implement virtual scrolling, log truncation

---

### Pitfall 13: No Dry-Run Mode for Expensive Operations

**What goes wrong:** User clicks "Generate 50 nodes" thinking it's a preview. Batch starts immediately, $5 of LLM calls happen before user realizes. No undo.

**Prevention:**
- Confirmation dialog: "This will cost approximately $5. Continue?"
- Dry-run mode: Analyze gaps, show what would be generated, no LLM calls
- Cost estimator: 50 nodes × 3 stages × $0.03/call = $4.50

**Detection:**
- User complaints: "I didn't mean to start that"
- High cancellation rate on bulk jobs

**Phase mapping:**
- **Phase 6 (Bulk UI):** Add confirmation dialog, cost estimator, dry-run option

---

### Pitfall 14: Generated Content Not Diffable or Editable

**What goes wrong:** LLM generates narrative_hook with minor typo. User wants to fix typo without regenerating entire node. No "edit before saving" option. Must accept fully or reject fully.

**Prevention:**
- After generation completes, show editable form pre-filled with generated content
- "Accept" vs. "Edit & Save" vs. "Regenerate" buttons
- Diff view: Show original prompt → generated output → user edits

**Detection:**
- User regenerates nodes multiple times for small tweaks
- Feature requests for "manual editing after AI generation"

**Phase mapping:**
- **Phase 6 (Streaming UI):** Add edit mode after generation
- **Phase 5 (Create Form):** Support pre-filled editing

---

### Pitfall 15: API Rate Limits Not Communicated to User

**What goes wrong:** User hits OpenAI rate limit (500 RPM). Batch fails. Error message: "429 Too Many Requests." User doesn't understand. Thinks it's a bug.

**Prevention:**
- Translate API errors to user-friendly messages:
  - 429 → "Rate limit reached. Pausing for 60 seconds..."
  - 401 → "API key invalid. Check settings."
  - 500 → "LLM provider is experiencing issues. Retry in a few minutes."
- Show rate limit status in UI: "450/500 requests this minute"
- Automatic pacing: Wait 1 second between requests to stay under limit

**Detection:**
- Support requests: "What does 429 mean?"
- Users don't understand why batch paused

**Phase mapping:**
- **Phase 2 (Backend):** Add error translation layer
- **Phase 6 (UI):** Display user-friendly error messages

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| **Phase 2: Backend Generation** | Retry loops (Pitfall 3) | Implement circuit breaker, error classification immediately |
| **Phase 2: Backend Generation** | No job persistence (Pitfall 1) | Add jobs table with status tracking |
| **Phase 5: Settings UI** | Base64 encryption shipped (Pitfall 2) | Add runtime checks, security warnings in UI |
| **Phase 6: Streaming UI** | SSE buffering (Pitfall 4) | Test with real proxy, add anti-buffering headers |
| **Phase 6: Streaming UI** | Connection drops (Pitfall 1) | Implement reconnection logic, heartbeat pings |
| **Phase 6: Bulk UI** | Partial failure handling (Pitfall 5) | Save incrementally, show partial success states |
| **Phase 7: Testing** | Proxy buffering not caught (Pitfall 4) | Deploy staging with nginx, test SSE latency |
| **Phase 7: Testing** | Retry scenarios untested (Pitfall 3) | Simulate 429 errors, malformed JSON, network drops |
| **Pre-deployment** | Security audit missing (Pitfall 2) | Checklist: Env vars only, no DB keys in production |

---

## Research Confidence Notes

| Area | Confidence | Rationale |
|------|------------|-----------|
| SSE streaming | MEDIUM | Based on training data about SSE best practices; specific Hono behavior not verified with Context7 |
| LLM retry logic | HIGH | Well-documented patterns; existing code shows exponential backoff |
| Security (API keys) | HIGH | Existing code shows base64 "encryption" with TODO comments |
| Batch processing | MEDIUM | General patterns known; specific implementation details inferred from code |
| Cost management | MEDIUM | Based on known LLM pricing models; actual API cost calculation not verified |

---

## Sources

**Training Data (as of January 2025):**
- SSE (Server-Sent Events) specification and best practices
- OpenAI/Anthropic API documentation patterns
- Hono framework streaming capabilities (general knowledge)
- Retry logic and circuit breaker patterns
- Security best practices for API key storage

**Existing Codebase Analysis:**
- `/Users/rob/Projects/node-gen-web/packages/backend/src/services/generation/llm-client.ts` - Base64 encryption, retry logic
- `/Users/rob/Projects/node-gen-web/packages/backend/src/services/generation/streaming.ts` - SSE implementation
- `/Users/rob/Projects/node-gen-web/packages/backend/src/services/generation/batch-processor.ts` - Retry and batch logic
- `/Users/rob/Projects/node-gen-web/packages/backend/src/middleware/encryption.ts` - Security TODOs
- `/Users/rob/Projects/node-gen-web/AI integration plan.md` - Planned architecture
- `/Users/rob/Projects/node-gen-web/IMPLEMENTATION_PLAN.md` - Phase structure

**Limitations:**
- Did not verify Hono streaming flush behavior with official docs (Context7/WebSearch unavailable)
- Did not verify current OpenAI/Anthropic API rate limits (2026 values unknown)
- Cost estimates based on typical LLM pricing, not actual current rates
- Proxy buffering behavior assumes typical nginx/CloudFlare defaults
