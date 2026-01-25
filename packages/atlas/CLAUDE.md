# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Initial Setup
```bash
# Install all dependencies
pnpm install

# Start PostgreSQL container
pnpm docker:up

# Run database migrations
pnpm db:migrate

# Seed the database with initial data
pnpm db:seed

# Start all services (frontend + backend)
pnpm dev
```

### Daily Development
```bash
# Start all services in parallel
pnpm dev

# Type checking across all packages
pnpm typecheck

# Build all packages
pnpm build
```

### Database Operations
```bash
# Generate new migration from schema changes
pnpm --filter @node-gen-web/backend db:generate

# Run migrations
pnpm db:migrate

# Seed database
pnpm db:seed

# Open Drizzle Studio (database GUI)
pnpm --filter @node-gen-web/backend db:studio
```

### Docker Management
```bash
# Start PostgreSQL
pnpm docker:up

# Stop PostgreSQL
pnpm docker:down
```

### Package-Specific Commands
```bash
# Work in a specific package
pnpm --filter @node-gen-web/backend <command>
pnpm --filter @node-gen-web/frontend <command>
pnpm --filter @node-gen-web/shared <command>

# Backend development
cd packages/backend
bun run --watch src/index.ts

# Frontend development
cd packages/frontend
bun run dev
```

## Architecture Overview

### Monorepo Structure
This is a pnpm workspace monorepo with three packages:

- **`packages/shared`**: Shared Zod schemas, TypeScript types, and constants used by both frontend and backend
- **`packages/backend`**: Bun + Hono API server with Drizzle ORM for PostgreSQL
- **`packages/frontend`**: React + TypeScript + Vite SPA with Tailwind CSS and shadcn/ui

### Data Flow Pattern

1. **Schema-First Design**: All data structures are defined as Zod schemas in `packages/shared/src/schemas/`
2. **Type Inference**: TypeScript types are inferred from Zod schemas and exported from `packages/shared/src/types/`
3. **Database Schema**: Drizzle ORM schema in `packages/backend/src/db/schema.ts` mirrors the Zod schemas
4. **API Validation**: Backend routes use `@hono/zod-validator` to validate requests against shared schemas
5. **Frontend Validation**: Forms use React Hook Form with `@hookform/resolvers/zod` for client-side validation

### Core Domain Concepts

**Narrative Graph Nodes**: The application manages a graph-based narrative system with 7 node types:
- `combat`: Combat encounters with enemy type hooks and environmental context
- `choice`: Decision points with consequence hooks and dilemma types
- `state_check`: Conditional branches based on game state
- `trade`: Trading interactions with merchant archetypes
- `passage`: Travel/movement nodes with travel event hooks
- `rest`: Rest/camping nodes with interruption chances and dream hooks
- `transition`: Act transition nodes with narrative summaries

**Biomes**: Each node belongs to one of 8 biomes (township, the_diggings, the_bush, the_mines, the_waste, the_scar, sacred_site, the_river), which determine available themes, entity types, and act presence.

**Acts**: The narrative is divided into 4 acts. Nodes can support multiple acts, and some nodes have act-specific variants with different content per act.

**Content Structure**: Node content consists of:
- `narrative_hook`: Opening text (1-3 sentences)
- `beats`: Story beats with roles (setup, escalation, reveal, choice, consequence, button, tension, relief, foreshadow, reflection)
- `options`: Choice options (for choice nodes)
- `outcomes`: Victory/defeat/neutral outcome texts
- `mood`: Tension level (1-5), atmosphere, and sensory details

### Database Architecture

**Single Table Design**: All node types are stored in a single `nodes` table with nullable type-specific fields. This avoids complex joins while maintaining type safety through discriminated unions in the application layer.

**Lookup Tables**: Biome-specific lookup data (enemy types, environmental contexts, consequence hooks, etc.) are stored in separate tables and loaded via the `/api/config` endpoint.

**Configuration Tables**:
- `biomes`: Metadata about each biome (themes, entity types, act presence)
- `distributions`: Defines how many of each node type should exist per biome

### Frontend State Management

**Server State**: TanStack Query manages all server data fetching and caching
- Queries defined in `packages/frontend/src/hooks/useNodes.ts`, `useConfig.ts`
- Mutations in `packages/frontend/src/hooks/useNodeMutations.ts`

**Client State**:
- **Zustand**: Two stores for local UI state
  - `form-store.ts`: Multi-step wizard form state (step tracking, form data accumulation)
  - `ui-store.ts`: UI preferences (sidebar collapsed state, theme, etc.)

**Form Pattern**: Multi-step wizard for node creation/editing
1. Step 0: Select node type
2. Step 1: Base metadata (name, biome, acts, themes, etc.)
3. Step 2: Type-specific fields (e.g., enemy hooks for combat, dilemma type for choice)
4. Step 3: Content creation (narrative hook, beats, options, mood)
5. Step 4: Review and submit

Each step uses React Hook Form with Zod validation, and data is accumulated in the form store.

### API Routes

**Backend** (`packages/backend/src/routes/`):
- `/api/nodes`: CRUD operations for nodes (GET list, GET by ID, POST, PUT, DELETE)
- `/api/config`: Get biomes, distributions, and lookup data
- `/api/search`: Search nodes (not yet implemented)

**Frontend Router** (`packages/frontend/src/App.tsx`):
- `/` or `/nodes`: Node list with filters
- `/nodes/create`: Multi-step node creation wizard
- `/nodes/:id`: View node details
- `/nodes/:id/edit`: Edit existing node
- `/config`: View/edit biome and distribution configuration

## Important Patterns

### Workspace Dependencies
When importing from `@node-gen-web/shared` in backend or frontend, use the workspace protocol (`workspace:*` in package.json). The TypeScript compiler resolves directly to the source files, not built output.

### Database Migrations
After changing `packages/backend/src/db/schema.ts`:
1. Run `pnpm --filter @node-gen-web/backend db:generate` to create migration files
2. Run `pnpm db:migrate` to apply migrations
3. Migrations are stored in `packages/backend/drizzle/`

### Adding New Node Types
1. Add enum value to `NodeTypeSchema` in `packages/shared/src/schemas/node.ts`
2. Create type-specific schema extending `BaseNodeMetadataSchema`
3. Add to discriminated union `AnyNodeMetadataSchema`
4. Update `nodeTypeEnum` in `packages/backend/src/db/schema.ts`
5. Add type-specific nullable fields to `nodes` table
6. Generate and run migration
7. Create form component in `packages/frontend/src/components/forms/`

### Shared Schema Pattern
All schemas follow this pattern:
- Define in `packages/shared/src/schemas/`
- Export Zod schema and inferred TypeScript type
- Backend validates with `zod-validator()`
- Frontend validates with React Hook Form + Zod resolver
- Database schema in Drizzle mirrors the Zod schema shape
