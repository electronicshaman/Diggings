# Phase 4: Frontend Streaming Client - Research

**Researched:** 2026-01-26
**Domain:** SSE client implementation, React state management, reconnection strategies
**Confidence:** HIGH

## Summary

The frontend streaming client needs to consume SSE events from the backend (implemented in Phase 1), manage streaming progress state in Zustand, and support reconnection after connection drops. The project already uses Fetch API with ReadableStream (not native EventSource) in `packages/frontend/src/lib/streaming.ts`, which provides better control for POST requests and custom headers while sacrificing automatic reconnection.

Current implementation analysis:
- **Fetch + ReadableStream approach** already in use (streaming.ts)
- **useState-based state** in useGeneration.ts hook
- **No persistence** of progress state across connection drops
- **No automatic reconnection** logic (AbortController used for cancellation only)

Key gaps to address:
1. **Reconnection strategy**: Manual exponential backoff needed (EventSource does this automatically)
2. **State persistence**: Move streaming state to Zustand with persist middleware
3. **Job recovery**: Backend job tracker exists (24hr persistence), frontend needs to reconnect via jobId
4. **Progress recovery**: Need to query `/api/jobs/:jobId` endpoint to resume state

**Primary recommendation:** Migrate streaming state from useState to Zustand store with persist middleware, implement manual exponential backoff reconnection with jobId-based recovery, and add UI for reconnecting to in-progress jobs.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Zustand** | ^4.4.7 | Client state management | Already in project; minimal, supports persist middleware |
| **TanStack Query** | ^5.17.0 | Server state caching | Already in project; handles cache invalidation after generation |
| **Fetch API + ReadableStream** | Native | SSE streaming | Already implemented; better POST support than EventSource |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **zustand/middleware (persist)** | Included | State persistence to localStorage | For saving jobId and progress across reconnection |
| **AbortController** | Native | Stream cancellation | Already in use; cleanup on unmount |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fetch + ReadableStream | Native EventSource | EventSource: automatic reconnection, but GET-only, no custom headers, less control |
| useState | Zustand | Zustand: persists across reconnect, global access; useState: simpler but ephemeral |
| Manual polling | Backend push via SSE | SSE already chosen (Phase 1); polling would be step backward |

**Installation:**
No new dependencies needed. Zustand persist middleware is already available via:
```bash
import { persist } from 'zustand/middleware'
```

## Architecture Patterns

### Recommended Project Structure
Current structure is appropriate:
```
packages/frontend/src/
├── lib/
│   └── streaming.ts          # Fetch-based SSE client (exists)
├── hooks/
│   └── useGeneration.ts      # Generation hook (exists, needs migration)
└── store/
    ├── ui-store.ts           # UI preferences (exists)
    ├── form-store.ts         # Wizard form state (exists)
    └── generation-store.ts   # NEW: Streaming progress state
```

### Pattern 1: Zustand Store for Streaming State
**What:** Centralized store for generation progress, replacing useState in useGeneration.ts
**When to use:** For state that must survive component unmount or connection drops

**Example:**
```typescript
// Source: Zustand docs + project patterns (ui-store.ts, form-store.ts)
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface GenerationJob {
  jobId: string;
  stage: 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'error';
  progress: number;
  message?: string;
  outline?: unknown;
  content?: unknown;
  criticScore?: number;
  error?: string;
  startedAt: number; // timestamp
}

interface GenerationState {
  activeJob: GenerationJob | null;
  connectionAttempts: number;
  lastEventId: string | null;

  setJob: (job: GenerationJob) => void;
  updateProgress: (update: Partial<GenerationJob>) => void;
  clearJob: () => void;
  incrementRetry: () => void;
  resetRetry: () => void;
}

export const useGenerationStore = create<GenerationState>()(
  persist(
    (set) => ({
      activeJob: null,
      connectionAttempts: 0,
      lastEventId: null,

      setJob: (job) => set({ activeJob: job, connectionAttempts: 0 }),
      updateProgress: (update) =>
        set((state) => ({
          activeJob: state.activeJob
            ? { ...state.activeJob, ...update }
            : null
        })),
      clearJob: () => set({ activeJob: null, connectionAttempts: 0, lastEventId: null }),
      incrementRetry: () => set((state) => ({ connectionAttempts: state.connectionAttempts + 1 })),
      resetRetry: () => set({ connectionAttempts: 0 }),
    }),
    {
      name: 'node-gen-generation', // localStorage key
      partialize: (state) => ({
        // Only persist activeJob, not connection state
        activeJob: state.activeJob,
      }),
    }
  )
);
```

### Pattern 2: Exponential Backoff Reconnection
**What:** Manual reconnection with increasing delay after connection failures
**When to use:** Required because Fetch+ReadableStream doesn't auto-reconnect like EventSource

**Example:**
```typescript
// Source: MDN SSE docs + OneUpTime 2026 SSE guide
const INITIAL_RETRY_DELAY = 1000; // 1 second
const MAX_RETRY_DELAY = 30000;    // 30 seconds
const MAX_RETRIES = 5;
const BACKOFF_MULTIPLIER = 2;

function calculateBackoff(attemptNumber: number): number {
  const delay = Math.min(
    INITIAL_RETRY_DELAY * Math.pow(BACKOFF_MULTIPLIER, attemptNumber),
    MAX_RETRY_DELAY
  );

  // Add jitter to prevent thundering herd
  const jitter = Math.random() * 0.3 * delay; // ±30% jitter
  return delay + jitter;
}

async function connectWithRetry(
  jobId: string,
  attemptNumber: number,
  onConnect: (stream: StreamHandle) => void,
  onMaxRetries: () => void
) {
  if (attemptNumber >= MAX_RETRIES) {
    onMaxRetries();
    return;
  }

  try {
    const stream = streamGeneration(`/api/jobs/${jobId}/stream`, {}, callbacks);
    onConnect(stream);
  } catch (error) {
    const backoff = calculateBackoff(attemptNumber);
    setTimeout(() => {
      connectWithRetry(jobId, attemptNumber + 1, onConnect, onMaxRetries);
    }, backoff);
  }
}
```

### Pattern 3: Job Recovery on Mount
**What:** Check for in-progress job on component mount, offer to reconnect
**When to use:** When user refreshes page or navigates back during generation

**Example:**
```typescript
// Source: Project backend (job-tracker.ts) + persistence patterns
useEffect(() => {
  const activeJob = useGenerationStore.getState().activeJob;

  if (activeJob && activeJob.stage !== 'completed' && activeJob.stage !== 'error') {
    // Job exists and is incomplete - check if still running
    const ageMinutes = (Date.now() - activeJob.startedAt) / 60000;

    if (ageMinutes < 60) { // Within 24hr backend retention, likely still valid
      // Query job status from backend
      fetch(`/api/jobs/${activeJob.jobId}`)
        .then(res => res.json())
        .then(jobStatus => {
          if (jobStatus.status === 'running') {
            // Offer to reconnect
            setShowReconnectPrompt(true);
          } else if (jobStatus.status === 'completed') {
            // Update local state
            useGenerationStore.getState().updateProgress({
              stage: 'completed',
              progress: 100,
              content: jobStatus.result?.content,
            });
          } else {
            // Job failed or expired, clear
            useGenerationStore.getState().clearJob();
          }
        });
    } else {
      // Too old, likely expired
      useGenerationStore.getState().clearJob();
    }
  }
}, []);
```

### Pattern 4: Stream Cleanup in useEffect
**What:** Proper cleanup of SSE connection on component unmount
**When to use:** Always when managing long-lived connections in React

**Example:**
```typescript
// Source: React memory leak prevention best practices 2026
useEffect(() => {
  let streamHandle: StreamHandle | null = null;

  if (isConnecting) {
    streamHandle = streamGeneration(url, body, callbacks);
  }

  return () => {
    // Cleanup on unmount or dependency change
    if (streamHandle) {
      streamHandle.abort();
    }
  };
}, [isConnecting, jobId]); // Re-run if connection or job changes
```

### Anti-Patterns to Avoid
- **Multiple EventSource instances**: Project uses Fetch+ReadableStream, but if switching to EventSource, never create multiple instances per component (causes 6-connection browser limit)
- **Missing cleanup**: Not calling `abort()` in useEffect cleanup leads to memory leaks and orphaned connections
- **Persisting connection state**: Don't persist `connectionAttempts` or `isConnecting` to localStorage - these are ephemeral
- **Synchronous localStorage in SSR**: Zustand persist middleware handles this, but custom persistence must check `typeof window !== 'undefined'`
- **Updating unmounted component**: Always check if component is mounted before setState in async callbacks (or use AbortController signal)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SSE parsing | Custom SSE parser | Fetch + TextDecoder (existing) | Already implemented in streaming.ts; handles chunked data correctly |
| Exponential backoff | Simple setTimeout retry | Standard backoff algorithm with jitter | Prevents thundering herd; protects server; well-tested pattern |
| State persistence | Custom localStorage wrapper | Zustand persist middleware | Handles SSR, storage errors, version migrations, partial persistence |
| Last-Event-ID tracking | Manual ID storage | EventSource built-in (if used) | EventSource sends Last-Event-ID header automatically |
| Progress recovery | Full re-generation | Backend job persistence + query | Backend already tracks state; query `/api/jobs/:jobId` instead of restarting |

**Key insight:** The project already uses Fetch+ReadableStream (not EventSource), which means automatic reconnection must be hand-rolled, but SSE parsing should not be re-implemented. Zustand persist middleware eliminates need for custom localStorage logic.

## Common Pitfalls

### Pitfall 1: Connection Limit Exhaustion (HTTP/1.1)
**What goes wrong:** Browser limits SSE connections to 6 per domain on HTTP/1.1, causing new connections to hang
**Why it happens:** Each EventSource or streaming fetch holds a connection open; failed cleanup accumulates connections
**How to avoid:**
- Always call `abort()` in useEffect cleanup
- Use single connection per user session (no per-component connections)
- Backend must support HTTP/2 for production (100+ concurrent streams)
**Warning signs:** SSE requests stuck in "pending" state in DevTools Network tab

### Pitfall 2: Missing CORS Headers for SSE
**What goes wrong:** SSE requests fail with CORS errors in browser console
**Why it happens:** SSE respects same CORS rules as fetch; missing Access-Control-Allow-Origin or wildcard with credentials
**How to avoid:**
- Backend Phase 1 should have `Access-Control-Allow-Origin` header set
- Avoid wildcard `*` if using credentials/cookies
- Test cross-origin scenarios early
**Warning signs:** Console error "CORS policy blocked access" on SSE endpoint

### Pitfall 3: Buffer Bloat on Slow Connections
**What goes wrong:** Browser buffers large amounts of SSE data, causing memory issues or delayed updates
**Why it happens:** Fast backend sending beats faster than UI can process, especially with large partial results
**How to avoid:**
- Backend uses `X-Accel-Buffering: no` header (already in Phase 1)
- Frontend processes events immediately, don't batch
- Consider backpressure if backend sends large payloads
**Warning signs:** UI updates lag behind backend progress; browser memory usage grows

### Pitfall 4: Token Expiration During Long Streams
**What goes wrong:** SSE connection authenticated with JWT expires mid-stream (e.g., 15min token, 30min generation)
**Why it happens:** SSE connections are long-lived; auth tokens are short-lived
**How to avoid:**
- Use refresh tokens to renew auth mid-stream
- Backend validates token on reconnection
- Frontend detects 401 errors, refreshes token, reconnects
**Warning signs:** Stream succeeds initially but fails partway through with 401

### Pitfall 5: Lost Progress on Connection Drop
**What goes wrong:** User loses all progress if connection drops (network blip, laptop sleep, proxy timeout)
**Why it happens:** useState-based progress is ephemeral; no persistence or recovery
**How to avoid:**
- Use Zustand persist to save jobId and current progress
- Backend job tracker already persists state (24hr retention)
- On reconnect, query `/api/jobs/:jobId` to resume
- Offer UI to reconnect to incomplete jobs on page load
**Warning signs:** Users complain about lost work after brief disconnections

### Pitfall 6: Infinite Reconnection Loop
**What goes wrong:** Client continuously reconnects to failed endpoint, overwhelming server
**Why it happens:** No max retry limit; backend error doesn't signal "stop retrying"
**How to avoid:**
- Enforce MAX_RETRIES limit (5-10 attempts)
- Backend sends retryable flag in error events (from Phase 3 error-handler.ts)
- Respect backend `retry:` field if switching to EventSource
- Exponential backoff caps at MAX_RETRY_DELAY
**Warning signs:** Network tab shows repeated requests to same endpoint; server logs show connection spam

### Pitfall 7: Race Condition on Multiple Generations
**What goes wrong:** User starts new generation while previous is running; progress from both jobs interleaves
**Why it happens:** No job isolation in state; callbacks update same state object
**How to avoid:**
- Abort previous stream before starting new one (already in useGeneration reset())
- Check jobId matches current job before applying updates
- Use AbortController signal to ignore stale callbacks
**Warning signs:** Progress bar jumps erratically; content from wrong generation appears

## Code Examples

Verified patterns from official sources and project code:

### Reconnect with Job Recovery
```typescript
// Source: Project backend job-tracker.ts + SSE reconnection best practices
async function reconnectToJob(jobId: string) {
  const generationStore = useGenerationStore.getState();

  try {
    // Query current job status
    const response = await fetch(`/api/jobs/${jobId}`);
    if (!response.ok) {
      throw new Error('Job not found');
    }

    const jobStatus = await response.json();

    if (jobStatus.status === 'completed') {
      // Job finished while disconnected
      generationStore.updateProgress({
        stage: 'completed',
        progress: 100,
        content: jobStatus.result?.content,
        criticScore: jobStatus.result?.critic?.score,
      });
      return;
    }

    if (jobStatus.status === 'failed') {
      generationStore.updateProgress({
        stage: 'error',
        error: jobStatus.error || 'Generation failed',
      });
      return;
    }

    // Job still running - reconnect to stream
    // Backend streaming endpoint should support /api/jobs/:jobId/stream
    const stream = streamGeneration(
      `/api/jobs/${jobId}/stream`,
      {},
      {
        onProgress: (event) => {
          generationStore.updateProgress({
            stage: event.stage as any,
            progress: event.progress,
            message: event.message,
          });
        },
        onComplete: (data) => {
          generationStore.updateProgress({
            stage: 'completed',
            progress: 100,
          });
        },
        onError: (error) => {
          generationStore.updateProgress({
            stage: 'error',
            error
          });
        },
      }
    );

    generationStore.resetRetry();
    return stream;

  } catch (error) {
    console.error('Failed to reconnect:', error);
    throw error;
  }
}
```

### Persist Middleware with Partialize
```typescript
// Source: Zustand docs + project ui-store.ts pattern
export const useGenerationStore = create<GenerationState>()(
  persist(
    (set, get) => ({
      activeJob: null,
      connectionAttempts: 0,

      setJob: (job) => set({ activeJob: job }),
      updateProgress: (update) => set((state) => ({
        activeJob: state.activeJob ? { ...state.activeJob, ...update } : null
      })),
      clearJob: () => set({ activeJob: null, connectionAttempts: 0 }),
    }),
    {
      name: 'node-gen-generation',

      // Only persist job state, not ephemeral connection state
      partialize: (state) => ({
        activeJob: state.activeJob,
      }),

      // Version for migration if schema changes
      version: 1,

      // Custom merge to handle invalid persisted data
      merge: (persistedState, currentState) => {
        const persisted = persistedState as Partial<GenerationState>;

        // Validate activeJob if exists
        if (persisted.activeJob) {
          const ageMinutes = (Date.now() - persisted.activeJob.startedAt) / 60000;

          // Discard jobs older than 24 hours (backend retention)
          if (ageMinutes > 24 * 60) {
            return currentState; // Don't merge, use defaults
          }
        }

        return { ...currentState, ...persisted };
      },
    }
  )
);
```

### TanStack Query Invalidation After Completion
```typescript
// Source: Project useGeneration.ts + TanStack Query docs
import { useQueryClient } from '@tanstack/react-query';

function useStreamingGeneration() {
  const queryClient = useQueryClient();
  const generationStore = useGenerationStore();

  const onComplete = useCallback((data: GenerationResponse) => {
    // Update generation store
    generationStore.updateProgress({
      stage: 'completed',
      progress: 100,
      content: data.content,
    });

    // Invalidate cached node list to fetch new node
    queryClient.invalidateQueries({ queryKey: ['nodes'] });

    // Optionally: optimistically add to cache
    if (data.nodeId) {
      queryClient.setQueryData(['nodes', data.nodeId], data.content);
    }
  }, [queryClient, generationStore]);

  return { onComplete };
}
```

### Error Handling with Retryable Flag
```typescript
// Source: Backend error-handler.ts + SSE error patterns
interface SSEErrorEvent {
  error: string;
  userMessage: string;
  retryable: boolean;
  httpStatus: number;
}

function handleStreamError(
  errorEvent: SSEErrorEvent,
  jobId: string,
  attemptNumber: number
) {
  const generationStore = useGenerationStore.getState();

  if (!errorEvent.retryable) {
    // Permanent error (rate limit, invalid config, etc.)
    generationStore.updateProgress({
      stage: 'error',
      error: errorEvent.userMessage,
    });
    return;
  }

  // Temporary error (network, server overload, etc.)
  if (attemptNumber < MAX_RETRIES) {
    const backoff = calculateBackoff(attemptNumber);

    generationStore.updateProgress({
      message: `Connection lost. Retrying in ${Math.round(backoff / 1000)}s...`,
    });

    setTimeout(() => {
      reconnectToJob(jobId);
    }, backoff);

    generationStore.incrementRetry();
  } else {
    generationStore.updateProgress({
      stage: 'error',
      error: 'Max reconnection attempts reached',
    });
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| EventSource API only | Fetch + ReadableStream preferred | 2024-2025 | POST support, custom headers, more control; but requires manual reconnection |
| useState for streaming | Zustand with persist middleware | 2025-2026 | State survives unmount/refresh; enables job recovery |
| Polling for progress | SSE streaming | 2023-2024 | Real-time updates, lower latency, less server load |
| Single retry strategy | Exponential backoff with jitter | Established pattern | Prevents thundering herd, more resilient |
| TanStack Query v3 | TanStack Query v5 | 2024 | Better concurrent rendering, experimental streaming support |

**Deprecated/outdated:**
- **EventSource for POST requests**: Can't send body or headers; use Fetch+ReadableStream instead
- **Infinite retry without backoff**: Hammers server; use exponential backoff with max attempts
- **Redux for ephemeral state**: Overly complex for UI state; Zustand is 2026 standard for lightweight stores
- **Custom localStorage wrappers**: Zustand persist middleware handles SSR, errors, migrations

## Open Questions

Things that couldn't be fully resolved:

1. **Backend `/api/jobs/:jobId/stream` endpoint**
   - What we know: Backend has job-tracker.ts with getJob(jobId) function
   - What's unclear: Does streaming.ts support reconnection via jobId? Or only initial POST?
   - Recommendation: Check if backend route exists; if not, add in Phase 4 planning

2. **Last-Event-ID support for Fetch-based SSE**
   - What we know: EventSource sends Last-Event-ID header automatically on reconnect
   - What's unclear: How to implement with Fetch+ReadableStream (requires manual header)
   - Recommendation: Backend doesn't appear to use event IDs in streaming.ts; consider adding or decide if jobId-based recovery is sufficient

3. **Optimistic UI updates vs streaming**
   - What we know: TanStack Query supports optimistic updates; SSE provides real-time progress
   - What's unclear: Should UI optimistically show "generation started" before stream connects?
   - Recommendation: Start with conservative approach (wait for first progress event); optimize later if UX demands it

4. **Concurrent rendering with Zustand v4**
   - What we know: Zustand v5 has better concurrent rendering support (2026), project uses v4.4.7
   - What's unclear: Does v4 have tearing issues with rapid SSE updates?
   - Recommendation: Test with rapid progress updates; upgrade to v5 if tearing occurs

5. **HTTP/2 deployment in production**
   - What we know: Backend anti-buffering headers suggest production awareness
   - What's unclear: Is production environment HTTP/2 capable?
   - Recommendation: Verify production infrastructure supports HTTP/2 (critical for multiple concurrent SSE streams)

## Sources

### Primary (HIGH confidence)
- [MDN - Using Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) - EventSource API specification
- [OneUpTime - SSE in React (Jan 2026)](https://oneuptime.com/blog/post/2026-01-15-server-sent-events-sse-react/view) - Current React SSE patterns
- [Zustand Documentation - Persist Middleware](https://zustand.docs.pmnd.rs/integrations/persisting-store-data) - Official persist middleware docs
- Project codebase: `packages/frontend/src/lib/streaming.ts`, `packages/backend/src/services/generation/streaming.ts`

### Secondary (MEDIUM confidence)
- [Mohamed-Ali - SSE Comprehensive Guide (Medium)](https://medium.com/@moali314/server-sent-events-a-comprehensive-guide-e4b15d147576) - Reconnection strategies, Last-Event-ID
- [Tigerabrodi - SSE Practical Guide](https://tigerabrodi.blog/server-sent-events-a-practical-guide-for-the-real-world) - Production patterns
- [Ably - SSE as WebSockets Alternative](https://ably.com/topic/server-sent-events) - SSE vs alternatives tradeoffs
- [Ajit Singh - Complete SSE Guide](https://singhajit.com/server-sent-events-explained/) - Error handling, event format
- [LogRocket - TanStack Query + WebSockets](https://blog.logrocket.com/tanstack-query-websockets-real-time-react-data-fetching/) - Real-time integration patterns

### Tertiary (LOW confidence)
- [Azure/fetch-event-source (GitHub)](https://github.com/Azure/fetch-event-source) - Fetch-based EventSource alternative patterns
- [Rob Blackbourn - Beyond EventSource (Medium)](https://rob-blackbourn.medium.com/beyond-eventsource-streaming-fetch-with-readablestream-5765c7de21a1) - ReadableStream SSE parsing
- [State Management in 2026 (Nucamp)](https://www.nucamp.co/blog/state-management-in-2026-redux-context-api-and-modern-patterns) - Current state management landscape
- [DHIWise - React Memory Leaks](https://www.dhiwise.com/post/the-complete-guide-to-detect-and-prevent-memory-leaks-in-react-js) - useEffect cleanup patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Zustand and TanStack Query already in package.json, Fetch+ReadableStream already implemented
- Architecture: HIGH - Patterns verified in project code (ui-store.ts, form-store.ts, useGeneration.ts) and official docs
- Pitfalls: MEDIUM-HIGH - Common SSE issues documented in multiple sources; some project-specific (job recovery) are inferred from backend code

**Research date:** 2026-01-26
**Valid until:** 30 days (streaming patterns stable, but frontend tooling evolves quickly)
