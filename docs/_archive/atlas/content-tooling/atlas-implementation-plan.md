# Node Generator Web Application - Implementation Plan

## Current Status ✓

**✅ COMPLETED: Phases 1-4 (Backend + Frontend Browse UI)**

- **Monorepo**: `/Users/rob/Projects/node-gen-web/` with pnpm workspace
- **Shared package**: All Zod schemas, types, and constants ported (700+ lookup entries)
- **Backend**: Hono API with full CRUD, Drizzle ORM schema, seed scripts
- **Docker**: PostgreSQL + backend + frontend services configured
- **Frontend Foundation**: Vite + React + TypeScript + Tailwind CSS v4
  - Node 20 pinned in `.nvmrc`
  - 19 shadcn/ui components installed via CLI
  - TanStack Query hooks for all API endpoints
  - Zustand store for filter state persistence
- **Browse UI Complete**:
  - Node list page with type/biome/acts filters, search, cards/table view toggle
  - Node detail page with tabs (Metadata, Eligibility, Content)
  - Delete confirmation dialog with API integration
  - Loading skeletons and empty states

**✅ COMPLETED: Phase 5 - Create/Edit Forms**

- Multi-step wizard (5 steps: type select, base fields, type-specific, eligibility, review)
- Form store with Zustand for wizard state management
- Base node form with React Hook Form + Zod validation
- 7 type-specific forms with biome-scoped dropdown data from config API
- Visual eligibility builder supporting all 8 condition types (flag, resource, tag, biome, act, difficulty, cooldown, seen)
- allOf/anyOf/noneOf expression wrappers
- Review step with full data preview and create mutation

**✅ COMPLETED: Phase 6 - Polish & Testing**

- Toaster component added to main.tsx with Sonner
- Fixed type-specific forms to use correct API response structure
- Backend database verified: migrations, seeding, and API endpoints working
- E2E tested with Playwright:
  - Node list page renders with filters
  - Create node wizard works through all steps
  - Combat form loads biome-scoped enemy types from API
  - Form navigation (Back/Next) works correctly

**✅ COMPLETED: Phase 7 - Config Page & Final Polish**

- Config page with 3 tabs:
  - Distributions matrix (biome × node type targets)
  - Current stats (actual vs target with color coding)
  - Biomes list with themes and entity types
- Edit page (`/nodes/:id/edit`) with pre-populated form
- Error boundary wrapping the entire app
- All routes properly configured

**🔄 NEXT: Phase 8 - Migration**

1. Create import script for existing CLI nodes
2. Test import with 181 nodes from graph-grammar-generator
3. Verify all node types import correctly

---

## Immediate Next Steps: Backend Testing

### Step 1: Install Dependencies

```bash
cd /Users/rob/Projects/node-gen-web
pnpm install
```

**Expected**: All packages install cleanly (shared, backend, frontend)

### Step 2: Generate Database Migrations

```bash
cd packages/backend
pnpm db:generate
```

**Expected**: Drizzle generates migration files in `packages/backend/drizzle/`

### Step 3: Start PostgreSQL

```bash
cd /Users/rob/Projects/node-gen-web
docker-compose up -d postgres
```

**Expected**: PostgreSQL container starts on port 5432

### Step 4: Run Migrations

```bash
cd packages/backend
pnpm db:migrate
```

**Expected**:

- Creates all tables (nodes, biomes, distributions, 10 lookup tables)
- Enums created (node_type, biome, dilemma_type, rest_type, interruption_chance)
- Indexes created (type_idx, biome_idx, node_id_idx)

### Step 5: Seed Configuration Data

```bash
pnpm db:seed
```

**Expected**:

- 8 biomes inserted
- 56 distribution entries (8 biomes × 7 node types)
- 700+ lookup entries (enemy types, environmental contexts, dream hooks, etc.)
- Console output: "🎉 Database seeding complete!"

### Step 6: Start Backend Server

```bash
pnpm dev
```

**Expected**: Server starts on `http://localhost:3000`

### Step 7: Test API Endpoints

```bash
# Health check
curl http://localhost:3000/health

# Get biomes (should return 8)
curl http://localhost:3000/api/config/biomes

# Get distributions matrix
curl http://localhost:3000/api/config/distributions

# Get enemy types for township (should return 10)
curl http://localhost:3000/api/config/lookup/enemy-types?biome=township

# Get environmental contexts for the_mines
curl http://localhost:3000/api/config/lookup/environmental-contexts?biome=the_mines

# List nodes (empty initially)
curl http://localhost:3000/api/nodes

# Get stats (should show 0 total)
curl http://localhost:3000/api/search/stats
```

**Expected**:

- All endpoints return JSON
- Biome and lookup data matches seeded values
- No TypeScript or runtime errors

### Step 8: Create Test Node via API

```bash
curl -X POST http://localhost:3000/api/nodes \
  -H "Content-Type: application/json" \
  -d '{
    "id": "TWN_CMB_001",
    "type": "combat",
    "biome": "township",
    "name": "Drunk Miner Brawl",
    "acts": [1],
    "isReplaceable": true,
    "replacementTags": ["combat", "township", "low_threat"],
    "themes": ["civilization", "desperation"],
    "entityTypes": ["human"],
    "enemyTypeHooks": ["drunk_miner", "gang_member"],
    "environmentalContext": "saloon",
    "estimatedCombatDifficulty": 2
  }'

# Verify node was created
curl http://localhost:3000/api/nodes/TWN_CMB_001

# List nodes (should show 1 node)
curl http://localhost:3000/api/nodes

# Search for "drunk"
curl "http://localhost:3000/api/search?q=drunk"

# Delete test node
curl -X DELETE http://localhost:3000/api/nodes/TWN_CMB_001
```

**Expected**:

- POST returns 201 with created node
- GET returns the node with all fields
- Search finds the node
- DELETE succeeds

### Step 9 (Optional): Import Existing CLI Nodes

Create import script at `packages/backend/src/db/import-cli-nodes.ts`:

```typescript
import { db, nodes } from "./index.js";
import { readdir, readFile } from "fs/promises";
import { join } from "path";
import { AnyNodeMetadataSchema } from "@node-gen-web/shared";

async function importNodes(sourceDir: string) {
  const files = await readdir(sourceDir);
  const jsonFiles = files.filter((f) => f.endsWith(".json"));

  console.log(`Found ${jsonFiles.length} JSON files to import`);

  for (const file of jsonFiles) {
    const content = await readFile(join(sourceDir, file), "utf-8");
    const data = JSON.parse(content);

    // Validate with Zod
    const validated = AnyNodeMetadataSchema.parse(data);

    // Transform and insert (reuse logic from POST endpoint)
    // ... (similar to routes/nodes.ts POST handler)

    console.log(`✓ Imported ${validated.id}`);
  }

  console.log("Import complete!");
}

const sourceDir =
  process.argv[2] ||
  "/Users/rob/Projects/graph-grammar-generator/nodes-improved";
importNodes(sourceDir).catch(console.error);
```

Run import:

```bash
bun run src/db/import-cli-nodes.ts /Users/rob/Projects/graph-grammar-generator/nodes-improved
```

**Expected**:

- All 181 CLI nodes imported
- Stats endpoint shows correct counts by type/biome
- Node IDs preserved (TWN_CMB_001, etc.)

---

## What Happens After Testing Succeeds

Once the backend is verified working (Steps 1-9 above), we proceed with frontend development:

**Phase 3: Frontend Foundation** (1-2 hours)

- Initialize Vite + React + TypeScript + Tailwind CSS
- Set up React Router, TanStack Query, Zustand
- Install and configure shadcn/ui components
- Create basic layout (Header, Sidebar, main content area)

**Phase 4: Browse Nodes UI** (2-3 hours)

- Node list page with cards/table view
- Filtering by type, biome, acts
- Search integration
- Node detail page (read-only tabs for metadata, content, eligibility)

**Phase 5: Create/Edit Forms** (4-6 hours)

- Multi-step form wizard
- 7 type-specific forms (Combat, Choice, Trade, Rest, Passage, StateCheck, Transition)
- Biome-scoped dropdowns (fetch from `/api/config/lookup/*`)
- Visual eligibility builder (boolean expression tree editor)
- Form validation with React Hook Form + Zod

**Phase 6: Polish & Testing** (2-3 hours)

- Error handling and loading states
- Toast notifications
- Optimistic updates
- End-to-end testing of CRUD workflows using **Playwright MCP**
- Automated verification of all 7 node type creation forms
- Screenshot documentation of key UI states

**Testing Strategy**: Use Playwright MCP throughout development to:

- Verify each component as it's built (browser_snapshot after implementing)
- Test responsive behavior and edge cases (browser_resize)
- Capture console errors (browser_console_messages)
- Document working features with screenshots (browser_take_screenshot)
- Validate form submissions and API integration

**Total Estimated Time**: 10-15 hours of focused work

---

## Critical Files Already Created

### Shared Package (`packages/shared/`)

- ✅ `src/schemas/node.ts` - All node Zod schemas (7 types)
- ✅ `src/schemas/eligibility.ts` - Eligibility/condition schemas
- ✅ `src/types/node.ts` - TypeScript node types
- ✅ `src/types/biome.ts` - Biome/Act enums and types
- ✅ `src/types/eligibility.ts` - Eligibility TypeScript types
- ✅ `src/constants/biomes.ts` - Act presence by biome
- ✅ `src/constants/distributions.ts` - 181-node distribution matrix
- ✅ `src/constants/defaults.ts` - Themes, entity types, difficulty pools
- ✅ `src/constants/lookup-data.ts` - 700+ lookup entries

### Backend Package (`packages/backend/`)

- ✅ `src/db/schema.ts` - Drizzle schema (nodes table + 11 config tables)
- ✅ `src/db/index.ts` - Database client
- ✅ `src/db/migrate.ts` - Migration runner
- ✅ `src/db/seed.ts` - Configuration seeding
- ✅ `src/index.ts` - Hono app entry point
- ✅ `src/routes/nodes.ts` - Node CRUD endpoints
- ✅ `src/routes/config.ts` - Configuration endpoints (10 lookup types)
- ✅ `src/routes/search.ts` - Search and stats endpoints
- ✅ `drizzle.config.ts` - Drizzle kit configuration

### Root Configuration

- ✅ `pnpm-workspace.yaml` - Monorepo workspace
- ✅ `docker-compose.yml` - PostgreSQL + backend + frontend services
- ✅ `.gitignore` - Ignore patterns
- ✅ `README.md` - Project documentation

**Total Lines of Code Written**: ~2,500 LOC

---

## Overview

Transform the `node-gen` CLI tool into a full-stack web application for creating, editing, and browsing narrative graph nodes. Replace programmatic generation with UI-first form-based workflows backed by PostgreSQL.

**Tech Stack:**

- Frontend: React + TypeScript + Tailwind CSS + shadcn/ui
- Forms: React Hook Form + Zod (shared schemas)
- State: TanStack Query (server) + Zustand (UI)
- Backend: Bun + Hono
- Database: PostgreSQL + Drizzle ORM
- Deploy: Docker Compose (local dev)

**Scope:** Single-user tool, no authentication, completely separate from CLI codebase.

---

## Architecture Decisions

### 1. Monorepo Structure

```
node-gen-web/
├── packages/
│   ├── shared/     # Zod schemas, types, constants (from CLI)
│   ├── backend/    # Hono API + Drizzle ORM
│   └── frontend/   # React + Vite
├── docker-compose.yml
└── pnpm-workspace.yaml
```

**Rationale:** Share Zod schemas and types between frontend/backend, simplify development.

### 2. Database Schema: Single Table with Nullable Fields

**nodes** table:

- Common fields (all nodes): id, nodeId, type, biome, name, acts, themes, etc.
- Type-specific fields (nullable): enemyTypeHooks, consequenceHooks, traderArchetype, etc.
- Complex data (JSONB): eligibility, content, actVariants

**Configuration tables:** biomes, distributions, enemyTypes, environmentalContexts, etc.

**Rationale:**

- Discriminated union maps cleanly to single table
- PostgreSQL JSONB handles nested structures (eligibility criteria)
- Simpler queries than table-per-type approach
- Easy to add/modify fields

### 3. UI-First Generation Strategy

Replace CLI generators with multi-step form wizards:

**Step 1:** Choose node type (Combat, Choice, Trade, etc.)
**Step 2:** Base fields (name, biome, acts, themes, entityTypes)
**Step 3:** Type-specific fields (dynamic form based on selected type)
**Step 4:** Eligibility criteria builder (visual boolean expression editor)
**Step 5:** Review and create

**Key Features:**

- Biome-scoped dropdowns (enemy types, environmental contexts pulled from API)
- Smart defaults (auto-generate ID, replacement tags)
- Visual eligibility builder (replaces probabilistic CLI generation)
- Real-time validation with Zod

### 4. API Design

**Hono Routes:**

```
GET    /api/nodes              List nodes (filterable)
GET    /api/nodes/:nodeId      Get single node
POST   /api/nodes              Create node
PUT    /api/nodes/:nodeId      Update node
PATCH  /api/nodes/:nodeId      Partial update
DELETE /api/nodes/:nodeId      Delete node

GET    /api/config/biomes      List biomes
GET    /api/config/distributions   Get distribution matrix
GET    /api/config/lookup/:type    Get lookup data (enemy types, etc.)

GET    /api/search?q=...       Full-text search
GET    /api/search/stats       Distribution stats
```

**Validation:** Dual validation (client + server) using shared Zod schemas

---

## Critical Files to Migrate from CLI

These files contain the data model and configuration that will be ported to the web app:

### Zod Schemas (→ packages/shared/src/schemas/)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/core/validators/schema.ts`

- `AnyNodeMetadataSchema` (discriminated union)
- `CombatNodeSchema`, `ChoiceNodeSchema`, etc. (7 type-specific schemas)
- `NodeContentSchema`, `EligibilitySchema`, etc.

### Type Definitions (→ packages/shared/src/types/)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/types/node.ts`

- NodeType enum (7 types)
- Node metadata interfaces
- Content structures

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/types/eligibility_criteria.ts`

- Eligibility, BoolExpr, Condition types (8 condition kinds)
- Saliency, RepeatPolicy types

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/types/biome.ts`

- Biome enum (8 biomes)

### Configuration Data (→ packages/shared/src/constants/)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/config/biome-distributions.ts`

- 181-node distribution matrix (biome × type)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/config/act-distributions.ts`

- Act availability per biome (weights 0-4)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/config/defaults.ts`

- Themes per biome (5 each)
- Entity types per biome (3-4 each)
- Combat difficulty pools
- Node name prefixes

### Lookup Data (→ Database Seed Scripts)

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/core/generators/combat.ts`

- ENEMY_TYPE_HOOKS (64 total: 8 per biome)
- ENVIRONMENTAL_CONTEXTS (80 total: 10 per biome)
- Difficulty distributions

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/core/generators/choice.ts`

- CONSEQUENCE_HOOKS (biome-specific)
- Dilemma type weights

**Source:** `/Users/rob/Projects/graph-grammar-generator/src/core/generators/rest.ts`

- DREAM_HOOKS (10 per biome)
- Rest type availability

**Source:** Similar patterns in `trade.ts`, `passage.ts`, `state-check.ts`, `transition.ts`

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Setup:**

1. Initialize monorepo (pnpm workspace)
2. Create package structure (shared, backend, frontend)
3. Port Zod schemas from CLI to `packages/shared`
4. Port types and constants
5. Set up Docker Compose with PostgreSQL

**Deliverable:** Monorepo with shared schemas, database running

### Phase 2: Backend (Week 2-3)

**Database:**

1. Define Drizzle schema in `packages/backend/src/db/schema.ts`
2. Create migrations
3. Write seed scripts for configuration tables (biomes, distributions, lookup data)

**API:**

1. Initialize Hono app with middleware (CORS, validation, error handling)
2. Implement node CRUD endpoints
3. Implement config endpoints
4. Implement search endpoints

**Deliverable:** Functional REST API with seeded database

### Phase 3: Frontend Foundation (Week 3-4)

**Setup:**

1. Initialize Vite + React + TypeScript
2. Install Tailwind CSS + shadcn/ui
3. Set up React Router, TanStack Query, Zustand
4. Create layout components (Header, Sidebar, Layout)
5. Install shadcn/ui components (Button, Input, Select, Form, Card, Dialog, Tabs)

**Deliverable:** Working frontend shell with routing and layout

### Phase 4: Browse Nodes (Week 4-5)

**Features:**

1. Node list page with filtering (type, biome, acts)
2. Search bar with full-text search
3. Grid/list view toggle
4. Pagination
5. Node detail page (read-only view with tabs)

**Deliverable:** Browsing interface for existing nodes

### Phase 5: Create Nodes (Week 5-7)

**Forms:**

1. Create `BaseNodeForm` (common fields)
2. Create 7 type-specific forms (Combat, Choice, Trade, Rest, Passage, StateCheck, Transition)
3. Implement biome-scoped field population (API-driven dropdowns)
4. Build visual eligibility criteria builder (boolean expressions, 8 condition types)
5. Create multi-step wizard (type selection → base → type-specific → eligibility → review)

**Deliverable:** Full node creation workflow

### Phase 6: Edit Nodes (Week 7-8)

**Features:**

1. Inline editing in detail page
2. Full edit mode (reuse creation forms)
3. PATCH endpoint for partial updates
4. Optimistic updates

**Deliverable:** Complete CRUD functionality

### Phase 7: Polish (Week 8-9)

**Quality:**

1. Error handling (global boundary, toast notifications)
2. Loading states (skeletons, suspense)
3. Form validation feedback
4. Testing (unit, component, E2E)
5. Documentation

**Deliverable:** Production-ready application

### Phase 8: Migration (Week 9)

**Data:**

1. Write script to import existing JSON nodes from CLI
2. Validate imported data with Zod
3. Archive CLI repository

**Deliverable:** All existing nodes migrated to PostgreSQL

---

## Key Components to Build

### Backend

**Core Services:**

- `packages/backend/src/services/node-service.ts` - CRUD operations, transformation between DB and API formats
- `packages/backend/src/services/config-service.ts` - Biome config, lookup data queries
- `packages/backend/src/services/search-service.ts` - Full-text search, stats

**Routes:**

- `packages/backend/src/routes/nodes.ts` - Node CRUD endpoints
- `packages/backend/src/routes/config.ts` - Configuration endpoints
- `packages/backend/src/routes/search.ts` - Search endpoints

**Database:**

- `packages/backend/src/db/schema.ts` - Drizzle schema (nodes, biomes, distributions, lookup tables)
- `packages/backend/src/db/seed.ts` - Seed configuration data

### Frontend

**Pages:**

- `packages/frontend/src/routes/nodes/list.tsx` - Browse/filter nodes
- `packages/frontend/src/routes/nodes/detail.tsx` - View/edit node
- `packages/frontend/src/routes/nodes/create.tsx` - Creation wizard
- `packages/frontend/src/routes/config/index.tsx` - View distributions/biomes

**Forms:**

- `packages/frontend/src/components/forms/BaseNodeForm.tsx` - Common fields
- `packages/frontend/src/components/forms/CombatForm.tsx` (+ 6 others) - Type-specific forms
- `packages/frontend/src/components/forms/EligibilityBuilder.tsx` - Visual condition builder

**Hooks:**

- `packages/frontend/src/hooks/useNodes.ts` - TanStack Query hooks (list, get)
- `packages/frontend/src/hooks/useNodeMutations.ts` - Mutations (create, update, delete)
- `packages/frontend/src/hooks/useConfig.ts` - Configuration queries

**Store:**

- `packages/frontend/src/store/ui-store.ts` - Filter state, view preferences
- `packages/frontend/src/store/form-store.ts` - Multi-step form state

---

## Docker Configuration

### docker-compose.yml

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: nodegen
      POSTGRES_USER: nodegen
      POSTGRES_PASSWORD: nodegen_dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./packages/backend
    environment:
      DATABASE_URL: postgresql://nodegen:nodegen_dev_password@postgres:5432/nodegen
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    command: bun run dev

  frontend:
    build: ./packages/frontend
    environment:
      VITE_API_URL: http://localhost:3000/api
    ports:
      - "5173:5173"
    depends_on:
      - backend
    command: bun run dev

volumes:
  postgres_data:
```

---

## Verification Plan

After implementation, verify the system end-to-end:

### 1. Database Setup

```bash
docker-compose up -d postgres
cd packages/backend
bun run db:migrate
bun run db:seed
```

**Verify:**

- PostgreSQL running on port 5432
- Tables created (nodes, biomes, distributions, lookup tables)
- Configuration data seeded (8 biomes, 181 distribution entries)

### 2. Backend API

```bash
docker-compose up backend
```

**Test endpoints:**

```bash
curl http://localhost:3000/api/config/biomes
curl http://localhost:3000/api/config/lookup/enemy-types?biome=township
curl http://localhost:3000/api/nodes?type=combat&biome=township
```

**Verify:**

- API responds with correct data
- Filtering works
- Zod validation rejects invalid payloads

### 3. Frontend (Using Playwright MCP)

```bash
docker-compose up frontend
# Frontend available at http://localhost:5173
```

**Automated UI Testing with Playwright MCP:**

Use Playwright browser automation to verify UI workflows:

1. **Navigate and take snapshot:**
   - `browser_navigate` to http://localhost:5173
   - `browser_snapshot` to verify page structure
   - Take screenshots at key points

2. **Browse nodes workflow:**
   - Verify node list page renders
   - Test filter dropdowns (type, biome, acts)
   - Test search input
   - Click on a node card → verify navigation to detail page

3. **Create Combat node workflow:**
   - Click "Create Node" button
   - Select "Combat" from type dropdown
   - Fill base fields: name="Test Combat", biome="Township", acts=[1]
   - Verify enemy type dropdown populates with township enemies
   - Select 2 enemy types
   - Select environmental context from dropdown
   - Set difficulty slider to 3
   - (Optional) Add eligibility condition: health >= 25
   - Click "Review"
   - Verify preview shows all entered data
   - Click "Create"
   - Verify redirect to node list
   - Verify new node appears in list

4. **Edit node workflow:**
   - Click on created node
   - Click "Edit" button
   - Change name field value
   - Click "Save"
   - Verify updated name displays

5. **Delete node workflow:**
   - Click "Delete" button
   - Confirm deletion in dialog
   - Verify node removed from list

**Playwright MCP Verification Steps:**

- `browser_snapshot` after each major action to verify UI state
- `browser_click` to interact with buttons/links
- `browser_type` to fill form fields
- `browser_select_option` for dropdowns
- `browser_take_screenshot` to capture evidence of correct behavior
- `browser_evaluate` to check for console errors

**Verify:**

- Forms validate correctly (required fields, min/max lengths)
- Biome changes trigger dropdown updates (enemy types, contexts)
- Eligibility builder constructs valid BoolExpr
- Optimistic updates work (immediate UI feedback)
- Error handling (toast notifications for failures)
- No console errors during workflows

### 4. End-to-End

**Create nodes of each type:**

- Combat, Choice, Trade, Rest, Passage, StateCheck, Transition
- Verify type-specific fields render correctly
- Verify each node validates against its Zod schema
- Check database for correct data storage

**Distribution stats:**

- Visit `/config` page
- Verify distribution matrix displays correctly
- Create nodes to match distribution targets
- Stats update in real-time

### 5. Migration

```bash
cd packages/backend
bun run migrate-from-json ../../../graph-grammar-generator/nodes-improved/
```

**Verify:**

- All existing JSON nodes imported
- IDs preserved (TWN_CMB_001, etc.)
- Complex eligibility criteria correctly stored as JSONB
- Content fields populated
- Node count matches: 181 total nodes

---

## Success Criteria

The implementation is complete when:

1. **All node types can be created via UI** (7 forms working)
2. **Filtering and search work** (type, biome, acts, full-text)
3. **Editing and deletion work** (inline + full edit modes)
4. **Eligibility builder supports all condition types** (8 types, nested expressions)
5. **Database stores all node metadata correctly** (no data loss)
6. **Existing CLI nodes migrate successfully** (181 nodes imported)
7. **Docker Compose runs all services** (PostgreSQL, backend, frontend)
8. **Forms validate with Zod** (client + server)
9. **No TypeScript errors** (strict mode enabled)
10. **Documentation is complete** (README, API docs, user guide)

---

## Notes

- **LLM Content Generation:** Not included in v1. Content fields (narrative_hook, beats, etc.) will be manually entered or left empty. Future enhancement could add AI-powered content generation UI.
- **Graph Visualization:** Deferred to v2 per user preference.
- **Authentication:** Not needed (single-user local tool).
- **CLI Preservation:** CLI will be archived after migration. Web app fully replaces it.
