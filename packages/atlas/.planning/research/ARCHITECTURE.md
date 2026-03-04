# Architecture Patterns for LLM Content Generation Systems

**Domain:** LLM-powered narrative content generation for web applications
**Researched:** 2026-01-25
**Confidence:** HIGH (based on existing implementation analysis and Claude training on LLM integration patterns)

## Executive Summary

LLM content generation systems in web applications follow a **pipeline architecture** with clear separation between request handling, LLM orchestration, streaming transport, and client state management. The architecture divides into four primary layers:

1. **Generation Pipeline** - Multi-stage LLM orchestration (beat outliner → prose expander → critic)
2. **Streaming Layer** - Server-Sent Events (SSE) for real-time progress updates
3. **State Management** - Frontend handling of async generation state and progressive updates
4. **Persistence Layer** - Database storage of generated content with validation

This architecture supports both synchronous (wait for completion) and streaming (real-time updates) generation modes, enabling responsive UIs that show progress during long-running LLM operations.

## Recommended Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (React)                         │
├─────────────────────────────────────────────────────────────────┤
│  UI Components                                                    │
│  ├── GenerationProgress (shows stage/progress/content)           │
│  ├── QuickGenerate (minimal input → full generation)             │
│  ├── AssistedCreate (hybrid manual + AI assists)                 │
│  └── BulkGenerate (batch with distribution gaps)                 │
├─────────────────────────────────────────────────────────────────┤
│  State Management                                                 │
│  ├── useGeneration hook (SSE stream consumer)                    │
│  ├── TanStack Query (server state cache)                         │
│  └── Zustand (local form/UI state)                               │
├─────────────────────────────────────────────────────────────────┤
│  Streaming Client                                                 │
│  └── EventSource wrapper (SSE connection, retry logic)           │
└─────────────────────────────────────────────────────────────────┘
                              ▼ HTTP / SSE
┌─────────────────────────────────────────────────────────────────┐
│                      Backend (Hono API)                          │
├─────────────────────────────────────────────────────────────────┤
│  API Routes                                                       │
│  ├── POST /api/generate/node (single, streaming SSE)             │
│  ├── POST /api/generate/bulk (batch, poll status)                │
│  └── GET /api/generate/status/:jobId (batch progress)            │
├─────────────────────────────────────────────────────────────────┤
│  Generation Pipeline (services/generation/)                       │
│  ├── Prompt Builder (compositional prompts from config)          │
│  ├── Beat Outliner (Stage 1: structured beats)                   │
│  ├── Prose Expander (Stage 2: full narrative)                    │
│  ├── Critic (Stage 3: quality scoring 0-100)                     │
│  └── Batch Processor (concurrent generation with callbacks)      │
├─────────────────────────────────────────────────────────────────┤
│  LLM Client Layer                                                 │
│  ├── Provider abstraction (OpenAI/OpenRouter/Anthropic)          │
│  ├── Retry logic with exponential backoff                        │
│  ├── Token counting and rate limiting                            │
│  └── Error normalization across providers                        │
├─────────────────────────────────────────────────────────────────┤
│  Streaming Layer                                                  │
│  ├── SSE stream creation (ReadableStream)                        │
│  ├── Progress callback routing                                   │
│  └── Message formatting (event types: progress/stage/complete)   │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Database (PostgreSQL)                          │
├─────────────────────────────────────────────────────────────────┤
│  Config Tables                                                    │
│  ├── llm_providers (API keys, model configs)                     │
│  ├── generation_settings (batch size, thresholds)                │
│  ├── beat_sequences (prompt templates)                           │
│  └── style_guide (biome-specific guidance)                       │
├─────────────────────────────────────────────────────────────────┤
│  Content Tables                                                   │
│  ├── nodes (generated narrative content)                         │
│  └── generation_jobs (batch tracking)                            │
└─────────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LLM Providers (External)                      │
│  ├── OpenRouter (Claude, GPT-4, etc.)                            │
│  ├── OpenAI API                                                   │
│  └── Anthropic API                                                │
└─────────────────────────────────────────────────────────────────┘
```

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Generation Pipeline** | Orchestrate 3-stage LLM generation, manage retries, quality gates | LLM Client, Prompt Builder, Streaming Layer |
| **LLM Client** | Abstract provider differences, handle auth/retry/errors | External LLM APIs, Database (config) |
| **Prompt Builder** | Compose prompts from templates + context + config | Database (style guide, beat sequences, config) |
| **Streaming Layer** | Convert progress callbacks to SSE messages | API Routes, Generation Pipeline |
| **Batch Processor** | Concurrent generation with throttling, progress aggregation | Generation Pipeline, Database (job tracking) |
| **Frontend State** | Manage async generation state, reconnect on disconnect | Streaming Client, TanStack Query cache |
| **Streaming Client** | Consume SSE, parse events, handle reconnection | API Routes (SSE endpoint) |

---

## Data Flow Patterns

### Pattern 1: Single Node Generation (Streaming)

```
User clicks "Generate"
  → Frontend: dispatch generation request
  → Frontend: establish SSE connection to /api/generate/node/stream
  → Backend: validate request with Zod
  → Backend: create SSE ReadableStream
  → Backend: start generation pipeline asynchronously

Generation Pipeline:
  Stage 1: Beat Outliner
    → Prompt Builder: compose prompt from templates + context
    → LLM Client: call provider API with retry logic
    → Return: structured beat outline (JSON)
    → Progress callback: { stage: 'outlining', progress: 33 }
    → SSE: send progress event to frontend

  Stage 2: Prose Expander
    → Prompt Builder: compose expansion prompt with outline
    → LLM Client: call provider API
    → Return: full narrative prose
    → Progress callback: { stage: 'expanding', progress: 66 }
    → SSE: send progress event

  Stage 3: Critic
    → Prompt Builder: compose critique prompt with content
    → LLM Client: call provider API
    → Return: quality score 0-100 + feedback
    → Progress callback: { stage: 'reviewing', progress: 100 }
    → SSE: send progress event

  Quality Gate:
    IF score >= threshold (default 70):
      → SSE: send 'complete' event with full content
      → Backend: save to database
      → Frontend: update cache, show success
    ELSE:
      → SSE: send 'error' event with critic feedback
      → Frontend: offer retry with feedback

  → SSE: close stream
  → Frontend: close EventSource connection
```

### Pattern 2: Bulk Generation (Batch Processing)

```
User clicks "Generate Missing Nodes"
  → Frontend: fetch distribution gaps from /api/config/distributions/gaps
  → Frontend: show gap chart, user confirms
  → Frontend: POST /api/generate/bulk with node specs

Backend Batch Processing:
  → Validate bulk request
  → Create job record in database (status: 'queued')
  → Return job ID immediately (202 Accepted)
  → Start async batch processing

Batch Processor:
  → Split requests into batches (default: 5 concurrent)
  → For each batch:
    → Launch concurrent generations (Promise.all)
    → Aggregate progress callbacks
    → Update job status in database
    → On batch complete: move to next batch

Frontend Polling:
  → Poll GET /api/generate/status/:jobId every 2 seconds
  → Display: "Generated 12/30 nodes (40%)"
  → On completion: invalidate TanStack Query cache
  → Redirect to node list with filters for new nodes
```

### Pattern 3: Assisted Create (Hybrid Manual + AI)

```
User in manual form, clicks "Generate Hook" button
  → Frontend: gather current form context (type, biome, themes)
  → Frontend: POST /api/generate/assist with field='narrative_hook'
  → Backend: minimal generation (single LLM call, no pipeline)
  → Backend: return generated text synchronously
  → Frontend: populate form field, user can edit

Field-level assists:
  - "Generate Hook" → narrative_hook field
  - "Suggest Beats" → beats array
  - "Enhance Mood" → mood descriptors

Key difference from full generation:
  - Single LLM call (not 3-stage pipeline)
  - Synchronous response (not streamed)
  - User retains full control (can edit/discard)
```

---

## Patterns to Follow

### Pattern 1: SSE for Real-Time Progress

**What:** Server-Sent Events (SSE) as unidirectional push from server to client for progress updates

**When:** Long-running operations (>2 seconds) where user needs feedback

**Why:**
- Simpler than WebSockets (no bidirectional overhead)
- Automatic reconnection in EventSource API
- Works through standard HTTP (no special server requirements)
- Browser native support

**Implementation:**

**Backend (Hono):**
```typescript
// Create SSE stream
export function createSSEStream(c: Context, request: GenerationRequest) {
  c.header('Content-Type', 'text/event-stream');
  c.header('Cache-Control', 'no-cache');
  c.header('Connection', 'keep-alive');

  const encoder = new TextEncoder();
  let controller: ReadableStreamDefaultController;

  const stream = new ReadableStream({
    start(ctrl) {
      controller = ctrl;
      // Send initial message
      controller.enqueue(encoder.encode(formatSSE({
        type: 'progress',
        data: { stage: 'outlining', progress: 0 }
      })));
    }
  });

  // Start async generation with progress callbacks
  generateSingle(request, {
    onProgress: (progress) => {
      controller.enqueue(encoder.encode(formatSSE({
        type: 'progress',
        data: progress
      })));
    }
  }).then(result => {
    controller.enqueue(encoder.encode(formatSSE({
      type: 'complete',
      data: result
    })));
    controller.close();
  });

  return stream;
}
```

**Frontend (React):**
```typescript
function useGeneration() {
  const [state, setState] = useState<GenerationState>({
    stage: 'idle',
    progress: 0,
  });

  const generate = useCallback((request: GenerationRequest) => {
    const eventSource = new EventSource(
      `/api/generate/node/stream?${new URLSearchParams(request)}`
    );

    eventSource.addEventListener('progress', (e) => {
      const data = JSON.parse(e.data);
      setState(prev => ({ ...prev, ...data }));
    });

    eventSource.addEventListener('complete', (e) => {
      const data = JSON.parse(e.data);
      setState({ stage: 'completed', progress: 100, content: data });
      eventSource.close();
    });

    eventSource.addEventListener('error', (e) => {
      console.error('SSE error:', e);
      eventSource.close();
    });

    return () => eventSource.close();
  }, []);

  return { state, generate };
}
```

### Pattern 2: Progress Callbacks Throughout Pipeline

**What:** Callback functions passed through pipeline stages to report incremental progress

**When:** Multi-stage async operations where each stage has measurable progress

**Why:**
- Decouples progress reporting from business logic
- Enables testing without SSE infrastructure
- Allows multiple consumers (SSE, logs, metrics)

**Implementation:**

```typescript
export interface ProgressCallback {
  onProgress?: (progress: GenerationProgress) => void;
}

export interface GenerationProgress {
  nodeId: string;
  stage: 'outlining' | 'expanding' | 'reviewing' | 'completed' | 'failed';
  progress: number; // 0-100
  message?: string;
  partialContent?: any;
}

export async function generateSingle(
  request: GenerationRequest,
  callbacks?: ProgressCallback
): Promise<GenerationResult> {
  const { onProgress } = callbacks || {};

  // Stage 1: Beat Outliner
  onProgress?.({
    nodeId: request.nodeId,
    stage: 'outlining',
    progress: 10,
    message: 'Generating beat structure...'
  });

  const outline = await beatOutliner.generate(request);

  onProgress?.({
    nodeId: request.nodeId,
    stage: 'outlining',
    progress: 33,
    partialContent: { outline }
  });

  // Stage 2: Prose Expander
  onProgress?.({
    nodeId: request.nodeId,
    stage: 'expanding',
    progress: 40
  });

  const prose = await proseExpander.expand(outline, request);

  onProgress?.({
    nodeId: request.nodeId,
    stage: 'expanding',
    progress: 66,
    partialContent: { outline, prose }
  });

  // Stage 3: Critic
  onProgress?.({
    nodeId: request.nodeId,
    stage: 'reviewing',
    progress: 80
  });

  const critique = await critic.evaluate(prose);

  if (critique.score >= threshold) {
    onProgress?.({
      nodeId: request.nodeId,
      stage: 'completed',
      progress: 100
    });
    return { success: true, content: prose, criticScore: critique.score };
  } else {
    onProgress?.({
      nodeId: request.nodeId,
      stage: 'failed',
      progress: 100,
      message: critique.feedback
    });
    return { success: false, error: critique.feedback };
  }
}
```

### Pattern 3: Multi-Provider LLM Client Abstraction

**What:** Single interface wrapping multiple LLM providers (OpenAI, Anthropic, OpenRouter)

**When:** Supporting multiple LLM backends with different APIs

**Why:**
- Isolates provider-specific logic from business logic
- Enables provider switching without code changes
- Normalizes error handling and retry logic
- Centralizes API key management

**Implementation:**

```typescript
export interface LLMClient {
  complete(options: LLMCompletionOptions): Promise<LLMCompletionResult>;
}

export class MultiProviderLLMClient implements LLMClient {
  async complete(options: LLMCompletionOptions): Promise<LLMCompletionResult> {
    const provider = await getActiveProvider();

    if (!provider) {
      throw new Error('No active LLM provider configured');
    }

    switch (provider.type) {
      case 'openai':
      case 'openrouter':
        return this.completeOpenAI(provider, options);
      case 'anthropic':
        return this.completeAnthropic(provider, options);
      default:
        throw new Error(`Unsupported provider: ${provider.type}`);
    }
  }

  private async completeOpenAI(
    provider: LLMProvider,
    options: LLMCompletionOptions
  ): Promise<LLMCompletionResult> {
    const client = createOpenAIClient(provider);

    const completion = await this.withRetry(() =>
      client.chat.completions.create({
        model: provider.model,
        messages: [
          { role: 'system', content: options.systemPrompt },
          { role: 'user', content: options.userPrompt }
        ],
        temperature: options.temperature ?? provider.temperature,
        max_tokens: options.maxTokens ?? 4000,
        response_format: options.responseFormat === 'json'
          ? { type: 'json_object' }
          : undefined,
      })
    );

    return {
      content: completion.choices[0]?.message?.content || '',
      usage: {
        promptTokens: completion.usage?.prompt_tokens || 0,
        completionTokens: completion.usage?.completion_tokens || 0,
        totalTokens: completion.usage?.total_tokens || 0,
      }
    };
  }

  private async withRetry<T>(
    fn: () => Promise<T>,
    maxRetries = 3
  ): Promise<T> {
    let lastError: Error;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error as Error;

        // Don't retry on validation errors
        if (error instanceof Error && error.message.includes('invalid')) {
          throw error;
        }

        // Exponential backoff
        if (attempt < maxRetries - 1) {
          await sleep(Math.pow(2, attempt) * 1000);
        }
      }
    }

    throw lastError!;
  }
}
```

### Pattern 4: Compositional Prompt Building

**What:** Assemble prompts from reusable templates + runtime context + configuration

**When:** Complex prompts requiring domain knowledge, style guides, examples

**Why:**
- Separates prompt content from code (editable in UI)
- Enables A/B testing of prompt variations
- Centralizes domain knowledge in database
- Reduces duplication across pipeline stages

**Implementation:**

```typescript
export class PromptBuilder {
  constructor(private db: Database) {}

  async buildBeatOutlinePrompt(request: GenerationRequest): Promise<string> {
    // Fetch configuration from database
    const [styleGuide, beatSequences, actTones] = await Promise.all([
      this.getStyleGuide(request.biome),
      this.getBeatSequences(request.nodeType),
      this.getActTone(request.acts[0]),
    ]);

    // Select beat sequence template (weighted random or rule-based)
    const template = this.selectBeatSequence(beatSequences, request);

    // Compose prompt sections
    const sections = [
      this.systemPromptSection(),
      this.taskSection(request.nodeType),
      this.contextSection(request),
      this.styleGuideSection(styleGuide),
      this.actToneSection(actTones),
      this.beatStructureSection(template),
      this.constraintsSection(request),
      this.examplesSection(request.nodeType), // Optional
      this.outputFormatSection(),
    ];

    return sections.filter(Boolean).join('\n\n---\n\n');
  }

  private contextSection(request: GenerationRequest): string {
    return `
# Context

- **Node Type**: ${request.nodeType}
- **Biome**: ${request.biome}
- **Acts**: ${request.acts.join(', ')}
- **Themes**: ${request.themes.join(', ')}
- **Entity Types**: ${request.entityTypes.join(', ')}

${this.nodeSpecificContext(request)}
    `.trim();
  }

  private styleGuideSection(styleGuide: StyleGuide): string {
    return `
# Style Guide for ${styleGuide.biome}

**Atmosphere**: ${styleGuide.atmosphere}

**Sensory Details**: ${styleGuide.sensoryDetails.join(', ')}

**Voice Notes**: ${styleGuide.voiceNotes}

**Avoid**: ${styleGuide.antipatterns.join(', ')}
    `.trim();
  }

  private beatStructureSection(template: BeatSequence): string {
    const beats = template.beatStructure.map((beat, i) =>
      `${i + 1}. **${beat.role}**: ${beat.description}`
    ).join('\n');

    return `
# Beat Structure

Generate beats following this sequence:

${beats}

Each beat should be 1-3 sentences and advance the narrative.
    `.trim();
  }
}
```

### Pattern 5: Batch Processing with Concurrency Control

**What:** Process multiple generation requests concurrently with throttling

**When:** Bulk operations (generate 20+ nodes) that would be slow sequentially

**Why:**
- Reduces total generation time (parallelism)
- Prevents API rate limiting (throttling)
- Provides aggregate progress tracking
- Enables fault tolerance (retry failed items)

**Implementation:**

```typescript
export class BatchProcessor {
  constructor(
    private batchSize: number = 5,
    private retryLimit: number = 3
  ) {}

  async generateBatch(
    requests: GenerationRequest[],
    onProgress?: (progress: BatchProgress) => void
  ): Promise<BatchResult> {
    const results: GenerationResult[] = [];
    const failed: { request: GenerationRequest; error: string }[] = [];

    // Process in batches
    for (let i = 0; i < requests.length; i += this.batchSize) {
      const batch = requests.slice(i, i + this.batchSize);

      // Concurrent generation within batch
      const batchResults = await Promise.allSettled(
        batch.map(request => this.generateWithRetry(request))
      );

      // Aggregate results
      batchResults.forEach((result, idx) => {
        if (result.status === 'fulfilled') {
          results.push(result.value);
        } else {
          failed.push({
            request: batch[idx],
            error: result.reason.message
          });
        }
      });

      // Report progress
      onProgress?.({
        total: requests.length,
        completed: results.length,
        failed: failed.length,
        progress: Math.round((results.length / requests.length) * 100)
      });

      // Rate limiting delay between batches
      if (i + this.batchSize < requests.length) {
        await sleep(1000); // 1 second between batches
      }
    }

    return {
      results,
      failed,
      successRate: results.length / requests.length
    };
  }

  private async generateWithRetry(
    request: GenerationRequest
  ): Promise<GenerationResult> {
    let lastError: Error;

    for (let attempt = 0; attempt < this.retryLimit; attempt++) {
      try {
        return await generateSingle(request);
      } catch (error) {
        lastError = error as Error;

        if (attempt < this.retryLimit - 1) {
          await sleep(Math.pow(2, attempt) * 1000);
        }
      }
    }

    throw lastError!;
  }
}
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Polling Instead of SSE

**What:** Frontend polls `/api/generate/status/:id` every second for progress

**Why bad:**
- Wastes bandwidth (most polls return "still in progress")
- Adds latency (average 500ms delay in updates)
- Scales poorly (100 concurrent users = 100 req/sec)
- Misses fine-grained progress (beat-by-beat updates)

**Instead:** Use SSE for single-node generation, polling only for batch jobs where SSE would be too chatty

### Anti-Pattern 2: Blocking API Calls for Long Operations

**What:** POST /api/generate/node waits for full generation (30-60 seconds) before responding

**Why bad:**
- Frontend appears frozen (no feedback)
- Timeout issues (proxies, browsers)
- No cancellation support
- Resource waste (holding connection open)

**Instead:** Return 202 Accepted immediately, stream progress via SSE, or use job queue

### Anti-Pattern 3: Storing Prompts in Code

**What:** System prompts, templates, examples hardcoded in TypeScript files

**Why bad:**
- Requires deployment to change prompts
- No A/B testing capability
- Can't edit in UI
- Difficult to version/track changes

**Instead:** Store prompt templates in database, compose at runtime, make editable through admin UI

### Anti-Pattern 4: No Quality Gates

**What:** Accept all LLM output without validation or scoring

**Why bad:**
- Generates low-quality content (off-topic, inconsistent)
- No feedback loop for improvement
- Users waste time editing bad output
- Degrades trust in AI features

**Instead:** Implement critic stage to score quality, retry on low scores, show score to user

### Anti-Pattern 5: Tight Coupling to Single Provider

**What:** Directly call `openai.chat.completions.create()` throughout codebase

**Why bad:**
- Hard to switch providers (vendor lock-in)
- Can't compare providers (cost, quality)
- Different error handling for each provider
- Duplicated retry logic

**Instead:** Abstract behind LLMClient interface, configure provider in database

### Anti-Pattern 6: Synchronous Streaming to Frontend

**What:** Wait for LLM to finish streaming, accumulate full response, then send to frontend

**Why bad:**
- Loses real-time benefit of streaming LLM APIs
- No progressive display (users see nothing until done)
- Memory waste (buffering full response)

**Instead:** Pipe LLM stream directly to SSE stream, enable real-time display

### Anti-Pattern 7: Global Generation State

**What:** Store generation progress in global Redux/Zustand store

**Why bad:**
- Multiple simultaneous generations conflict
- Hard to clean up on unmount
- Doesn't survive navigation
- Difficult to test

**Instead:** Use component-local state with `useGeneration` hook, store completed results in TanStack Query cache

---

## Integration with Existing Architecture

### Hono + Drizzle Integration

**Route Handler Pattern:**

```typescript
// /api/generate/node
app.post('/node', zValidator('json', GenerationRequestSchema), async (c) => {
  const request = c.req.valid('json');

  // Generate content
  const result = await generateSingle(request);

  // Transform to database schema
  const nodeData = transformToDbSchema(result, request);

  // Persist with Drizzle
  await db.insert(nodes).values(nodeData);

  return c.json(result);
});

// /api/generate/node/stream (SSE variant)
app.get('/node/stream', async (c) => {
  const request = parseQueryParams(c.req.query());

  // Validate request
  GenerationRequestSchema.parse(request);

  // Create and return SSE stream
  return c.body(createSSEStream(c, request));
});
```

**Key Points:**
- Reuse existing Zod schemas from `@node-gen-web/shared`
- Leverage Drizzle ORM for persistence (no raw SQL)
- Use Hono's `zValidator` middleware for request validation
- Return ReadableStream for SSE endpoints

### React + TanStack Query Integration

**State Management Layers:**

```typescript
// Layer 1: SSE streaming state (ephemeral, component-local)
function useGeneration() {
  const [state, setState] = useState<GenerationState>({ stage: 'idle' });

  const generate = useCallback((request: GenerationRequest) => {
    // Manage SSE connection, update local state
  }, []);

  return { state, generate };
}

// Layer 2: Server state cache (persistent, global)
function useNodes() {
  return useQuery({
    queryKey: ['nodes'],
    queryFn: () => fetch('/api/nodes').then(r => r.json())
  });
}

// Layer 3: UI state (persistent, global)
const useUIStore = create<UIState>((set) => ({
  sidebarCollapsed: false,
  setSidebarCollapsed: (collapsed) => set({ sidebarCollapsed: collapsed })
}));

// Layer 4: Form state (ephemeral, component-local)
const useFormStore = create<FormState>((set) => ({
  step: 0,
  data: {},
  setStep: (step) => set({ step }),
  setData: (data) => set((state) => ({ data: { ...state.data, ...data } }))
}));
```

**Integration Pattern:**

```typescript
function QuickGenerate() {
  const { state, generate } = useGeneration();
  const queryClient = useQueryClient();

  const handleGenerate = async (input: GenerationInput) => {
    // Start generation (streaming)
    const cleanup = generate(input);

    // When complete, invalidate cache
    if (state.stage === 'completed') {
      await queryClient.invalidateQueries({ queryKey: ['nodes'] });
      cleanup();
    }
  };

  return (
    <div>
      <GenerationForm onSubmit={handleGenerate} />
      <GenerationProgress state={state} />
    </div>
  );
}
```

**Key Points:**
- Use `useGeneration` hook for SSE streaming (not TanStack Query)
- Use TanStack Query for REST endpoints (CRUD operations)
- Invalidate queries on generation completion to refresh lists
- Use Zustand for UI preferences and wizard state

---

## Scalability Considerations

### At 1 User (Current Scope)

**Architecture:**
- Single Hono server (Bun runtime)
- Direct SSE connections
- In-memory job tracking (no Redis needed)
- Synchronous batch processing

**Configuration:**
- Batch size: 5 concurrent generations
- No rate limiting
- Direct database access

### At 10 Users (Future)

**Changes Needed:**
- Job queue (BullMQ + Redis) for batch processing
- WebSocket fallback for SSE (some proxies block SSE)
- Connection pooling for database
- Basic rate limiting (per-user)

**No changes needed:**
- Core architecture remains same
- LLM client abstraction unchanged
- Streaming pattern still works

### At 100+ Users (Not in Scope)

**Would Require:**
- Dedicated job workers (separate processes)
- Horizontal scaling (load balancer + multiple Hono instances)
- Distributed job queue
- WebSocket cluster (sticky sessions or Redis pub/sub)
- Advanced rate limiting (token bucket per user + global)

---

## Build Order & Dependencies

### Phase 1: Core Generation Pipeline (Backend)

**Components:**
1. LLM Client (`llm-client.ts`) - ALREADY EXISTS
2. Prompt Builder (`prompt-builder.ts`) - ALREADY EXISTS
3. Beat Outliner (`beat-outliner.ts`) - ALREADY EXISTS
4. Prose Expander (`prose-expander.ts`) - ALREADY EXISTS
5. Critic (`critic.ts`) - ALREADY EXISTS
6. Index (`index.ts` - exports) - ALREADY EXISTS

**Dependencies:**
- Database schema with config tables (llm_providers, generation_settings, etc.)
- Shared Zod schemas (GenerationRequest, GenerationResult)

**Completion Criteria:**
- Can call `generateSingle(request)` and get back content
- All 3 stages execute sequentially
- Quality gate (critic) enforces threshold

### Phase 2: Streaming Layer (Backend)

**Components:**
1. Streaming utilities (`streaming.ts`) - ALREADY EXISTS
2. Batch Processor (`batch-processor.ts`) - ALREADY EXISTS

**Dependencies:**
- Phase 1 complete (generation pipeline)
- Progress callback integration

**Completion Criteria:**
- SSE stream sends progress events
- Progress updates flow from pipeline to frontend
- Stream closes on completion/error

### Phase 3: API Routes (Backend)

**Components:**
1. Generation routes (`routes/generate.ts`) - ALREADY EXISTS
2. Provider routes (`routes/llm-providers.ts`) - ALREADY EXISTS

**Dependencies:**
- Phase 1 and 2 complete
- Request validation schemas

**Completion Criteria:**
- POST /api/generate/node returns 202 or streams SSE
- POST /api/generate/bulk creates job and returns ID
- GET /api/generate/status/:jobId returns progress

### Phase 4: Frontend Streaming Client

**Components:**
1. SSE client wrapper (`lib/streaming.ts`)
2. `useGeneration` hook (`hooks/useGeneration.ts`)

**Dependencies:**
- Backend API routes available

**Completion Criteria:**
- Can establish SSE connection
- Receives and parses progress events
- Handles reconnection on disconnect
- Cleans up on component unmount

### Phase 5: Frontend Generation UI

**Components:**
1. GenerationProgress component - ALREADY EXISTS
2. QuickGenerate component - ALREADY EXISTS
3. AssistedCreate component - ALREADY EXISTS
4. BulkGenerate component - ALREADY EXISTS

**Dependencies:**
- Phase 4 complete (streaming hooks)
- Existing form components
- TanStack Query setup

**Completion Criteria:**
- Can trigger single node generation
- Real-time progress display works
- Bulk generation shows aggregate progress
- Generated content saves to database

### Phase 6: Integration & Testing

**Tasks:**
1. Connect streaming.ts SSE to frontend hooks - **NOT DONE**
2. Wire batch-processor progress to job status API - **NOT DONE**
3. Integrate prompt-builder with generation pipeline - **NOT DONE**
4. Connect critic stage retry logic - **NOT DONE**
5. Test end-to-end flows (single, bulk, assisted) - **NOT DONE**

**Dependencies:**
- All components implemented

**Completion Criteria:**
- Single node generation works end-to-end
- Bulk generation completes without errors
- Assisted create populates form fields
- No console errors, all types valid

---

## Critical Integration Points

### Integration Point 1: SSE Stream → Frontend Hook

**Backend:**
```typescript
// streaming.ts - ALREADY EXISTS
export function createSSEStream(c: Context, request: NodeGenerationRequest) {
  // Returns ReadableStream with progress events
}
```

**Frontend:**
```typescript
// hooks/useGeneration.ts - NEEDS IMPLEMENTATION
export function useGeneration() {
  const generate = (request: GenerationRequest) => {
    const url = `/api/generate/node/stream?${serialize(request)}`;
    const eventSource = new EventSource(url);

    eventSource.addEventListener('progress', (e) => {
      const data = JSON.parse(e.data);
      setState(prev => ({ ...prev, ...data }));
    });

    eventSource.addEventListener('complete', (e) => {
      const result = JSON.parse(e.data);
      setState({ stage: 'completed', content: result });
      eventSource.close();
    });
  };
}
```

**Gap:** Frontend hook needs to be wired to backend SSE endpoint

### Integration Point 2: Batch Processor → Job Status API

**Backend:**
```typescript
// batch-processor.ts - ALREADY EXISTS
export async function generateBatch(
  requests: GenerationRequest[],
  callbacks?: { onProgress: (progress: BatchProgress) => void }
) {
  // Processes batches, calls onProgress
}

// routes/generate.ts - NEEDS JOB TRACKING
app.post('/bulk', async (c) => {
  const request = c.req.valid('json');

  // Create job in database
  const job = await db.insert(generationJobs).values({
    status: 'queued',
    total: request.requests.length,
    completed: 0,
  }).returning();

  // Start batch in background
  generateBatch(request.requests, {
    onProgress: (progress) => {
      // Update job in database
      db.update(generationJobs)
        .set({ completed: progress.completed })
        .where(eq(generationJobs.id, job.id));
    }
  });

  return c.json({ jobId: job.id }, 202);
});

app.get('/status/:jobId', async (c) => {
  const job = await db.select()
    .from(generationJobs)
    .where(eq(generationJobs.id, c.req.param('jobId')));

  return c.json(job);
});
```

**Gap:** Need to add `generationJobs` table and wire progress callbacks to database updates

### Integration Point 3: Prompt Builder → Generation Stages

**Current State:**
- `prompt-builder.ts` exists but may not be called by beat-outliner, prose-expander, critic

**Needed:**
```typescript
// beat-outliner.ts
export async function generateOutline(request: GenerationRequest) {
  const promptBuilder = new PromptBuilder(db);
  const prompt = await promptBuilder.buildBeatOutlinePrompt(request);

  const llmClient = new MultiProviderLLMClient();
  const result = await llmClient.complete({
    systemPrompt: BEAT_OUTLINER_SYSTEM_PROMPT,
    userPrompt: prompt,
    responseFormat: 'json'
  });

  return parseBeatOutline(result.content);
}
```

**Gap:** Verify each stage uses PromptBuilder (not hardcoded prompts)

---

## Configuration Schema Requirements

### Database Tables (For LLM Integration)

```typescript
// llm_providers
{
  id: number;
  name: string;
  type: 'openai' | 'openrouter' | 'anthropic';
  baseUrl: string | null;
  encryptedApiKey: string | null;
  model: string;
  temperature: number;
  maxRetries: number;
  isActive: boolean;
  createdAt: Date;
}

// generation_settings
{
  id: number;
  batchSize: number; // default: 5
  criticThreshold: number; // default: 70
  enableCriticStage: boolean; // default: true
  defaultTemperature: number; // default: 0.7
  maxTokens: number; // default: 4000
}

// generation_jobs (for batch tracking)
{
  id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  total: number;
  completed: number;
  failed: number;
  createdAt: Date;
  completedAt: Date | null;
}
```

---

## Performance Characteristics

### Single Node Generation

| Stage | Duration | Tokens | Cost (GPT-4) |
|-------|----------|--------|--------------|
| Beat Outliner | 3-5s | 500 in / 200 out | $0.02 |
| Prose Expander | 8-12s | 800 in / 600 out | $0.04 |
| Critic | 2-4s | 700 in / 100 out | $0.02 |
| **Total** | **15-20s** | **2000/900** | **$0.08** |

### Bulk Generation (20 nodes)

| Metric | Sequential | Batch (5 concurrent) |
|--------|------------|---------------------|
| Duration | 6-7 minutes | 1.5-2 minutes |
| API calls | 60 (3 per node) | 60 (same) |
| Peak concurrency | 1 | 5 |
| Cost | $1.60 | $1.60 (same) |
| Speedup | 1x | 3.5x |

### Streaming Overhead

| Metric | Without SSE | With SSE |
|--------|-------------|----------|
| Backend duration | 15s | 15s (same) |
| Frontend latency | 15s (blocking) | <100ms (first event) |
| User perception | Frozen UI | Progressive updates |
| Memory | Buffers full response | Streams incrementally |

---

## Sources & Confidence

**HIGH Confidence Areas:**
- SSE streaming patterns (standard web technology, widely documented)
- React state management with TanStack Query + hooks (official docs)
- Multi-stage pipeline architecture (analysis of existing implementation)
- Hono routing and middleware (Hono official documentation)

**MEDIUM Confidence Areas:**
- Batch processing patterns (inferred from existing `batch-processor.ts` structure)
- LLM client abstraction (based on existing `llm-client.ts` implementation)
- Performance characteristics (estimated from typical GPT-4 response times)

**Implementation Evidence:**
- All backend services already exist in `/packages/backend/src/services/generation/`
- Frontend components already exist in `/packages/frontend/src/components/generation/`
- Database schema includes LLM configuration tables
- API routes defined in `/packages/backend/src/routes/generate.ts`

**Primary Gap:**
- Integration between existing components (wiring SSE to hooks, batch processor to job tracking)
- Not architectural design (architecture is sound and implemented)

**Recommendation:**
Proceed with Phase 6 (Integration & Testing) as architecture is well-designed and components exist. Focus on connecting the pieces rather than redesigning.
