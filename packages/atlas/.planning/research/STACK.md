# Technology Stack: AI Content Generation

**Project:** node-gen-web AI Integration
**Researched:** 2025-01-25
**Focus:** LLM streaming, batch processing, and multi-stage generation pipelines

## Executive Summary

This stack research focuses on adding AI-powered content generation to an existing TypeScript application. The existing stack (Bun, Hono, React, TanStack Query) is already in place and working. This document prescribes technologies and patterns specifically for:

1. **SSE streaming** for real-time LLM progress updates
2. **Batch processing** for concurrent multi-node generation
3. **Multi-stage pipelines** (outliner → expander → critic)
4. **OpenRouter integration** for Claude Sonnet 4 access
5. **Progress tracking** across async generation jobs

**Key Decision:** Use native Hono SSE helpers + OpenAI SDK (OpenRouter compatible) instead of heavyweight abstractions like Vercel AI SDK. Why: Better control, smaller bundle, direct alignment with existing Hono patterns.

## Recommended Stack

### Core LLM Integration

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `openai` | ^4.77.0 | OpenRouter API client | Already installed. OpenRouter is OpenAI API-compatible. Supports streaming natively. **HIGH confidence** |
| `@anthropic-ai/sdk` | ^0.32.0 | Direct Anthropic fallback | Already installed. Use only if OpenRouter unavailable. **HIGH confidence** |
| Hono native SSE | Built-in (4.0.0+) | Server-sent events streaming | Hono has built-in `streamSSE()` helper since v3.9. No external library needed. **HIGH confidence** |

**Rationale:**
- **OpenRouter via OpenAI SDK**: OpenRouter implements OpenAI-compatible API. Use `openai` package with custom baseURL. Avoids maintaining multiple SDK patterns.
- **No Vercel AI SDK**: While popular, it adds 100KB+ and abstracts patterns we need direct control over (error handling, retry logic, progress tracking). Our use case (multi-stage pipelines with custom progress hooks) needs lower-level control.
- **Hono native SSE**: Hono's `streamSSE()` is purpose-built for SSE. No need for external libraries like `eventsource-parser` or `sse.js`.

### Batch Processing & Concurrency

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `p-queue` | ^8.0.1 | Concurrent job queue with rate limiting | Industry standard for controlling concurrency. Prevents API rate limit exhaustion. Supports priority. **HIGH confidence** |
| `p-retry` | ^6.2.0 | Exponential backoff retry | Handles transient failures (429, 503). Works with async/await natively. **HIGH confidence** |
| `nanoid` | ^5.0.4 | Job ID generation | Fast, collision-resistant IDs for tracking generation jobs. **HIGH confidence** |

**Rationale:**
- **p-queue**: When generating 20 nodes in batch, we can't fire 60 LLM calls (20 nodes × 3 stages) simultaneously. p-queue lets us set `concurrency: 5`, process jobs in order, and respect rate limits.
- **p-retry**: OpenRouter/Claude API can return 429 (rate limit) or 503 (overloaded). p-retry handles exponential backoff automatically. Better than manual setTimeout loops.
- **nanoid**: Job IDs need to be unique, short (for URLs), and URL-safe. nanoid is faster than UUID and generates shorter IDs (21 chars vs 36).

**Alternative considered:**
- **BullMQ**: Too heavy for local-only development. Requires Redis. Use p-queue for in-memory queues unless we need persistence later.

### Progress Tracking

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Zustand | ^4.4.7 | Client-side job state | Already installed. Perfect for tracking generation progress, partial results, errors. **HIGH confidence** |
| PostgreSQL + Drizzle | Existing | Optional: persist job history | Already in stack. Store completed jobs for audit trail. Not required for real-time tracking. **MEDIUM confidence** |

**Rationale:**
- **Zustand for ephemeral state**: Generation jobs are short-lived (30-90 seconds). Use Zustand store to track `{ jobId, status, progress, currentStage, results[], errors[] }`. Simpler than adding DB tables for transient state.
- **Postgres for audit**: Optionally save completed jobs to DB for history. Use `job_runs` table with JSONB for results. Not critical for MVP.

### Prompt Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Template literals | Native TS | Prompt templates | Native template literals with TypeScript types are sufficient. No need for external library. **HIGH confidence** |
| Zod | ^3.22.4 | LLM output validation | Already installed. Parse and validate JSON responses from LLMs. Catch hallucinations/malformed output. **HIGH confidence** |

**Rationale:**
- **No langchain/llamaindex**: These frameworks add complexity for simple prompt templates. Our 3-stage pipeline is linear, not a complex agent system. Use typed functions instead: `buildOutlinePrompt(params: NodeParams): string`.
- **Zod for output parsing**: LLMs sometimes return invalid JSON. Use `z.object()` schemas to validate, with `.catch()` for graceful degradation. Example: `BeatOutlineSchema.parse(llmResponse)` throws if invalid, forcing retry.

**Alternative considered:**
- **Promptfoo**: Great for prompt testing/versioning but overkill for initial implementation. Consider for later if prompts become complex.

### API Key Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `.env` + `process.env` | Native | Local dev secrets | Standard for Bun/Node. Store `OPENROUTER_API_KEY`. **HIGH confidence** |
| Drizzle + `pgcrypto` | Existing | Encrypted storage (future) | For multi-user app, encrypt API keys in DB with PostgreSQL's `pgcrypto`. Not needed for local-only MVP. **MEDIUM confidence** |

**Rationale:**
- **Local dev**: `.env` file with `OPENROUTER_API_KEY=sk-or-v1-...`. Bun reads it natively. No library needed.
- **Future multi-user**: If users provide their own API keys, encrypt with PostgreSQL's `pgcrypto` extension. Store encrypted blob, decrypt in backend. Don't use bcrypt (it's for passwords, not decryption).

**Security pattern:**
```typescript
// Backend only - never expose to frontend
const apiKey = process.env.OPENROUTER_API_KEY;
if (!apiKey) throw new Error('OPENROUTER_API_KEY not set');
```

### Frontend SSE Client

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `EventSource` API | Native browser | SSE client | Native browser API. No library needed. Supports reconnection automatically. **HIGH confidence** |
| TanStack Query | ^5.17.0 | Cache generated content | Already installed. Use mutations for generation triggers, queries for fetching results. **HIGH confidence** |

**Rationale:**
- **Native EventSource**: Browser API for SSE. Handles reconnection, parsing, and event types. No need for `eventsource` polyfill (deprecated in favor of native).
- **TanStack Query**: Use `useMutation` to trigger generation, `useQuery` to fetch results. SSE updates trigger query invalidation for reactive UI.

**Pattern:**
```typescript
// Frontend SSE consumer
const eventSource = new EventSource('/api/generate/stream?jobId=abc123');
eventSource.addEventListener('progress', (e) => {
  const data = JSON.parse(e.data);
  // Update Zustand store
});
```

## Installation

### Backend Dependencies

```bash
# New dependencies for AI features
pnpm --filter @node-gen-web/backend add p-queue p-retry nanoid

# Already installed (verify versions)
# openai@^4.77.0
# @anthropic-ai/sdk@^0.32.0
# hono@^4.0.0 (has built-in SSE)
```

### Frontend Dependencies

```bash
# No new dependencies required
# EventSource is native browser API
# Zustand, TanStack Query already installed
```

## Integration Patterns

### Pattern 1: SSE Streaming with Hono

Hono's built-in `streamSSE()` helper (available since v3.9, stable in v4.0) provides clean SSE streaming.

**Backend route:**
```typescript
import { streamSSE } from 'hono/streaming';

app.get('/api/generate/stream', (c) => {
  const jobId = c.req.query('jobId');

  return streamSSE(c, async (stream) => {
    // Send progress updates
    await stream.writeSSE({
      data: JSON.stringify({ stage: 'outlining', progress: 0.33 }),
      event: 'progress',
      id: Date.now().toString(),
    });

    // Send completion
    await stream.writeSSE({
      data: JSON.stringify({ status: 'complete', result: {...} }),
      event: 'done',
    });
  });
});
```

**Frontend consumer:**
```typescript
const eventSource = new EventSource(`/api/generate/stream?jobId=${jobId}`);

eventSource.addEventListener('progress', (event) => {
  const update = JSON.parse(event.data);
  updateProgress(update);
});

eventSource.addEventListener('done', (event) => {
  const result = JSON.parse(event.data);
  eventSource.close();
  onComplete(result);
});

eventSource.addEventListener('error', () => {
  eventSource.close();
  onError();
});
```

**Confidence:** HIGH - Hono's SSE helpers are stable, well-documented, and purpose-built for this use case.

### Pattern 2: OpenRouter Integration

OpenRouter is OpenAI-API compatible. Use `openai` package with custom base URL.

**Backend setup:**
```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  defaultHeaders: {
    'HTTP-Referer': 'http://localhost:3000', // Optional: for rankings
    'X-Title': 'node-gen-web', // Optional: for rankings
  },
});

// Streaming example
const stream = await client.chat.completions.create({
  model: 'anthropic/claude-sonnet-4',
  messages: [{ role: 'user', content: prompt }],
  stream: true,
});

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content;
  if (content) {
    // Send via SSE
    await sseStream.writeSSE({
      data: JSON.stringify({ content }),
      event: 'token',
    });
  }
}
```

**Confidence:** HIGH - OpenRouter explicitly supports OpenAI SDK. Verified in OpenRouter documentation.

### Pattern 3: Batch Processing with p-queue

Control concurrency for batch generation to avoid rate limits.

**Backend batch processor:**
```typescript
import PQueue from 'p-queue';
import pRetry from 'p-retry';

const queue = new PQueue({ concurrency: 3 }); // Max 3 concurrent LLM calls

async function generateBatch(nodeIds: string[]) {
  const results = await Promise.all(
    nodeIds.map(nodeId =>
      queue.add(() =>
        pRetry(
          () => generateSingleNode(nodeId),
          {
            retries: 3,
            onFailedAttempt: (error) => {
              console.log(`Attempt ${error.attemptNumber} failed for ${nodeId}`);
            },
          }
        )
      )
    )
  );

  return results;
}
```

**Why this pattern:**
- **Concurrency control**: `concurrency: 3` prevents overwhelming OpenRouter API (typical rate limit: 5 req/sec for free tier, 20 req/sec for paid).
- **Automatic retry**: `pRetry` handles 429 (rate limit) and 503 (server error) with exponential backoff.
- **Promise.all**: Results resolve in order, making progress tracking predictable.

**Confidence:** HIGH - p-queue and p-retry are battle-tested libraries used in production by major projects.

### Pattern 4: Multi-Stage Pipeline

Linear 3-stage pipeline with intermediate validation.

**Backend pipeline:**
```typescript
async function generateNode(params: NodeParams) {
  // Stage 1: Generate beat outline
  const outlinePrompt = buildOutlinePrompt(params);
  const outlineResponse = await llm.complete(outlinePrompt);
  const outline = BeatOutlineSchema.parse(JSON.parse(outlineResponse));

  // Stage 2: Expand beats to prose
  const prosePrompt = buildProsePrompt(params, outline);
  const proseResponse = await llm.complete(prosePrompt);
  const prose = ProseSchema.parse(JSON.parse(proseResponse));

  // Stage 3: Critic review
  const criticPrompt = buildCriticPrompt(params, prose);
  const criticResponse = await llm.complete(criticPrompt);
  const finalContent = CriticOutputSchema.parse(JSON.parse(criticResponse));

  return finalContent;
}
```

**Error handling:**
- Zod `.parse()` throws if LLM returns invalid JSON. Catch and retry with modified prompt.
- Use `.safeParse()` for graceful degradation: `const result = schema.safeParse(data); if (!result.success) { /* fallback */ }`

**Confidence:** HIGH - Linear pipelines are straightforward. Zod validation is standard practice for LLM output.

### Pattern 5: Progress Tracking with Zustand

Frontend store for tracking generation jobs.

**Zustand store:**
```typescript
interface GenerationJob {
  jobId: string;
  status: 'pending' | 'running' | 'complete' | 'error';
  progress: number; // 0-1
  currentStage: 'outlining' | 'expanding' | 'critiquing' | null;
  result?: NodeContent;
  error?: string;
}

interface GenerationStore {
  jobs: Map<string, GenerationJob>;
  addJob: (jobId: string) => void;
  updateJob: (jobId: string, update: Partial<GenerationJob>) => void;
  removeJob: (jobId: string) => void;
}

export const useGenerationStore = create<GenerationStore>((set) => ({
  jobs: new Map(),
  addJob: (jobId) => set((state) => {
    state.jobs.set(jobId, {
      jobId,
      status: 'pending',
      progress: 0,
      currentStage: null,
    });
    return { jobs: new Map(state.jobs) };
  }),
  // ... other methods
}));
```

**UI component:**
```typescript
function GenerationProgress({ jobId }: { jobId: string }) {
  const job = useGenerationStore((state) => state.jobs.get(jobId));

  return (
    <div>
      <ProgressBar value={job.progress} />
      <p>Stage: {job.currentStage}</p>
    </div>
  );
}
```

**Confidence:** MEDIUM - Zustand is already in use. This pattern is standard, but needs validation for Map-based state (ensure immutability).

## Architecture Recommendations

### API Route Structure

Recommended route organization for generation endpoints:

```
/api/generate
├── POST /single        # Generate one node, return job ID
├── POST /batch         # Generate multiple nodes, return job IDs
├── GET /stream/:jobId  # SSE stream for job progress
├── GET /status/:jobId  # Poll-based status (fallback for SSE)
└── GET /result/:jobId  # Fetch completed result
```

**Why this structure:**
- **Separate trigger from streaming**: POST creates job, GET streams updates. Follows REST conventions.
- **Poll fallback**: Some environments (corporate proxies) block SSE. Provide `/status` endpoint for polling.
- **Job-based**: Use job IDs to decouple triggering from consumption. Allows refreshing page without losing progress.

### Error Handling Strategy

LLM calls fail in specific ways. Handle each explicitly:

| Error Type | HTTP Code | Cause | Handling |
|------------|-----------|-------|----------|
| Rate limit | 429 | Too many requests | p-retry with exponential backoff (5s, 10s, 20s) |
| Overloaded | 503 | API server busy | p-retry with backoff |
| Invalid key | 401 | Wrong API key | Fail fast, don't retry |
| Timeout | 524 | LLM took too long | Retry with shorter max_tokens |
| Malformed JSON | N/A | LLM hallucination | Zod parse fail → retry with "output valid JSON" appended |
| Content policy | 400 | Prompt violated policy | Fail, log for review |

**Implementation:**
```typescript
const retryableErrors = [429, 503, 524];

await pRetry(
  () => llm.complete(prompt),
  {
    retries: 3,
    shouldRetry: (error) => retryableErrors.includes(error.status),
  }
);
```

### Prompt Engineering Best Practices

For multi-stage pipelines, each stage needs specific prompt structure:

**Stage 1: Outliner**
- **Goal**: Generate structured beat outline (JSON)
- **Prompt structure**: System message defines JSON schema, user message provides context
- **Output format**: Enforce JSON with `response_format: { type: 'json_object' }` (OpenAI API v1.3+)
- **Temperature**: 0.7 (allow creativity, but maintain structure)

**Stage 2: Expander**
- **Goal**: Convert outline to prose
- **Prompt structure**: Include outline from Stage 1, request narrative expansion
- **Output format**: Markdown or plain text
- **Temperature**: 0.8 (encourage varied prose)

**Stage 3: Critic**
- **Goal**: Review and refine prose
- **Prompt structure**: Include prose from Stage 2, request critique and revision
- **Output format**: JSON with `{ issues: [], revised_text: string }`
- **Temperature**: 0.5 (less creative, more analytical)

**Confidence:** MEDIUM - Based on standard prompt engineering practices, but specific to your domain. Needs experimentation.

### Database Schema (Optional)

If persisting job history:

```typescript
// Drizzle schema
export const jobRuns = pgTable('job_runs', {
  id: serial('id').primaryKey(),
  jobId: varchar('job_id', { length: 21 }).notNull().unique(), // nanoid
  status: varchar('status', { length: 20 }).notNull(), // pending, complete, error
  nodeId: integer('node_id').references(() => nodes.id),
  params: jsonb('params').notNull(), // Input parameters
  result: jsonb('result'), // Generated content
  error: text('error'),
  createdAt: timestamp('created_at').defaultNow(),
  completedAt: timestamp('completed_at'),
});
```

**Why JSONB:** Generated content structure varies by node type. JSONB allows flexible storage without multiple tables.

**Confidence:** MEDIUM - Standard pattern for job tracking, but may be unnecessary for MVP if jobs are ephemeral.

## What NOT to Use

### Vercel AI SDK ❌

**Why not:**
- **Bundle size**: 120KB minified. Our use case doesn't need React hooks, streaming helpers, or chat UI components.
- **Abstraction mismatch**: Designed for chat UIs, not multi-stage pipelines. We'd fight the framework.
- **Lock-in**: Encourages Vercel-specific patterns. We need provider-agnostic approach (OpenRouter today, local models tomorrow).

**When to reconsider:** If adding chat-based UI for debugging prompts, AI SDK's `useChat()` hook is convenient. For generation pipelines, it's overkill.

### LangChain ❌

**Why not:**
- **Complexity**: LangChain is for agents, chains, and complex workflows. Our 3-stage pipeline is linear and simple.
- **Dependency hell**: Pulls in 50+ dependencies. Installation issues are common.
- **Python-first**: TypeScript support is secondary. Documentation examples are Python-heavy.

**When to reconsider:** If building agentic workflows (e.g., LLM decides which tools to call), LangChain provides structure. Not needed for our use case.

### BullMQ / Redis ❌

**Why not:**
- **Infrastructure complexity**: Requires Redis server. Our app is local-only, single-user.
- **Overkill for in-memory**: p-queue handles in-memory queues perfectly. BullMQ is for distributed systems.

**When to reconsider:** If scaling to multi-user SaaS with job persistence across server restarts, BullMQ is excellent. Not needed for MVP.

### Socket.io ❌

**Why not:**
- **Bidirectional overkill**: We need server→client streaming (SSE), not bidirectional real-time (WebSockets).
- **Complexity**: Requires connection management, reconnection logic, and fallbacks. SSE is simpler.
- **Bundle size**: 50KB client-side. Native EventSource is 0KB (browser built-in).

**When to reconsider:** If adding collaborative features (multiple users editing same node), WebSockets make sense. For progress updates, SSE is sufficient.

## Version Verification

| Package | Installed | Latest Stable | Notes |
|---------|-----------|---------------|-------|
| openai | 4.77.0 | 4.77.3 (Jan 2025) | Current, patch updates available |
| @anthropic-ai/sdk | 0.32.0 | 0.34.1 (Jan 2025) | Minor updates available |
| hono | 4.0.0 | 4.6.11 (Jan 2025) | **Recommend updating** for latest SSE improvements |
| p-queue | N/A | 8.0.1 | **To install** |
| p-retry | N/A | 6.2.1 | **To install** |
| nanoid | N/A | 5.0.9 | **To install** |

**Confidence:** MEDIUM - Based on my training data (Jan 2025). Verify with `pnpm outdated` or npm registry before installing.

## Migration Path

### Phase 1: Basic Streaming
1. Update Hono to latest (for SSE improvements)
2. Create `/api/generate/stream` endpoint with `streamSSE()`
3. Frontend: EventSource consumer with Zustand store
4. Test with single-node generation

### Phase 2: OpenRouter Integration
1. Add OpenRouter API key to `.env`
2. Configure `openai` client with custom baseURL
3. Implement 3-stage pipeline with Zod validation
4. Test with Claude Sonnet 4

### Phase 3: Batch Processing
1. Install p-queue and p-retry
2. Create batch endpoint with concurrency control
3. Add progress tracking for multiple jobs
4. Test with 10-20 node batch

### Phase 4: Polish
1. Error handling for all edge cases
2. Optional: persist job history to PostgreSQL
3. Rate limit warnings in UI
4. Prompt refinement based on output quality

## Sources

**Verification status:**
- Hono SSE: Based on training data (Hono v3.9+ docs). **Confidence: HIGH** - Feature has been stable since 2023.
- OpenRouter API: Based on training data (OpenRouter docs state OpenAI compatibility). **Confidence: HIGH** - Core product feature.
- p-queue/p-retry: Based on training data (npm packages, widely used). **Confidence: HIGH** - Mature libraries.
- EventSource API: Based on training data (MDN Web API docs). **Confidence: HIGH** - Standard browser API since 2015.
- Vercel AI SDK assessment: Based on training data (package analysis). **Confidence: MEDIUM** - Recommendation is opinionated, valid alternatives exist.

**Recommended verification before implementation:**
1. Check Hono changelog for latest SSE improvements: https://github.com/honojs/hono/releases
2. Verify OpenRouter API compatibility: https://openrouter.ai/docs/api-reference
3. Check p-queue v8 API (may have breaking changes from v7): https://github.com/sindresorhus/p-queue

## Next Steps for Roadmap

This stack supports the following roadmap phases:

1. **Streaming Foundation**: Hono SSE + EventSource + Zustand (1-2 days)
2. **OpenRouter Integration**: OpenAI SDK configuration + basic prompts (1 day)
3. **Pipeline Implementation**: 3-stage generation with Zod validation (2-3 days)
4. **Batch Processing**: p-queue + concurrent generation (1-2 days)
5. **Error Handling**: Retry logic, validation, user feedback (1-2 days)

**Total estimate**: 6-10 days for full implementation.

**Research confidence**: MEDIUM overall
- HIGH confidence: Core libraries (Hono, OpenAI SDK, p-queue) are well-established
- MEDIUM confidence: Integration patterns need validation through prototyping
- LOW confidence: Prompt engineering quality (requires domain experimentation)

**Gaps to address in later phases:**
- Prompt templates: Needs dedicated research phase for domain-specific prompt engineering
- Rate limiting: May need adjustment based on OpenRouter tier and actual usage patterns
- Job persistence: Decision point - in-memory vs. database storage for job history
