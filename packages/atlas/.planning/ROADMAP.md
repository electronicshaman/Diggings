# Roadmap: Narrative Node Generator - AI Integration

## Overview

This roadmap completes the AI-powered narrative generation features for an existing brownfield codebase. The application already supports manual node creation through a multi-step wizard. This roadmap integrates LLM-powered generation with streaming progress updates, quality control via critic scoring, and batch processing capabilities. The architecture follows a 3-stage pipeline (beat outliner → prose expander → critic) with real-time SSE streaming to the frontend. Phases build sequentially from streaming foundation through provider management, enabling users to generate high-quality narrative content with minimal manual effort.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Streaming Foundation** - SSE infrastructure with anti-buffering and heartbeat
- [x] **Phase 2: Core Generation Pipeline** - Wire generation services to API routes with retry logic
- [x] **Phase 3: Quality Control** - Integrate critic stage with scoring and auto-retry
- [x] **Phase 4: Frontend Streaming Client** - EventSource hook with reconnection logic
- [x] **Phase 5: Single-Node Generation UI** - Quick Generate flow with preview and regenerate
- [ ] **Phase 6: Field-Level Assists** - Inline AI generation buttons in manual forms
- [ ] **Phase 7: Batch Processing** - Bulk generation with concurrency control and progress tracking
- [ ] **Phase 8: Provider Management** - Settings UI for LLM provider configuration
- [ ] **Phase 9: Configuration Management** - Advanced config UI for beat sequences and style guides

## Phase Details

### Phase 1: Streaming Foundation
**Goal**: Backend SSE streaming infrastructure works end-to-end with anti-buffering headers and connection monitoring
**Depends on**: Nothing (first phase)
**Requirements**: INTG-01, ERR-03, ERR-04
**Success Criteria** (what must be TRUE):
  1. SSE endpoint streams progress events to connected clients
  2. Stream includes heartbeat pings every 10-15 seconds to detect connection drops
  3. Anti-buffering headers (X-Accel-Buffering: no) prevent proxy buffering
  4. Generation jobs persist to database and survive connection drops
**Plans**: 1 plan

Plans:
- [x] 01-01-PLAN.md — SSE streaming with heartbeat, anti-buffering headers, and job persistence

### Phase 2: Core Generation Pipeline
**Goal**: Complete 3-stage generation pipeline (outliner → expander → critic) executes successfully for single nodes
**Depends on**: Phase 1
**Requirements**: INTG-02, INTG-03, INTG-05, GEN-03, GEN-04, ERR-01, ERR-02
**Success Criteria** (what must be TRUE):
  1. User can trigger generation and receive complete node content through all 3 stages
  2. Pipeline connects prompt-builder to generation stages (outliner, expander, critic)
  3. LLM client supports OpenRouter, Anthropic, and OpenAI providers with retry logic
  4. System implements circuit breaker after repeated failures (prevents runaway costs)
  5. System retries transient errors (429, 503) with exponential backoff
  6. User receives actionable error messages when generation fails
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — Circuit breaker integration with opossum for LLM failure protection
- [x] 02-02-PLAN.md — Enhanced error handling with user-friendly messages and retry jitter
- [x] 02-03-PLAN.md — Database save integration for streaming endpoint completion

### Phase 3: Quality Control
**Goal**: Critic stage scores generated content and automatically retries low-quality outputs
**Depends on**: Phase 2
**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04
**Success Criteria** (what must be TRUE):
  1. System validates generated JSON structure and required fields before saving
  2. Critic LLM scores content (0-100 quality rating) after generation
  3. System automatically retries generation if critic score falls below threshold (default: 70)
  4. User sees critic score breakdown with quality feedback in UI
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Zod validation layer and quality-based retry loop in batch-processor
- [x] 03-02-PLAN.md — QualityFeedback UI component with severity-grouped issues display

### Phase 4: Frontend Streaming Client
**Goal**: Frontend consumes SSE streams with reconnection logic and progress state management
**Depends on**: Phase 1
**Requirements**: STREAM-01, ERR-05
**Success Criteria** (what must be TRUE):
  1. User sees real-time beat-by-beat progress updates during generation
  2. Frontend EventSource hook connects to SSE endpoint and parses events
  3. Zustand store manages generation progress state (stages, partial results)
  4. User can reconnect to in-progress generation after connection loss
**Plans**: 1 plan

Plans:
- [x] 04-01-PLAN.md — Zustand generation store with persist middleware and reconnection logic

### Phase 5: Single-Node Generation UI
**Goal**: User can generate complete nodes through Quick Generate flow with preview and regenerate controls
**Depends on**: Phase 2, Phase 3, Phase 4
**Requirements**: GEN-02, STREAM-02, STREAM-03, STREAM-04
**Success Criteria** (what must be TRUE):
  1. User can generate complete node from minimal input (node type + biome)
  2. User can preview generated content before saving to database
  3. User can regenerate content if output quality is unsatisfactory
  4. User can cancel in-flight generation requests mid-stream
  5. GenerationProgress component displays 3-stage pipeline progress
**Plans**: 1 plan

Plans:
- [x] 05-01-PLAN.md — Wire Quick Generate save workflow with navigation and toast feedback

### Phase 6: Field-Level Assists
**Goal**: User can generate individual fields via AI assist buttons in manual node creation forms
**Depends on**: Phase 5
**Requirements**: GEN-01
**Success Criteria** (what must be TRUE):
  1. User sees "Generate" button next to narrative hook field in manual forms
  2. User sees "Suggest Beats" button in beat editor
  3. AI-generated field content streams into form field in real-time
  4. User can accept, regenerate, or manually edit AI-generated field content
**Plans**: 3 plans

Plans:
- [ ] 06-01-PLAN.md — Backend field generation endpoints for narrative_hook, beat, and beat-list
- [ ] 06-02-PLAN.md — FieldAssistButton component, useFieldGeneration hook, narrative hook integration
- [ ] 06-03-PLAN.md — Beat editor AI assists with Suggest Beats and per-beat regeneration

### Phase 7: Batch Processing
**Goal**: User can generate multiple nodes in bulk with concurrency control and incremental progress tracking
**Depends on**: Phase 5
**Requirements**: INTG-04
**Success Criteria** (what must be TRUE):
  1. User can trigger bulk generation with distribution gap analysis
  2. System processes batch with concurrency control (default: 5 parallel requests)
  3. User sees per-node progress tracking with partial success reporting
  4. System saves completed nodes incrementally (doesn't lose progress on partial failure)
  5. DistributionGapChart visualizes which node types/biomes need generation
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

### Phase 8: Provider Management
**Goal**: User can configure LLM providers through Settings UI with encrypted API key storage
**Depends on**: Phase 2
**Requirements**: PROV-01, PROV-02, PROV-03, PROV-04, PROV-05, PROV-06, PROV-07
**Success Criteria** (what must be TRUE):
  1. User can add new LLM provider configurations (OpenRouter, Anthropic, OpenAI)
  2. User can edit existing provider settings (model, temperature, max retries)
  3. User can delete unused providers
  4. User can activate/deactivate providers without deleting configuration
  5. System stores API keys encrypted in database (base64 for local dev)
  6. System enforces environment variable API keys when NODE_ENV=production
  7. User can test provider connection to verify credentials
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

### Phase 9: Configuration Management
**Goal**: User can view and edit advanced generation configuration (beat sequences, style guides, vernacular)
**Depends on**: Nothing (independent feature)
**Requirements**: CONF-01, CONF-02, CONF-03, CONF-04, CONF-05
**Success Criteria** (what must be TRUE):
  1. User can view beat roles, sequences, and style guides in config UI
  2. User can edit beat sequences for each node type (combat, choice, trade, etc.)
  3. User can edit style guides per biome (atmosphere, sensory details, antipatterns)
  4. User can manage vernacular glossary (historical/archaic terms)
  5. System loads configuration from database (not hardcoded constants)
**Plans**: TBD

Plans:
- [ ] 09-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Streaming Foundation | 1/1 | Complete | 2026-01-25 |
| 2. Core Generation Pipeline | 3/3 | Complete | 2026-01-25 |
| 3. Quality Control | 2/2 | Complete | 2026-01-25 |
| 4. Frontend Streaming Client | 1/1 | Complete | 2026-01-26 |
| 5. Single-Node Generation UI | 1/1 | Complete | 2026-01-26 |
| 6. Field-Level Assists | 0/3 | Not started | - |
| 7. Batch Processing | 0/1 | Not started | - |
| 8. Provider Management | 0/1 | Not started | - |
| 9. Configuration Management | 0/1 | Not started | - |
