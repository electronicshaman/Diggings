# Codebase Structure

**Analysis Date:** 2026-01-25

## Directory Layout

```
node-gen-web/                          # Monorepo root (pnpm workspace)
├── packages/
│   ├── shared/                        # Shared types, schemas, constants
│   │   └── src/
│   │       ├── schemas/               # Zod schemas for all data types
│   │       ├── types/                 # TypeScript types (inferred from schemas)
│   │       ├── constants/             # Biome data, distributions, prompts, lookup data
│   │       └── index.ts               # Barrel exports
│   ├── backend/                       # Hono API server with Drizzle ORM
│   │   ├── src/
│   │   │   ├── index.ts               # App initialization, middleware, route registration
│   │   │   ├── routes/                # API endpoints organized by resource
│   │   │   ├── services/              # Business logic (generation, LLM calls)
│   │   │   ├── db/                    # Database schema, migrations, seeding
│   │   │   └── middleware/            # Custom middleware
│   │   ├── drizzle/                   # Generated migration files and metadata
│   │   ├── dist/                      # Built output (git-ignored)
│   │   └── package.json
│   ├── frontend/                      # React SPA with Vite
│   │   ├── src/
│   │   │   ├── main.tsx               # React entry point
│   │   │   ├── App.tsx                # Route definitions
│   │   │   ├── routes/                # Page components organized by feature
│   │   │   ├── components/            # Reusable UI components
│   │   │   ├── hooks/                 # Custom React hooks
│   │   │   ├── store/                 # Zustand state stores
│   │   │   ├── lib/                   # Utilities and helpers
│   │   │   ├── index.css              # Global Tailwind styles
│   │   │   └── main.tsx               # React DOM render
│   │   ├── dist/                      # Build output (git-ignored)
│   │   └── package.json
│   └── package.json (workspace metadata)
├── pnpm-workspace.yaml                # Monorepo configuration
├── pnpm-lock.yaml                     # Lockfile
├── docker-compose.yml                 # PostgreSQL dev environment
├── package.json                       # Root workspace scripts
└── .planning/                         # GSD planning documents
    └── codebase/
```

## Directory Purposes

**`packages/shared/`:**
- Purpose: Shared data contracts and constants used by backend and frontend
- Contains: Zod schemas, TypeScript types (inferred), biome metadata, distribution configs, prompt templates
- Key files: `src/schemas/node.ts`, `src/types/node.ts`, `src/constants/biomes.ts`
- Committed to git: Yes
- Generated: No (hand-written)

**`packages/shared/src/schemas/`:**
- Purpose: Define all Zod validation schemas
- Contains: `node.ts` (node types and content), `eligibility.ts`, `beat-sequences.ts`, `llm.ts`, `style-guide.ts`, `generation.ts`
- Pattern: Each file exports base schema and discriminated union schema
- Used by: Backend (request validation), Frontend (form validation)

**`packages/shared/src/types/`:**
- Purpose: Export TypeScript types inferred from Zod schemas
- Contains: `node.ts`, `biome.ts`, `eligibility.ts`, `index.ts` (barrel)
- Pattern: `z.infer<typeof SomeSchema>` pattern for type extraction
- Used by: Both backend and frontend for type checking

**`packages/shared/src/constants/`:**
- Purpose: Store static data and templates
- Contains: `biomes.ts` (8 biomes with themes), `distributions.ts` (node type counts per biome), `prompts.ts` (LLM prompts), `lookup-data.ts` (enemy types, hooks, etc.), `defaults.ts`
- Pattern: Export arrays/objects matching database schema structure
- Used by: Seed data generation, frontend dropdowns, generation prompts

**`packages/backend/src/`:**
- Purpose: API server implementation
- Entry point: `index.ts` (creates Hono app, registers routes, starts server)
- Key subdirectories:
  - `routes/`: API endpoint handlers organized by resource
  - `db/`: Database schema, migrations, seed script
  - `services/`: Business logic for generation and LLM integration
  - `middleware/`: Custom Hono middleware

**`packages/backend/src/routes/`:**
- Purpose: Define REST API endpoints
- Files:
  - `nodes.ts`: `/api/nodes` CRUD operations (GET list, GET by ID, POST create, PUT update, DELETE)
  - `config.ts`: `/api/config/biomes`, `/api/config/distributions`, `/api/config/lookup/*` (lookup tables)
  - `search.ts`: `/api/search` (not yet implemented)
  - `generate.ts`: `/api/generate` batch node generation
  - `llm-providers.ts`: `/api/llm/providers` LLM provider CRUD and activation
  - `config-advanced.ts`: `/api/config/advanced` beat roles, beat sequences, style guide, vernacular, act tones
- Pattern: Each file exports a Hono router, registered in `index.ts` with `app.route()`

**`packages/backend/src/db/`:**
- Purpose: Database layer
- Files:
  - `schema.ts`: Drizzle ORM table definitions (142 KB file with 28 tables)
  - `index.ts`: Drizzle client initialization and exports
  - `migrate.ts`: Migration runner
  - `seed.ts`: Initial data population from shared constants
  - `seed-data/`: Additional seed data files if needed
- Pattern: All tables defined with Drizzle ORM using PostgreSQL types
- Key tables: `nodes` (main), `biomes`, `distributions`, `llmProviders`, `generationSettings`, lookup tables

**`packages/backend/src/services/generation/`:**
- Purpose: Generation business logic
- Contains: LLM prompt construction, API calls, critic evaluation
- Used by: `routes/generate.ts`

**`packages/backend/drizzle/`:**
- Purpose: Auto-generated migration files
- Contains: Migration files in SQL and TypeScript
- Committed to git: Yes (migrations are part of version control)
- Generated: Yes (via `drizzle-kit generate`)

**`packages/frontend/src/`:**
- Purpose: React SPA implementation
- Entry points: `main.tsx` (React DOM), `App.tsx` (router)
- Key subdirectories:
  - `routes/`: Page components
  - `components/`: Reusable components
  - `hooks/`: Data fetching and state hooks
  - `store/`: Zustand state

**`packages/frontend/src/routes/`:**
- Purpose: Page-level components corresponding to URL routes
- Files:
  - `nodes/list.tsx`: `/nodes` node list with filtering
  - `nodes/create.tsx`: `/nodes/create` multi-step creation wizard
  - `nodes/edit.tsx`: `/nodes/:id/edit` edit existing node
  - `nodes/detail.tsx`: `/nodes/:id` view node details
  - `config/index.tsx`: `/config` biome and distribution editor
  - `config/advanced.tsx`: `/config/advanced` beat roles, sequences, style guide, act tones
  - `settings.tsx`: `/settings` LLM provider configuration
  - `generate/index.tsx`: `/generate` batch generation UI
- Pattern: Page components fetch data via custom hooks, manage local state, render layout

**`packages/frontend/src/components/`:**
- Purpose: Reusable UI components
- Subdirectories:
  - `ui/`: shadcn/ui component library (button, input, form, dialog, etc.)
  - `forms/`: Node type-specific form components
    - `NodeTypeSelect.tsx`: Step 0 - select node type
    - `BaseNodeForm.tsx`: Step 1 - common fields (name, biome, acts, themes, entity types)
    - `CombatForm.tsx`, `ChoiceForm.tsx`, `TradeForm.tsx`, `RestForm.tsx`, `PassageForm.tsx`, `StateCheckForm.tsx`, `TransitionForm.tsx`: Step 2 - type-specific fields
    - `EligibilityBuilder.tsx`: Step 3 - eligibility and resource cost
    - `ReviewStep.tsx`: Step 4 - final review before submission
  - `layout/`: Layout wrappers (navbar, sidebar, main content area)
  - `config/`: Biome/distribution config components
  - `settings/`: LLM provider settings components
  - `generation/`: Generation UI components
  - `ErrorBoundary.tsx`: Error boundary wrapper

**`packages/frontend/src/hooks/`:**
- Purpose: Custom React hooks for data fetching and mutations
- Files:
  - `useNodes.ts`: Query hook for fetching all nodes
  - `useConfig.ts`: Query hook for biomes, distributions, lookup data
  - `useNodeMutations.ts`: Mutation hooks for create/update/delete
  - `useLLMProviders.ts`: Query and mutation hooks for LLM provider config
  - `useGeneration.ts`: Mutation hook for batch generation
  - `useAdvancedConfig.ts`: Query and mutation hooks for beat roles, sequences, style guide, act tones
- Pattern: Wrap TanStack Query (useQuery/useMutation) with business logic
- Used by: Page components and form components

**`packages/frontend/src/store/`:**
- Purpose: Local client state management
- Files:
  - `form-store.ts`: Zustand store for multi-step wizard (step tracking, accumulated form data)
  - `ui-store.ts`: Zustand store for UI preferences (filters, view mode), persisted to localStorage
- Pattern: Export `useFormStore()` and `useUIStore()` hooks
- Used by: Form components, list pages

**`packages/frontend/src/lib/`:**
- Purpose: Utility functions and helpers
- Contains: Format helpers, API client utilities, etc.

**`packages/frontend/src/index.css`:**
- Purpose: Global Tailwind CSS styles
- Pattern: Import Tailwind directives, define custom utilities

## Key File Locations

**Entry Points:**
- `packages/backend/src/index.ts`: Backend server initialization (Hono app setup, route registration)
- `packages/frontend/src/main.tsx`: React entry point (mount app to DOM, set up providers)
- `packages/frontend/src/App.tsx`: React Router setup (defines all client routes)

**Configuration:**
- `packages/backend/src/db/schema.ts`: All database table definitions
- `packages/shared/src/constants/biomes.ts`: Biome metadata and themes
- `packages/shared/src/constants/prompts.ts`: LLM prompt templates
- `docker-compose.yml`: PostgreSQL dev database configuration
- `pnpm-workspace.yaml`: Monorepo configuration (includes all packages)

**Core Logic:**
- `packages/shared/src/schemas/node.ts`: Node type discriminated unions
- `packages/backend/src/routes/nodes.ts`: Node CRUD endpoints
- `packages/backend/src/routes/generate.ts`: Generation endpoint implementation
- `packages/backend/src/services/generation/`: LLM integration logic
- `packages/frontend/src/routes/nodes/create.tsx`: Multi-step form wizard
- `packages/frontend/src/store/form-store.ts`: Form state accumulation

**Testing:**
- Not yet established (no test files in codebase)

## Naming Conventions

**Files:**
- React components: PascalCase (e.g., `NodeTypeSelect.tsx`, `CombatForm.tsx`)
- Hooks: camelCase prefixed with `use` (e.g., `useNodes.ts`, `useNodeMutations.ts`)
- Utilities/services: camelCase (e.g., `migrate.ts`, `seed.ts`)
- Schemas: kebab-case or camelCase (e.g., `beat-sequences.ts`, `eligibility.ts`)

**Directories:**
- Feature-based grouping (e.g., `routes/nodes/`, `components/forms/`)
- Type-based grouping for shared (e.g., `schemas/`, `types/`, `constants/`)
- Lowercase with dashes (e.g., `seed-data/`, `environment-contexts`)

**Code:**
- React components: PascalCase
- Functions: camelCase
- Constants: UPPER_SNAKE_CASE (in schemas and constants)
- Type names: PascalCase (e.g., `CombatNode`, `AnyNodeMetadata`)
- Enum values: snake_case (e.g., `node_type: 'combat'`)

## Where to Add New Code

**New Feature (e.g., Networking, Treasure):**
1. Add enum value to `NodeTypeSchema` in `packages/shared/src/schemas/node.ts`
2. Create type-specific schema extending `BaseNodeMetadataSchema` in same file
3. Add to discriminated union `AnyNodeMetadataSchema`
4. Update `nodeTypeEnum` in `packages/backend/src/db/schema.ts`
5. Add type-specific nullable fields to `nodes` table
6. Run `pnpm --filter @node-gen-web/backend db:generate` and `pnpm db:migrate`
7. Create form component `packages/frontend/src/components/forms/NetworkingForm.tsx`
8. Update import and add case in `packages/frontend/src/routes/nodes/create.tsx`

**New API Route (e.g., `/api/stats`):**
1. Create `packages/backend/src/routes/stats.ts` exporting Hono router
2. Define request/response schemas in `packages/shared/src/schemas/` if needed
3. Register route in `packages/backend/src/index.ts` with `app.route('/api/stats', statsRouter)`
4. Create frontend hook in `packages/frontend/src/hooks/useStats.ts` if data needs to be queried

**New Component:**
- UI component (reusable): `packages/frontend/src/components/ui/ComponentName.tsx`
- Form component: `packages/frontend/src/components/forms/ComponentName.tsx`
- Config component: `packages/frontend/src/components/config/ComponentName.tsx`
- Layout component: `packages/frontend/src/components/layout/ComponentName.tsx`

**New Page Route:**
- Create page file in `packages/frontend/src/routes/{feature}/{page}.tsx`
- Add route to `packages/frontend/src/App.tsx` in Routes
- Create hook in `packages/frontend/src/hooks/` if data fetching needed

**Shared Types/Schemas:**
- Schema: `packages/shared/src/schemas/feature-name.ts`
- Export from `packages/shared/src/schemas/index.ts`
- Types auto-inferred and exported from `packages/shared/src/types/feature-name.ts`

**Database Changes:**
1. Modify `packages/backend/src/db/schema.ts`
2. Run `pnpm --filter @node-gen-web/backend db:generate`
3. Review generated migration in `packages/backend/drizzle/`
4. Run `pnpm db:migrate`
5. Update seed data in `packages/backend/src/db/seed.ts` if needed

## Special Directories

**`packages/backend/drizzle/`:**
- Purpose: Version-controlled database migrations
- Generated: Yes (via drizzle-kit)
- Committed: Yes (migrations are part of code history)
- Manual edits: Generally avoided; regenerate when schema changes

**`packages/frontend/dist/` and `packages/backend/dist/`:**
- Purpose: Build output
- Generated: Yes (via build scripts)
- Committed: No (.gitignore)

**`node_modules/`:**
- Purpose: Installed dependencies
- Generated: Yes (via pnpm install)
- Committed: No (.gitignore)

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents
- Generated: By mapping tools
- Committed: Yes (documentation)

---

*Structure analysis: 2026-01-25*
