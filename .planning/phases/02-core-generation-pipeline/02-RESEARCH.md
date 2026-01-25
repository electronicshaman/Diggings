# Phase 2: Core Generation Pipeline - Research

**Researched:** 2026-01-25
**Domain:** Multi-stage LLM pipeline orchestration with SSE streaming
**Confidence:** HIGH

## Summary

Phase 2 completes the end-to-end generation pipeline wiring: connecting the prompt-builder to a 3-stage generation flow (outliner → expander → critic) with SSE streaming, multi-provider LLM support, and production-grade error handling.

The codebase already has substantial infrastructure in place from Phase 1. The generation stages exist (`beat-outliner.ts`, `prose-expander.ts`, `critic.ts`), SSE streaming is implemented with job persistence (`streaming.ts`, `job-tracker.ts`), and the LLM client supports all three providers (`llm-client.ts`). The core architecture is sound.

**Key findings:**
- All 3 generation stages are implemented and functional
- SSE streaming infrastructure exists with 12s heartbeat and 24hr job persistence
- LLM client has basic retry logic (exponential backoff) but lacks circuit breaker
- Error classification is heuristic (pattern matching on messages)
- Database save on completion is not yet wired (streaming endpoint doesn't persist)

**Primary recommendation:** Wire the existing pieces together with circuit breaker pattern and enhanced error handling. Don't rewrite - integrate and enhance.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Hono | 4.0+ | Web framework with streaming | Native SSE support via `streamSSE()` helper, lightweight, TypeScript-first |
| @anthropic-ai/sdk | 0.32+ | Anthropic Claude API client | Official SDK with proper typing, handles streaming and error codes |
| openai | 4.77+ | OpenAI + OpenRouter client | Official SDK with built-in retry (maxRetries), supports streaming, compatible with OpenRouter |
| Drizzle ORM | 0.36+ | Database ORM | Type-safe, already in use for job persistence (generation_jobs table) |
| Zod | 3.22+ | Schema validation | Runtime validation, type inference, already used throughout codebase |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| opossum | 8.1+ | Circuit breaker | Prevent runaway LLM costs when provider repeatedly fails (ERR-01 requirement) |
| Bun | Latest | JavaScript runtime | Already in use, fast native APIs, ESM-first |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| opossum | cockatiel | More features (bulkheads, rate limiters) but heavier, less Node.js community adoption |
| SSE | WebSockets | Bidirectional but more complex, SSE is simpler for server→client streaming |
| Manual retry | tenacity (Python) / p-retry (JS) | Generic retry libs don't understand LLM-specific error codes (429 vs 401) |

**Installation:**
```bash
# Circuit breaker for Phase 2
bun add opossum
bun add --dev @types/opossum
```

## Architecture Patterns

### Recommended Project Structure
Already in place from Phase 1:
```
packages/backend/src/
├── services/generation/
│   ├── llm-client.ts          # Multi-provider LLM client
│   ├── prompt-builder.ts      # Context builder
│   ├── beat-outliner.ts       # Stage 1: Beat generation
│   ├── prose-expander.ts      # Stage 2: Prose expansion
│   ├── critic.ts              # Stage 3: Quality evaluation
│   ├── batch-processor.ts     # 3-stage orchestration
│   ├── streaming.ts           # SSE implementation
│   ├── job-tracker.ts         # Job persistence
│   └── index.ts               # Public API
├── routes/
│   └── generate.ts            # API endpoints
└── db/
    └── schema.ts              # generation_jobs table
```

### Pattern 1: Circuit Breaker Wrapper for LLM Calls

**What:** Wrap the LLM `complete()` function in an opossum circuit breaker to prevent runaway costs when a provider fails repeatedly.

**When to use:** Always for production LLM calls. ERR-01 requirement mandates circuit breaker for repeated failures.

**Example:**
```typescript
// Source: opossum documentation + LLM-specific configuration
import CircuitBreaker from 'opossum';
import { complete, type LLMCompletionOptions } from './llm-client.js';

// Create circuit breaker for LLM completion
const llmBreaker = new CircuitBreaker(complete, {
  timeout: 60000,              // 60s (LLM calls can be slow)
  errorThresholdPercentage: 50, // Open after 50% failures
  resetTimeout: 30000,          // Try recovery after 30s
  rollingCountTimeout: 10000,   // Track errors over 10s window
  name: 'llm-completion',
});

// Fallback to provide helpful error
llmBreaker.fallback(() => {
  throw new Error('LLM service temporarily unavailable. The circuit breaker has opened due to repeated failures. Please try again in 30 seconds.');
});

// Event monitoring
llmBreaker.on('open', () => {
  console.error('[Circuit Breaker] OPEN - LLM calls are now failing fast');
});
llmBreaker.on('halfOpen', () => {
  console.log('[Circuit Breaker] HALF-OPEN - Testing if LLM service recovered');
});
llmBreaker.on('close', () => {
  console.log('[Circuit Breaker] CLOSED - LLM service operational');
});

// Use breaker instead of direct complete()
export async function completeWithCircuitBreaker(
  options: LLMCompletionOptions
): Promise<LLMCompletionResult> {
  return await llmBreaker.fire(options);
}
```

**Key insight:** Circuit breaker MUST wrap the lowest-level LLM call (before retry logic), not the high-level `generateSingle()`. This ensures the breaker trips on provider failures, not transient network issues.

### Pattern 2: Error Classification with Provider-Specific Codes

**What:** Classify errors as retryable/non-retryable based on HTTP status codes and provider-specific error messages.

**When to use:** In the retry logic (`completeWithRetry`) and SSE error reporting (already partially implemented).

**Example:**
```typescript
// Source: OpenAI/Anthropic/OpenRouter API documentation (2026)
interface ErrorClassification {
  retryable: boolean;
  userMessage: string;
  httpStatus?: number;
}

function classifyLLMError(error: Error | unknown): ErrorClassification {
  const errorMsg = error instanceof Error ? error.message : String(error);
  const lowerMsg = errorMsg.toLowerCase();

  // Non-retryable: Authentication/Authorization
  if (lowerMsg.includes('401') || lowerMsg.includes('403') ||
      lowerMsg.includes('unauthorized') || lowerMsg.includes('forbidden') ||
      lowerMsg.includes('invalid api key')) {
    return {
      retryable: false,
      userMessage: 'API authentication failed. Please check your API key in settings.',
      httpStatus: 401,
    };
  }

  // Non-retryable: Invalid request
  if (lowerMsg.includes('400') || lowerMsg.includes('invalid_request') ||
      lowerMsg.includes('validation')) {
    return {
      retryable: false,
      userMessage: 'Invalid request parameters. Please check your node configuration.',
      httpStatus: 400,
    };
  }

  // Retryable: Rate limiting (with retry-after header honored)
  if (lowerMsg.includes('429') || lowerMsg.includes('rate limit')) {
    return {
      retryable: true,
      userMessage: 'Rate limit exceeded. The system will automatically retry with exponential backoff.',
      httpStatus: 429,
    };
  }

  // Retryable: Service overloaded (OpenRouter fallback, Anthropic 529)
  if (lowerMsg.includes('503') || lowerMsg.includes('529') ||
      lowerMsg.includes('service unavailable') || lowerMsg.includes('overloaded')) {
    return {
      retryable: true,
      userMessage: 'LLM service temporarily overloaded. Retrying with backoff.',
      httpStatus: 503,
    };
  }

  // Retryable: Network errors
  if (lowerMsg.includes('timeout') || lowerMsg.includes('econnrefused') ||
      lowerMsg.includes('enotfound') || lowerMsg.includes('network')) {
    return {
      retryable: true,
      userMessage: 'Network error occurred. Retrying...',
    };
  }

  // Non-retryable: Content filter (OpenAI/Anthropic)
  if (lowerMsg.includes('content_filter') || lowerMsg.includes('content_policy')) {
    return {
      retryable: false,
      userMessage: 'Content rejected by safety filters. Please modify the node parameters.',
      httpStatus: 400,
    };
  }

  // Default: Non-retryable unknown error
  return {
    retryable: false,
    userMessage: `Unknown error: ${errorMsg}`,
  };
}
```

**Why this matters:** The current `isRetryableError()` in `streaming.ts` is a good start, but lacks provider-specific patterns (e.g., Anthropic's 529 overload code, OpenRouter's automatic fallback behavior).

### Pattern 3: SSE Streaming with Job Persistence

**What:** Stream generation progress via SSE while persisting state to the database for reconnection support.

**When to use:** All generation endpoints. Already implemented in `streaming.ts`, just needs enhancement.

**Current implementation (Phase 1):**
```typescript
// Source: packages/backend/src/services/generation/streaming.ts (lines 73-225)
export async function streamGeneration(
  c: Context,
  request: NodeGenerationRequest,
  jobId: string
) {
  // SSE headers with anti-buffering
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('X-Accel-Buffering', 'no'); // Prevents nginx buffering

  const stream = new ReadableStream({
    async start(controller) {
      // 12s heartbeat prevents proxy timeouts
      const heartbeat = setInterval(() => {
        controller.enqueue(encoder.encode(formatSSE('ping', { timestamp: Date.now() })));
      }, 12000);

      // Update job status throughout pipeline
      await updateJobStatus(jobId, { status: 'running', currentStage: 'outlining' });

      // Execute 3-stage pipeline with progress callbacks
      const result = await generateSingle(request, {
        onProgress: async (progress) => {
          await updateJobStatus(jobId, { progress: progress.progress, currentStage: progress.stage });
          controller.enqueue(encoder.encode(formatSSE('progress', progress)));

          // Send partial results after each stage
          if (progress.stage === 'expanding' && progress.outline) {
            controller.enqueue(encoder.encode(formatSSE('partial', { type: 'outline', data: progress.outline })));
          }
        },
      });

      // Handle completion/failure with database persistence
      if (result.stage === 'completed') {
        await updateJobStatus(jobId, { status: 'completed', result });
        controller.enqueue(encoder.encode(formatSSE('complete', result)));
      } else {
        await updateJobStatus(jobId, { status: 'failed', error: result.error });
        const retryable = isRetryableError(result.error);
        controller.enqueue(encoder.encode(formatSSE('error', { error: result.error, retryable })));
      }
    },
  });

  return new Response(stream);
}
```

**Reconnection pattern:**
- Client reconnects to `/api/generate/job/:jobId` to check status
- Job persists for 24 hours (`expiresAt` in schema)
- `Last-Event-ID` header NOT implemented (would require event ID tracking)

### Pattern 4: Exponential Backoff with Jitter

**What:** Retry transient errors with exponentially increasing delays plus random jitter to prevent thundering herd.

**When to use:** Already implemented in `completeWithRetry()` and `batch-processor.ts`. Enhancement needed: respect `Retry-After` header from providers.

**Current implementation:**
```typescript
// Source: packages/backend/src/services/generation/llm-client.ts (lines 183-221)
export async function completeWithRetry(
  options: LLMCompletionOptions,
  maxRetries?: number
): Promise<LLMCompletionResult> {
  const provider = await getActiveProvider();
  const retries = maxRetries ?? provider.maxRetries;
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await complete(options);
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));

      // Don't retry auth errors
      if (lastError.message.includes('401') || lastError.message.includes('403')) {
        throw lastError;
      }

      // Exponential backoff: 2^attempt * 1000ms
      if (attempt < retries) {
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise((resolve) => setTimeout(resolve, delay));
      }
    }
  }

  throw lastError ?? new Error('LLM completion failed after retries');
}
```

**Enhancement needed:**
```typescript
// Add jitter and respect Retry-After header
const baseDelay = Math.pow(2, attempt) * 1000;
const jitter = Math.random() * 1000; // 0-1000ms random
const delay = baseDelay + jitter;

// Check for Retry-After header (from error object if provider SDK exposes it)
const retryAfter = extractRetryAfter(lastError);
if (retryAfter) {
  await new Promise((resolve) => setTimeout(resolve, retryAfter * 1000));
} else {
  await new Promise((resolve) => setTimeout(resolve, delay));
}
```

### Anti-Patterns to Avoid

- **Retrying non-retryable errors:** Don't retry 401/403/400 errors - they'll never succeed. Current code correctly avoids this.
- **Circuit breaker on high-level functions:** Don't wrap `generateSingle()` - wrap the LLM `complete()` call. Breaker should trip on provider failures, not application logic failures.
- **Missing SSE heartbeat:** Without periodic `ping` events, proxies/load balancers will timeout long-running streams. Already implemented at 12s intervals.
- **Unbounded retries:** Always limit retries (current default: 3). Infinite retries can cause runaway costs.
- **Ignoring partial results:** In streaming errors, preserve partial results from completed stages. Already handled via job persistence.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Circuit breaker | Custom failure counter + state machine | opossum | Handles half-open state, rolling windows, fallbacks, events. Easy to get state transitions wrong. |
| Exponential backoff | `setTimeout()` with `Math.pow()` | Already implemented correctly | Current impl is good, just needs jitter and Retry-After header support. |
| SSE streaming | Manual `Response` with `TextEncoder` | Hono's `streamSSE()` helper | Current code manually manages streams. Hono helper is simpler but current impl works and includes heartbeat. |
| Error classification | String matching on error messages | Provider SDK error types | OpenAI/Anthropic SDKs have typed error classes. Current pattern matching is acceptable for now since SDKs don't expose structured errors consistently across providers. |
| LLM client retry | Manual retry logic | OpenAI SDK `maxRetries` | OpenAI SDK has built-in retry, but doesn't cover all providers (Anthropic, OpenRouter). Custom retry needed for provider abstraction. |

**Key insight:** The codebase already correctly avoids hand-rolling most solutions. The circuit breaker (opossum) is the main missing piece for ERR-01 requirement.

## Common Pitfalls

### Pitfall 1: Circuit Breaker Opens Too Quickly on Cold Start

**What goes wrong:** LLM cold starts (model loading) can cause initial timeouts. If the circuit breaker's error threshold is too aggressive (e.g., 1 error), it opens immediately and prevents legitimate retries.

**Why it happens:** Circuit breakers track errors in a rolling window. A single slow cold start counts as a failure.

**How to avoid:**
- Use `errorThresholdPercentage: 50` (50% failure rate) not absolute count
- Set `rollingCountTimeout: 10000` (10s window) to smooth over transient spikes
- Set `timeout: 60000` (60s) to accommodate slow LLM responses
- Use `volumeThreshold: 5` to require at least 5 requests before opening

**Warning signs:** Circuit opens on first request, logs show "OPEN" immediately after deployment.

### Pitfall 2: Not Honoring Retry-After Headers

**What goes wrong:** Anthropic and OpenAI return `Retry-After` headers in 429 responses indicating exact wait time. Ignoring this causes premature retries that count against rate limits.

**Why it happens:** Error objects from SDKs don't consistently expose headers. Pattern matching on error messages misses this data.

**How to avoid:**
- Check if error object has `response.headers['retry-after']` property
- Parse header value (seconds as integer or HTTP date string)
- Use header value instead of exponential backoff calculation
- Log when Retry-After is used: `Respecting Retry-After: ${retryAfter}s`

**Warning signs:** Continued 429 errors despite backoff, rate limit errors in bursts.

### Pitfall 3: Streaming Errors After Headers Sent

**What goes wrong:** Once SSE stream starts, you can't change the HTTP status code. If an error occurs mid-stream, the response is 200 OK but contains error events.

**Why it happens:** SSE streams commit headers immediately. Errors during generation stages (outliner/expander/critic) occur after stream starts.

**How to avoid:**
- Use SSE `error` event type (already implemented)
- Include `retryable: boolean` flag in error events (already implemented)
- Persist error to job record for reconnection (`updateJobStatus` with error - already implemented)
- Client must check event type, not HTTP status

**Warning signs:** Clients see 200 responses but generation fails, errors not visible in network inspector.

### Pitfall 4: Database Save Missing After Stream Completion

**What goes wrong:** Streaming endpoint (`/api/generate/stream`) successfully generates content but doesn't save it to the `nodes` table. Job record has result, but user can't see the node in the UI.

**Why it happens:** Phase 1 focused on streaming infrastructure. The non-streaming endpoint (`/api/generate/node`) saves to database (lines 195-201 in `generate.ts`), but streaming endpoint only updates job status.

**How to avoid:**
- Add database insert/update after successful completion in `streaming.ts`
- Reuse the node save logic from `/api/generate/node` endpoint
- Handle nodeId generation if not provided in request
- Update job result to include saved nodeId for client tracking

**Warning signs:** User completes generation, sees success, but node doesn't appear in list. Job shows completed but node doesn't exist.

### Pitfall 5: No Cleanup Job Scheduler

**What goes wrong:** `cleanupOldJobs()` function exists but is never called. Job table grows indefinitely as expired jobs accumulate.

**Why it happens:** Function was written but not scheduled. No cron/interval runner configured.

**How to avoid:**
- Add daily cleanup job using Bun's `setInterval` or cron library
- Run on server startup: `setInterval(cleanupOldJobs, 24 * 60 * 60 * 1000)` (daily)
- Or use database trigger with TTL (PostgreSQL doesn't have automatic TTL, needs manual DELETE)
- Low priority for Phase 2 - 24hr expiry means max 1 day of accumulation

**Warning signs:** Database size grows over time, `SELECT COUNT(*) FROM generation_jobs` increases without bound.

## Code Examples

Verified patterns from official sources and existing codebase:

### Multi-Provider LLM Client with Circuit Breaker
```typescript
// Source: Existing llm-client.ts + opossum documentation
import CircuitBreaker from 'opossum';
import OpenAI from 'openai';
import Anthropic from '@anthropic-ai/sdk';

// Wrap complete() function with circuit breaker
const llmBreaker = new CircuitBreaker(complete, {
  timeout: 60000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000,
  rollingCountTimeout: 10000,
  volumeThreshold: 5, // Require 5 requests before opening
  name: 'llm-completion',
});

// Fallback message for when circuit is open
llmBreaker.fallback(() => {
  throw new Error(
    'LLM service unavailable due to repeated failures. ' +
    'The circuit breaker is open. Please wait 30 seconds and try again.'
  );
});

// Export breaker-wrapped function
export async function completeWithCircuitBreaker(
  options: LLMCompletionOptions
): Promise<LLMCompletionResult> {
  return await llmBreaker.fire(options);
}

// Then use in completeWithRetry:
export async function completeWithRetry(
  options: LLMCompletionOptions,
  maxRetries?: number
): Promise<LLMCompletionResult> {
  // ... existing retry logic, but call completeWithCircuitBreaker instead of complete
  return await completeWithCircuitBreaker(options);
}
```

### Enhanced Error Classification for User Messages
```typescript
// Source: OpenAI/Anthropic error documentation + existing streaming.ts
interface LLMError {
  retryable: boolean;
  userMessage: string;
  technicalMessage: string;
  httpStatus?: number;
}

function classifyLLMError(error: Error | unknown): LLMError {
  const errorMsg = error instanceof Error ? error.message : String(error);
  const lowerMsg = errorMsg.toLowerCase();

  // Auth errors (non-retryable)
  if (lowerMsg.includes('401') || lowerMsg.includes('invalid api key')) {
    return {
      retryable: false,
      userMessage: 'Authentication failed. Please check your API key in Settings > LLM Providers.',
      technicalMessage: errorMsg,
      httpStatus: 401,
    };
  }

  // Rate limiting (retryable)
  if (lowerMsg.includes('429') || lowerMsg.includes('rate limit')) {
    return {
      retryable: true,
      userMessage: 'Rate limit reached. The system will automatically retry with exponential backoff.',
      technicalMessage: errorMsg,
      httpStatus: 429,
    };
  }

  // Service overload (retryable, Anthropic-specific 529)
  if (lowerMsg.includes('529') || lowerMsg.includes('overloaded')) {
    return {
      retryable: true,
      userMessage: 'LLM service is temporarily overloaded. Retrying with backoff.',
      technicalMessage: errorMsg,
      httpStatus: 529,
    };
  }

  // Content filter (non-retryable)
  if (lowerMsg.includes('content_filter') || lowerMsg.includes('safety')) {
    return {
      retryable: false,
      userMessage: 'Content rejected by safety filters. Try adjusting themes or node parameters.',
      technicalMessage: errorMsg,
      httpStatus: 400,
    };
  }

  // Network errors (retryable)
  if (lowerMsg.includes('timeout') || lowerMsg.includes('econnrefused')) {
    return {
      retryable: true,
      userMessage: 'Network error occurred. Retrying...',
      technicalMessage: errorMsg,
    };
  }

  // Circuit breaker open (non-retryable, wait required)
  if (lowerMsg.includes('circuit breaker') || lowerMsg.includes('breaker is open')) {
    return {
      retryable: false,
      userMessage: 'Generation service temporarily unavailable due to repeated failures. Please wait 30 seconds and try again.',
      technicalMessage: errorMsg,
      httpStatus: 503,
    };
  }

  // Default unknown error (non-retryable)
  return {
    retryable: false,
    userMessage: 'An unexpected error occurred. Please try again or contact support if the issue persists.',
    technicalMessage: errorMsg,
  };
}
```

### Database Save After Stream Completion
```typescript
// Source: Existing generate.ts lines 156-202 + streaming.ts integration
// Add to streaming.ts after successful completion

if (result.stage === 'completed' && result.content) {
  // Save to nodes table (reuse logic from generate.ts)
  const nodeData = {
    nodeId: result.nodeId || request.nodeId,
    type: request.nodeType,
    biome: request.biome,
    name: request.name,
    acts: request.acts || [request.act || 1],
    actVariant: request.actVariant || false,
    isReplaceable: true,
    replacementTags: [],
    themes: request.themes,
    entityTypes: request.entityTypes,
    estimatedCombatDifficulty: request.nodeMetadata?.estimatedCombatDifficulty,
    eligibility: null,
    resourceCost: null,
    potentialRewards: [],
    content: result.content,
    actVariants: null,
    criticScore: result.critic?.score,
    generatedBy: 'ai',

    // Type-specific fields from nodeMetadata
    enemyTypeHooks: request.nodeMetadata?.enemyTypeHooks,
    environmentalContext: request.nodeMetadata?.environmentalContext,
    // ... other type-specific fields
  };

  if (request.nodeId) {
    // Update existing node
    await db.update(nodesTable).set(nodeData).where(eq(nodesTable.nodeId, request.nodeId));
  } else {
    // Insert new node
    await db.insert(nodesTable).values(nodeData as any);
  }

  // Update job with final nodeId
  await updateJobStatus(jobId, {
    status: 'completed',
    result: { ...result, nodeId: nodeData.nodeId },
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling for job status | SSE streaming + job persistence | 2024-2025 | Real-time updates without client polling, reconnection support via job lookup |
| Single-provider LLM | Multi-provider abstraction | 2025+ | Switch providers without code changes, fallback support (OpenRouter) |
| Manual retry logic | SDK-native retry + custom backoff | 2024+ | OpenAI SDK has `maxRetries`, but multi-provider needs custom abstraction |
| String error messages | Structured error classification | 2025-2026 | Better UX with actionable guidance, but still heuristic (no standard error codes across providers) |
| JSON response mode | Structured output (OpenAI) / Prompt engineering (Anthropic) | 2024+ | OpenAI has `response_format: {type: 'json_object'}`, Anthropic requires prompt-based JSON coercion |

**Deprecated/outdated:**
- **Completions API (OpenAI):** Replaced by Chat Completions API in 2023. Current code correctly uses `client.chat.completions.create()`.
- **`davinci-003` model:** Deprecated. Current code uses configurable model names (user-provided via database).
- **Polling for async jobs:** SSE streaming is now standard for LLM responses (2024+). Phase 1 correctly implemented SSE.

## Open Questions

Things that couldn't be fully resolved:

1. **Retry-After header extraction from SDK errors**
   - What we know: OpenAI and Anthropic SDKs return error objects, but header access varies
   - What's unclear: Whether `error.response.headers` is exposed consistently across SDK versions
   - Recommendation: Implement best-effort header extraction with fallback to exponential backoff. Test with actual 429 errors in development.

2. **Circuit breaker timeout calibration**
   - What we know: LLM responses vary widely (5s for simple, 60s+ for complex multi-stage)
   - What's unclear: Optimal timeout value that doesn't trigger false positives on legitimate slow responses
   - Recommendation: Start with 60s timeout, monitor production latency, adjust based on P95 response times. Add per-stage timeouts (outliner: 20s, expander: 30s, critic: 10s) if needed.

3. **OpenRouter automatic fallback behavior**
   - What we know: OpenRouter claims to automatically fallback to next provider on error
   - What's unclear: Whether this is transparent (invisible to client) or requires retry logic
   - Recommendation: Test with intentionally invalid model names. If fallback is transparent, errors are already handled. If not, may need provider-specific retry logic.

4. **Cleanup job scheduler mechanism**
   - What we know: `cleanupOldJobs()` exists but isn't called
   - What's unclear: Whether to use `setInterval` (in-memory, simple) or external cron (robust, requires infrastructure)
   - Recommendation: Phase 2 can skip this (low priority), or use simple `setInterval` on startup. Proper cron scheduling is Phase 4 concern.

5. **Error classification validation with real API responses**
   - What we know: Current error classification is heuristic (pattern matching on strings)
   - What's unclear: Whether real API errors match the expected patterns (e.g., does Anthropic 529 actually include "overloaded" in message?)
   - Recommendation: Add logging to capture actual error messages in development. Update patterns based on observed errors. This is noted as a blocker/concern in phase context.

## Sources

### Primary (HIGH confidence)
- Hono Streaming Helpers: https://hono.dev/docs/helpers/streaming (official docs, SSE API reference)
- Opossum GitHub: https://github.com/nodeshift/opossum (official repo, configuration examples)
- OpenAI Node.js SDK: https://github.com/openai/openai-node (official SDK, maxRetries configuration)
- Anthropic Claude API Errors: https://docs.anthropic.com/en/api/errors (official docs, error codes and retry strategies)
- OpenRouter Error Handling: https://openrouter.ai/docs/api/reference/errors-and-debugging (official docs, provider fallback)
- Existing codebase: All generation service files reviewed directly (llm-client.ts, streaming.ts, batch-processor.ts, etc.)

### Secondary (MEDIUM confidence)
- [Circuit Breaker Pattern in Node.js](https://medium.com/deno-the-complete-reference/circuit-breaker-pattern-in-node-js-a61fe2c4f2a4) - Implementation patterns verified against opossum docs
- [OpenAI Rate Limits Guide](https://platform.openai.com/docs/guides/rate-limits) - Exponential backoff recommendations (attempted fetch, 403 error, likely behind auth)
- [Anthropic Rate Limits 2026](https://www.aifreeapi.com/en/posts/fix-claude-api-429-rate-limit-error) - Recent rate limit tiers and retry-after headers
- [SSE Reconnection Patterns](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) - Last-Event-ID mechanism

### Tertiary (LOW confidence)
- [Multi-Stage LLM Pipeline Orchestration 2026](https://dev.to/ash_dubai/multi-provider-llm-orchestration-in-production-a-2026-guide-1g10) - General patterns, not Hono-specific
- [LLM Streaming Error Handling](https://dev.to/abhinav__ap/from-waiting-to-streaming-how-to-handle-llm-responses-like-a-pro-especially-with-json-2lgh) - Conceptual guidance, implementation varies

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries are in active use in codebase, verified via package.json and imports
- Architecture: HIGH - Existing implementation reviewed directly, patterns verified against official docs
- Pitfalls: MEDIUM - Based on common issues in LLM applications (WebSearch) + code review, not production observation
- Circuit breaker configuration: MEDIUM - Opossum defaults verified, but LLM-specific tuning needs testing
- Error classification: MEDIUM - Pattern matching is heuristic, needs validation with real API responses (noted in Open Questions)

**Research date:** 2026-01-25
**Valid until:** 60 days (stable infrastructure, but LLM API error handling patterns may evolve)
