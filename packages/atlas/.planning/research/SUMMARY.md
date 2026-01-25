# Project Research Summary

**Project:** node-gen-web AI Integration
**Domain:** AI-powered narrative content generation with streaming UI
**Researched:** 2026-01-25
**Confidence:** HIGH

## Executive Summary

This project integrates AI-powered narrative generation into an existing TypeScript monorepo (Bun + Hono backend, React + Vite frontend) that manages graph-based narrative content for game development. The recommended approach uses **streaming SSE for real-time progress updates**, **multi-stage LLM pipelines** (outliner → expander → critic), and **batch processing with concurrency control** to generate high-quality narrative content at scale.

The existing stack is already well-suited for this integration. Use **OpenRouter with the OpenAI SDK** for LLM access, **Hono's native SSE helpers** for streaming, **p-queue for batch concurrency**, and **Zustand for client-side generation state**. The architecture already has the generation pipeline components implemented (llm-client, prompt-builder, beat-outliner, prose-expander, critic, batch-processor, streaming utilities) — the primary gap is **integration and wiring** between these components, not architectural design.

The critical risks are **SSE connection drops losing work**, **runaway retry costs**, **streaming response buffering**, and **base64 API key storage in production**. All are preventable with job persistence, circuit breakers, proper HTTP headers, and enforcing environment variable API keys. The research identifies specific phase-level mitigations to address each pitfall systematically.

## Key Findings

### Recommended Stack

Research confirms the existing technology choices are sound. No major stack additions required — primarily need to install **p-queue**, **p-retry**, and **nanoid** for batch processing. The stack leverages built-in capabilities (Hono SSE, browser EventSource, Zod validation) rather than heavy abstractions.

**Core technologies:**
- **OpenRouter via OpenAI SDK**: Multi-model access through OpenAI-compatible API; avoids vendor lock-in
- **Hono native SSE (streamSSE)**: Built-in server-sent events streaming; no external library needed
- **p-queue**: Concurrency control for batch generation; prevents API rate limit exhaustion
- **p-retry**: Exponential backoff for transient failures (429, 503 errors)
- **Zustand**: Client-side ephemeral state for generation progress tracking
- **EventSource API**: Native browser SSE client; zero bundle size
- **Zod**: LLM output validation to catch malformed JSON and hallucinations

**Critical non-decisions:**
- **Avoid Vercel AI SDK**: Too heavy (120KB), designed for chat UIs not multi-stage pipelines
- **Avoid LangChain**: Complexity overkill for linear 3-stage pipeline
- **Avoid BullMQ/Redis**: In-memory p-queue sufficient for single-user local development
- **Avoid Socket.io**: SSE is simpler for unidirectional server-to-client streaming

### Expected Features

Research shows clear feature tiers. MVP should focus on **single-node generation with streaming**, then expand to **full-node generation with quality control**, then add **differentiating features** (critic LLM, field-level assists, smart retry).

**Must have (table stakes):**
- Real-time streaming generation (token-by-token or beat-by-beat)
- Regenerate/retry controls (users need ability to roll the dice again)
- Preview before save (AI output is unpredictable, needs review step)
- Generation cancellation (abort in-flight requests)
- Basic error handling with actionable feedback (distinguish rate limits vs invalid input)
- Cost visibility (estimate before generation, actual cost after)

**Should have (competitive differentiators):**
- **Critic LLM scoring** (automated quality assessment before user review) — HIGH value
- **Field-level AI assists** (inline "magic wand" per form field) — MEDIUM-HIGH value
- **Smart retry with hints** ("Make this darker", "Add more sensory detail") — MEDIUM value
- **Bulk generation with progress tracking** (generate 50 nodes overnight) — HIGH value for productivity

**Defer (v2+):**
- Batch operations with constraints ("Generate 10 combat nodes for Act 2, no duplicates")
- Context-aware suggestions (AI proposes what to generate next based on graph)
- Prompt template customization UI (power users edit system prompts)
- Multi-provider fallback (auto-switch on primary provider failure)
- Generation analytics (track which prompts produce best results)

### Architecture Approach

The architecture follows a **pipeline pattern** with clear separation of concerns. Backend has multi-stage LLM orchestration (outliner → expander → critic), SSE streaming layer, and batch processor with concurrency control. Frontend uses EventSource for SSE consumption and Zustand for ephemeral generation state. All components are already implemented — the gap is integration and wiring.

**Major components:**
1. **Generation Pipeline** (backend/services/generation) — Orchestrates 3-stage LLM generation with quality gates
2. **Streaming Layer** (streaming.ts) — Converts progress callbacks to SSE messages; manages ReadableStream
3. **LLM Client** (llm-client.ts) — Abstracts OpenAI/OpenRouter/Anthropic with retry logic and error normalization
4. **Prompt Builder** (prompt-builder.ts) — Composes prompts from templates + context + database config
5. **Batch Processor** (batch-processor.ts) — Concurrent generation with throttling (default: 5 concurrent)
6. **Frontend Streaming Hook** (useGeneration) — EventSource wrapper with reconnection logic (needs implementation)
7. **Progress Tracking** (Zustand store) — Ephemeral state for jobs, stages, partial results (needs implementation)

**Data flow pattern:**
- User triggers generation → API returns SSE stream → Pipeline stages emit progress callbacks → SSE stream sends events → Frontend EventSource updates Zustand → UI displays progress → On completion: save to DB + invalidate TanStack Query cache

**Integration points (need wiring):**
- SSE stream → Frontend useGeneration hook
- Batch processor progress callbacks → Job status API (needs generation_jobs table)
- Prompt builder → Generation pipeline stages (verify connection)
- Critic retry logic → Pipeline orchestration

### Critical Pitfalls

Research identified 15 pitfalls. Top 5 are critical (cause rewrites/data loss). All have concrete prevention strategies.

1. **SSE Connection Drops Without Recovery** — Browser closes connection, user loses partial results, costs already incurred. **Prevention:** Job persistence in DB, aggressive heartbeat (10-15s), checkpoint progress, idempotency, reconnection logic with exponential backoff.

2. **Base64 "Encryption" Deployed to Production** — API keys stored with base64 encoding (current implementation) get leaked. **Prevention:** Enforce environment variables in production, add runtime checks if NODE_ENV=production and DB keys used, security warnings in UI.

3. **Unbounded Retry Loops Cause Runaway Costs** — Malformed LLM output triggers retries; batch of 50 nodes × 3 retries × 3 stages = 450 calls instead of 150. **Prevention:** Error classification (retriable vs non-retriable), circuit breaker pattern, cost budgets per batch, graduated retry strategy (skip after 2-3 failures).

4. **Streaming Response Buffering Destroys Real-Time UX** — Proxies buffer SSE events, entire content appears at once after 15s. **Prevention:** HTTP headers (X-Accel-Buffering: no), explicit flush in stream, test with real nginx/cloudflare proxy, fallback to polling.

5. **Partial Batch Failure Loses Progress and Context** — 30 nodes succeed, network error hits, entire batch marked failed, 30 nodes discarded. **Prevention:** Incremental save (each node immediately), resume from checkpoint, partial success reporting, progress persistence in DB.

## Implications for Roadmap

Based on research, the architecture is already sound and components exist. Focus on **integration phases** rather than building from scratch. The roadmap should prioritize streaming foundation, then single-node generation end-to-end, then batch processing, then differentiating features.

### Phase 1: Streaming Foundation (Backend)
**Rationale:** Must establish SSE infrastructure before any generation features. Backend streaming.ts exists but needs integration with routes.
**Delivers:** Working SSE endpoint with progress callbacks, anti-buffering headers, heartbeat pings
**Uses:** Hono streamSSE, ReadableStream, progress callback pattern
**Avoids:** Pitfall #4 (buffering), Pitfall #1 (connection drops via heartbeat)
**Estimated:** 1-2 days

### Phase 2: Core Generation Pipeline (Backend)
**Rationale:** Wire prompt-builder to generation stages, implement job persistence, add circuit breakers
**Delivers:** End-to-end single-node generation (outliner → expander → critic)
**Implements:** Generation pipeline orchestration, error classification, retry logic
**Avoids:** Pitfall #3 (retry loops), Pitfall #1 (job persistence for recovery)
**Estimated:** 2-3 days

### Phase 3: Frontend Streaming Client
**Rationale:** Can't show progress without frontend SSE consumer
**Delivers:** useGeneration hook, EventSource wrapper, reconnection logic
**Uses:** Native EventSource API, Zustand for state, TanStack Query invalidation
**Avoids:** Pitfall #1 (reconnection logic), Pitfall #4 (detect buffering)
**Estimated:** 1-2 days

### Phase 4: Single-Node Generation UI
**Rationale:** Complete MVP user flow (trigger → stream → preview → save)
**Delivers:** GenerationProgress component, QuickGenerate form, preview-before-save
**Addresses:** Table stakes features (streaming, regenerate, preview, cancel, error handling)
**Estimated:** 2-3 days

### Phase 5: Quality Control (Critic Integration)
**Rationale:** Differentiator feature; prevents low-quality output from reaching users
**Delivers:** Critic stage with quality scoring, threshold enforcement, retry on low scores
**Addresses:** FEATURES.md differentiator (automated quality assessment)
**Avoids:** Pitfall #10 (calibrate critic per node type)
**Estimated:** 1-2 days

### Phase 6: Batch Processing
**Rationale:** Productivity multiplier; requires job infrastructure
**Delivers:** Bulk generation with concurrency control, progress tracking, partial success handling
**Uses:** p-queue, batch-processor.ts, generation_jobs table
**Addresses:** Table stakes (bulk generation) + differentiator (progress tracking)
**Avoids:** Pitfall #3 (circuit breaker), Pitfall #5 (incremental save, partial success)
**Estimated:** 2-3 days

### Phase 7: Field-Level Assists
**Rationale:** Differentiator feature; enables hybrid manual + AI workflow
**Delivers:** Inline "Generate" button per form field, single-LLM-call generation
**Addresses:** FEATURES.md differentiator (field-level assists)
**Estimated:** 1-2 days

### Phase 8: Settings & Provider Management
**Rationale:** Allows switching models, configuring temperature, managing API keys
**Delivers:** Provider CRUD UI, temperature presets, cost visibility
**Addresses:** Table stakes (provider selection, generation presets, cost visibility)
**Avoids:** Pitfall #2 (security warnings for DB keys), Pitfall #9 (parameter validation)
**Estimated:** 1-2 days

### Phase Ordering Rationale

- **Streaming first** because all features depend on it (single, bulk, assists all need progress updates)
- **Single-node before batch** because batch complexity amplifies any single-node issues
- **Critic before batch** because batch multiplies low-quality generation costs
- **Settings last** because default provider (OpenRouter) works via env vars initially

**Dependency chain:**
```
Streaming Foundation (Phase 1)
    ↓
Core Pipeline (Phase 2) + Frontend Client (Phase 3)
    ↓
Single-Node UI (Phase 4)
    ↓
Critic Integration (Phase 5)
    ↓
Batch Processing (Phase 6)
    ↓
Field Assists (Phase 7) | Settings UI (Phase 8) [parallel]
```

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 2 (Core Pipeline):** Error classification rules need validation with actual API responses; circuit breaker thresholds need tuning
- **Phase 5 (Critic):** Scoring rubric calibration per node type requires domain expertise and iteration
- **Phase 6 (Batch):** Optimal concurrency levels depend on OpenRouter tier and rate limits (needs runtime testing)

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Streaming):** SSE is well-documented web standard; Hono implementation is straightforward
- **Phase 3 (Frontend Client):** EventSource API is stable; reconnection patterns are established
- **Phase 4 (Single-Node UI):** Standard React form + progress UI patterns
- **Phase 7 (Field Assists):** Simple variation of Phase 4 (single field instead of full node)
- **Phase 8 (Settings):** CRUD UI with form validation (existing pattern in codebase)

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Existing stack is well-suited; only need p-queue/p-retry additions |
| Features | HIGH | Clear tiering based on established AI writing tool patterns (Sudowrite, NovelAI, Notion AI) |
| Architecture | HIGH | Components already implemented; gap is integration not design |
| Pitfalls | MEDIUM-HIGH | Based on training data patterns; specific to existing implementation (base64 encryption confirmed in code) |

**Overall confidence:** HIGH

The architecture exists and is sound. Components are already implemented. Research primarily validates approach and identifies integration gaps rather than discovering new requirements. Low risk of major surprises during implementation.

### Gaps to Address

**During planning/execution:**
- **Prompt template content**: Research focused on architecture, not domain-specific prompt engineering. Beat outliner, prose expander, and critic prompts need domain expertise and iteration. Likely needs dedicated experimentation phase.
- **API rate limits**: OpenRouter tier and rate limits unknown (2026 values). May need to adjust concurrency settings (currently hardcoded to 5) based on runtime testing.
- **Proxy buffering behavior**: Needs verification in staging with real nginx/cloudflare. Anti-buffering headers are standard but implementation-specific quirks may emerge.
- **Critic score calibration**: Score thresholds (default: 70/100) need validation against actual node types. Combat vs choice vs passage may need different thresholds.
- **Cost estimation accuracy**: Token counting and cost calculations based on typical rates. Need to verify with actual provider pricing in 2026.

**Post-MVP validation:**
- Performance characteristics (15-20s per node, 1.5-2min for 20-node batch) are estimates. Actual timings depend on model speed and prompt complexity.
- Multi-provider fallback deferred to v2; if OpenRouter has reliability issues, may need to accelerate.

## Sources

### Primary (HIGH confidence)
- **Existing Codebase Analysis**:
  - `/packages/backend/src/services/generation/` — All pipeline components already implemented
  - `/packages/backend/src/routes/generate.ts` — API routes defined
  - `/packages/backend/src/middleware/encryption.ts` — Base64 encoding confirmed (Pitfall #2)
  - `/packages/frontend/src/components/generation/` — Frontend components partially implemented
  - `CLAUDE.md`, `IMPLEMENTATION_PLAN.md`, `AI integration plan.md` — Architecture documentation
- **Hono SSE Documentation**: Training data on Hono v4.0+ streamSSE helper
- **OpenRouter API**: Training data on OpenAI API compatibility
- **Browser EventSource API**: MDN Web API documentation patterns
- **p-queue/p-retry libraries**: npm package documentation and usage patterns

### Secondary (MEDIUM confidence)
- **AI Writing Tools**: Training data patterns from Sudowrite, NovelAI, AI Dungeon, Scenario.gg (feature landscape analysis)
- **SSE Best Practices**: General streaming patterns, anti-buffering techniques, proxy behavior
- **LLM Integration Patterns**: Multi-stage pipelines, retry logic, error handling from code generation tools (Cursor, Copilot)

### Tertiary (LOW confidence)
- **Performance Estimates**: Token counts and timing based on typical GPT-4 response times (not verified for 2026 models)
- **Cost Estimates**: Based on training data LLM pricing (actual 2026 rates may differ)
- **Concurrency Limits**: OpenRouter free tier (5 req/sec) and paid tier (20 req/sec) from training data; may have changed

---
**Research completed:** 2026-01-25
**Ready for roadmap:** Yes — Architecture validated, components exist, integration plan clear, pitfall mitigations identified per phase
