# Architecture

**Analysis Date:** 2026-01-25

## Pattern Overview

**Overall:** Three-tier monorepo with schema-driven, full-stack TypeScript integration.

**Key Characteristics:**
- Shared schema layer drives database design, API validation, and frontend form validation
- Discriminated union types enable type-safe polymorphism across 7 narrative node types
- Single-table narrative database design with nullable type-specific fields
- Server state (TanStack Query) and client UI state (Zustand) separation in frontend
- API-first design with Hono backend and React frontend

## Layers

**Shared Layer (`packages/shared`):**
- Purpose: Define all data structures, types, and constants used by frontend and backend
- Location: `packages/shared/src/`
- Contains: Zod schemas (`schemas/`), inferred TypeScript types (`types/`), constants (`constants/`)
- Depends on: Only Zod
- Used by: Both backend and frontend via workspace protocol

**Backend Layer (`packages/backend`):**
- Purpose: Provide REST API for node CRUD, configuration management, AI generation, and LLM provider configuration
- Location: `packages/backend/src/`
- Contains: Hono routes, Drizzle ORM database layer, generation services
- Depends on: `@node-gen-web/shared`, Hono, Drizzle ORM, PostgreSQL, LLM SDKs (Anthropic, OpenAI)
- Used by: Frontend via HTTP requests to `/api/*`

**Frontend Layer (`packages/frontend`):**
- Purpose: Provide interactive React SPA for browsing nodes, creating/editing nodes, configuring biomes and distributions, generating content
- Location: `packages/frontend/src/`
- Contains: Route pages, form components, UI components (shadcn/ui), hooks for data fetching and mutations
- Depends on: `@node-gen-web/shared`, React, React Router, React Hook Form, TanStack Query, Zustand, Tailwind CSS
- Used by: End users via browser

## Data Flow

**Node Creation (Frontend → Backend → Database):**

1. User navigates to `/nodes/create`
2. Multi-step wizard form controlled by Zustand `useFormStore` (step tracking, form data accumulation)
3. Form data validated client-side using React Hook Form + Zod resolver
4. User submits complete node
5. Frontend mutation calls `POST /api/nodes` with AnyNodeMetadata payload
6. Backend validates with `@hono/zod-validator` against discriminated union schema
7. Backend generates unique `nodeId` based on biome and type (e.g., `TOWNSHIP_COMBAT_001`)
8. Drizzle inserts to `nodes` table with all common fields + type-specific nullable fields
9. Backend returns created node (ID, metadata)
10. TanStack Query invalidates nodes cache
11. Frontend navigates to `/nodes/:id`

**Node Display:**

1. Frontend fetches `/api/config` (biomes, distributions, lookup tables)
2. Frontend fetches `/api/nodes` (all nodes)
3. TanStack Query caches results (staleTime: 5 minutes)
4. User filters/searches via Zustand `useUIStore` (persisted to localStorage)
5. Components render from cached data

**Node Generation:**

1. User navigates to `/generate`
2. User selects generation parameters (biome, node type, act, batch size)
3. Frontend calls `POST /api/generate` with parameters
4. Backend retrieves LLM provider configuration from `llmProviders` table
5. Backend calls LLM (OpenAI, Anthropic, OpenRouter) with prompt templates from `packages/shared/src/constants/prompts.ts`
6. LLM generates narrative content (beats, outcomes, mood)
7. Optional: critic LLM evaluates generated content (if `enableCriticStage` in generation settings)
8. Backend stores generated nodes with `generatedBy` and `criticScore` fields
9. Frontend streams generation progress or receives completion
10. TanStack Query refetches nodes list

**State Management:**

- **Server State:** TanStack Query manages `/api/nodes`, `/api/config` queries with automatic caching and refetching
  - Query defined in `packages/frontend/src/hooks/useNodes.ts`
  - Mutations in `packages/frontend/src/hooks/useNodeMutations.ts`
  - Config query in `packages/frontend/src/hooks/useConfig.ts`
- **Client State:** Two Zustand stores
  - `useFormStore`: Multi-step form state (step, accumulated form data)
  - `useUIStore`: UI preferences (filters, view mode, persisted to localStorage)

## Key Abstractions

**Discriminated Union Node Types:**
- Purpose: Enable type-safe polymorphism across 7 node types (combat, choice, state_check, trade, passage, rest, transition)
- Examples: `CombatNodeSchema`, `ChoiceNodeSchema`, `TradeNodeSchema` in `packages/shared/src/schemas/node.ts`
- Pattern: `z.discriminatedUnion('type', [CombatNodeCreateSchema, ChoiceNodeCreateSchema, ...])` ensures correct type-specific fields at compile time
- Database: All types stored in single `nodes` table with nullable type-specific fields (e.g., `enemyTypeHooks` for combat, `dilemmaType` for choice)

**Biome-Scoped Configuration:**
- Purpose: Manage biome-specific narrative content (8 biomes total: township, the_diggings, the_bush, the_mines, the_waste, the_scar, sacred_site, the_river)
- Examples: `biomes` table, `enemyTypes`, `traderArchetypes`, `dreamHooks` lookup tables
- Pattern: `/api/config/lookup/:type?biome=...` endpoints return biome-filtered data

**Multi-Step Wizard Form:**
- Purpose: Break complex node creation into manageable steps
- Examples: `packages/frontend/src/routes/nodes/create.tsx` (5 steps: type select, base fields, type-specific fields, eligibility, review)
- Pattern: FormProvider wraps all steps, each step validates independently, store accumulates data

**Content Structure (NodeContent):**
- Purpose: Standardize narrative content across nodes
- Examples: `narrative_hook` (1-3 sentences), `beats` (story structure), `options` (for choice nodes), `outcomes` (victory/defeat/neutral), `mood` (tension, atmosphere, sensory details)
- Pattern: Defined in `packages/shared/src/schemas/node.ts` as `NodeContentSchema`

**Eligibility Builder:**
- Purpose: Allow fine-grained control over which nodes appear in which game states/contexts
- Examples: Resource cost checks, state checks, consequence hooks
- Pattern: Component `packages/frontend/src/components/forms/EligibilityBuilder.tsx` and schema `packages/shared/src/schemas/eligibility.ts`

**LLM Provider Abstraction:**
- Purpose: Support multiple LLM providers (OpenAI, Anthropic, OpenRouter)
- Examples: `llmProviders` table, `GenerationSettings` table
- Pattern: Backend loads active provider config, instantiates appropriate SDK (OpenAI, Anthropic), calls with shared prompt templates

## Entry Points

**Backend:**
- Location: `packages/backend/src/index.ts`
- Triggers: Bun runtime (via `bun run src/index.ts` or imported export)
- Responsibilities: Initialize Hono app, mount middleware (logger, cors, pretty-json), register routers, start server on configurable port (default 3000)

**Frontend:**
- Location: `packages/frontend/src/main.tsx`
- Triggers: Vite dev server or production build
- Responsibilities: Mount React app to #root element, initialize QueryClient with default options, set up BrowserRouter, ErrorBoundary, and Toaster

**Frontend Router:**
- Location: `packages/frontend/src/App.tsx`
- Triggers: React Router initialization
- Responsibilities: Define all routes (/, /nodes, /nodes/create, /nodes/:id, /nodes/:id/edit, /config, /config/advanced, /settings, /generate)

## Error Handling

**Strategy:** Return structured JSON error responses from backend; display toast notifications on frontend.

**Patterns:**

- **Backend API Errors:** Hono error handler (`app.onError()`) catches exceptions, logs to console, returns `{ error: message }` with appropriate HTTP status
  - Route validation failures return 400 with validation error details (via `@hono/zod-validator`)
  - Not found routes return 404 with `{ error: 'Not Found' }`
  - Server errors return 500 with generic error message

- **Frontend Form Errors:** React Hook Form displays field-level validation errors under inputs
  - Zod schema validation runs on submit
  - Server errors returned from mutations are displayed as toast notifications (via Sonner)

- **Client-Side Boundaries:** ErrorBoundary wraps entire app (in `packages/frontend/src/components/ErrorBoundary.tsx`)
  - Catches React render errors
  - Displays fallback UI

## Cross-Cutting Concerns

**Logging:**
- Backend uses Hono's built-in logger middleware for request/response logging
- Backend services log errors and generation progress to console
- Frontend uses browser console for development debugging

**Validation:**
- Shared layer: All schemas defined as Zod schemas in `packages/shared/src/schemas/`
- Backend: Routes use `@hono/zod-validator` middleware to validate requests against shared schemas
- Frontend: Form validation via `@hookform/resolvers/zod` for client-side validation before submission

**Authentication:**
- Not implemented; API is currently open to localhost origins (configured in CORS middleware)

**Database Connection:**
- Centralized in `packages/backend/src/db/index.ts`
- PostgreSQL connection string from environment variable `DATABASE_URL` or default localhost
- Drizzle ORM instance exported and used by all routes/services

**Type Safety:**
- All data flows through shared Zod schemas
- Database schema in Drizzle mirrors Zod schema shapes
- Frontend form types inferred from shared schemas
- Backend routes use discriminated unions for type-safe node handling

---

*Architecture analysis: 2026-01-25*
