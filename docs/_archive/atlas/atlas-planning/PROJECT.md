# Narrative Node Generator - AI Integration

## What This Is

A full-stack TypeScript application for generating narrative nodes for game/interactive fiction content using LLM-powered AI. The app supports 7 node types (combat, choice, trade, rest, passage, state_check, transition) across 8 biomes, with a 3-stage generation pipeline (beat outlining → prose expansion → critic review). Users can create nodes manually through a multi-step wizard or generate them with AI assistance using minimal input.

## Core Value

Generate complete, high-quality narrative nodes with minimal manual effort through AI-powered content creation.

## Requirements

### Validated

<!-- Shipped and working in the existing codebase -->

- ✓ Manual node creation via multi-step wizard — existing
- ✓ Node CRUD operations (create, read, update, delete) — existing
- ✓ Multi-step form with type-specific fields — existing
- ✓ Discriminated union type safety across 7 node types — existing
- ✓ Database schema with nodes, biomes, distributions, lookup tables — existing
- ✓ LLM provider configuration tables (llmProviders, generationSettings) — existing
- ✓ Advanced config tables (beat_roles, beat_sequences, style_guide, vernacular, act_tones) — existing
- ✓ Basic config API endpoints — existing
- ✓ Zod validation across all layers — existing
- ✓ PostgreSQL database with Drizzle ORM — existing

### Active

<!-- Current scope - completing AI generation features -->

**Phase 6: AI Generation UI (Current Focus)**
- [ ] Single node AI generation with streaming progress
- [ ] Real-time SSE streaming from backend to frontend
- [ ] GenerationProgress component showing 3-stage pipeline
- [ ] Quick Generate flow (type + biome → full node)
- [ ] Assisted Create flow (hybrid manual/AI with field-level assists)
- [ ] Bulk Generate flow with distribution gap analysis
- [ ] DistributionGapChart visualization
- [ ] "Generate Hook" and "Suggest Beats" AI assist buttons in manual forms

**Integration Work (Blocking Phase 6)**
- [ ] Wire up LLM client to generation service endpoints
- [ ] Connect streaming.ts SSE to frontend hooks
- [ ] Fix batch-processor integration with progress callbacks
- [ ] Connect prompt-builder to generation pipeline
- [ ] Integrate critic stage with retry logic

**Phase 7: Testing & Polish**
- [ ] Test infrastructure setup (Vitest + React Testing Library)
- [ ] Unit tests for generation service
- [ ] Integration tests for API routes
- [ ] E2E test for single node generation flow
- [ ] Error boundaries and loading states
- [ ] Toast notifications for generation events
- [ ] Documentation updates (CLAUDE.md)

**Provider & Config Management**
- [ ] Provider management UI (/settings page)
- [ ] Provider CRUD with encrypted API keys
- [ ] Test connection functionality
- [ ] Advanced config UI (/config/advanced page)
- [ ] Beat sequence editor
- [ ] Style guide editor per biome
- [ ] Vernacular glossary editor
- [ ] Configuration import/export

### Out of Scope

- Production deployment — Local development only
- Multi-user authentication — Single-user local app
- OAuth providers — OpenRouter API key sufficient
- Mobile responsiveness — Desktop-first development
- Real-time collaboration — Single-user workflow
- Content versioning — Not needed for v1

## Context

**Brownfield codebase:**
- Application structure exists and runs (`pnpm dev` works)
- Manual node creation fully functional
- AI generation features partially implemented but not working end-to-end
- Integration issues between existing parts (services, routes, frontend)

**Reference implementation:**
- CLI tool at `/Users/rob/Projects/graph-grammar-generator` has working 3-stage pipeline
- Can port LLM client, prompt templates, batch processing patterns
- Beat sequences, style guides, distributions already defined in CLI config

**Technical environment:**
- Bun + Hono + Drizzle + React monorepo
- PostgreSQL database with comprehensive schema
- LLM SDKs already installed (openai, @anthropic-ai/sdk)
- TanStack Query for server state, Zustand for client state

**Current blockers:**
- Parts work in isolation but don't connect properly
- Streaming SSE not wired up frontend-to-backend
- Generation service files exist but aren't integrated with API routes
- Frontend generation UI components exist but hooks don't call working endpoints

## Constraints

- **Tech Stack**: Bun, Hono, Drizzle, React — existing stack must be preserved
- **LLM Provider**: OpenRouter for access to Claude Sonnet 4 and other models
- **Deployment**: Local development only, no production deployment concerns
- **Budget**: API costs minimized through OpenRouter's competitive pricing

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Single-table node design | All 7 node types in one table with nullable type-specific fields | — Pending |
| 3-stage generation pipeline | Beat outline → prose expand → critic ensures quality | — Pending |
| OpenRouter as primary provider | Access to multiple models including Claude Sonnet 4 | — Pending |
| SSE for streaming | Real-time progress updates without polling | — Pending |
| Brownfield completion approach | Fix integration issues rather than rewrite | — Pending |

---
*Last updated: 2026-01-25 after initialization*
