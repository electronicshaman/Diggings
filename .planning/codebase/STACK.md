# Technology Stack

**Analysis Date:** 2026-03-09

## Languages

**Primary:**
- TypeScript 5.3.3 - All packages (backend, frontend, shared)

**Secondary:**
- SQL - PostgreSQL schema via Drizzle ORM migrations in `packages/atlas/packages/backend/drizzle/`

## Runtime

**Environment:**
- Bun (latest) - Backend runtime and task runner; also used for frontend dev in some scripts
- Node >=20.0.0 - Required as engine constraint for tooling compatibility

**Package Manager:**
- pnpm >=8.0.0
- Lockfile: `packages/atlas/pnpm-lock.yaml` (present)
- Workspace config: `packages/atlas/pnpm-workspace.yaml`

## Frameworks

**Core - Backend:**
- Hono ^4.0.0 - HTTP framework for the Bun API server; used with built-in `cors`, `logger`, `prettyJSON` middleware
- Drizzle ORM ^0.36.0 - PostgreSQL ORM with schema-first approach; migrations in `packages/atlas/packages/backend/drizzle/`
- `@hono/zod-validator` ^0.2.1 - Route-level request validation middleware

**Core - Frontend:**
- React ^18.2.0 + React DOM - SPA UI framework
- Vite ^5.0.8 - Frontend build tool; config at `packages/atlas/packages/frontend/vite.config.ts`
- React Router DOM ^6.21.0 - Client-side routing
- TanStack Query (React Query) ^5.17.0 - Server state management, query caching, mutations
- Zustand ^4.4.7 - Client-side UI state (two stores: form-store, ui-store)
- React Hook Form ^7.49.0 + `@hookform/resolvers` ^3.3.3 - Form state and Zod-backed validation

**UI Component Layer:**
- Tailwind CSS ^4.1.18 + `@tailwindcss/vite` ^4.1.18 - Utility CSS (Vite plugin integration)
- Radix UI - Headless primitives: checkbox, dialog, dropdown-menu, label, progress, scroll-area, select, separator, slider, slot, switch, tabs, tooltip
- `class-variance-authority` ^0.7.0 + `clsx` ^2.1.0 + `tailwind-merge` ^2.2.0 - shadcn/ui pattern for variant-safe component classes
- Lucide React ^0.563.0 - Icon library
- `next-themes` ^0.4.6 - Dark/light theme toggle
- Sonner ^2.0.7 - Toast notifications

**Testing:**
- Vitest ^1.6.1 - Unit/integration test runner for all packages; workspace config at `packages/atlas/vitest.workspace.ts`
- `@vitest/coverage-v8` ^1.6.1 - Coverage provider
- `@testing-library/react` ^16.0.0 + `@testing-library/user-event` ^14.5.2 - Frontend component testing
- `@testing-library/jest-dom` ^6.4.8 - DOM assertions
- `jsdom` ^25.0.1 - DOM environment for frontend tests
- Playwright ^1.58.2 - E2E tests; config at `packages/atlas/playwright.config.ts`

**Build/Dev:**
- Drizzle Kit ^0.30.0 - Schema diffing and migration generation; config at `packages/atlas/packages/backend/drizzle.config.ts`
- `bun run --watch` - Backend hot-reload dev mode

## Key Dependencies

**Critical:**
- `zod` ^3.22.4 - Schema definition across all packages; is the single source of truth for types
- `@atlas/shared` (workspace:*) - Internal package exposing Zod schemas, TypeScript types, and constants consumed by both backend and frontend
- `postgres` ^3.4.3 - Low-level PostgreSQL client used by Drizzle
- `openai` ^4.77.0 - OpenAI SDK; also used as the client for OpenRouter (same API surface)
- `@anthropic-ai/sdk` ^0.32.0 - Anthropic Claude API client
- `opossum` ^9.0.0 - Circuit breaker library wrapping LLM completion calls; config in `packages/atlas/packages/backend/src/services/generation/circuit-breaker.ts`

**Infrastructure:**
- Docker / docker-compose - PostgreSQL container only (`nodegen-postgres`); backend/frontend Docker services are broken and not used in dev
- PostgreSQL 16-alpine - Primary database, running in Docker

## Configuration

**Environment:**
- Backend env file: `packages/atlas/packages/backend/.env` (create from `.env.example`)
- Required vars: `DATABASE_URL`, `PORT`, `NODE_ENV`, `ENCRYPTION_KEY` (32+ chars, required for production AES-256-GCM key encryption; dev falls back to base64)
- Frontend env: `VITE_API_URL` set in docker-compose but not required in local dev (Vite proxy handles `/api` → `http://localhost:3000`)

**Build:**
- Backend: `bun build src/index.ts --outdir dist --target bun`
- Frontend: `tsc && vite build` (TypeScript compile then Vite bundle)
- TypeScript configs per package: `packages/atlas/packages/backend/tsconfig.json`, `packages/atlas/packages/frontend/`, `packages/atlas/packages/shared/`

**Path Aliases:**
- Frontend uses `@` alias resolving to `packages/atlas/packages/frontend/src/` (configured in `vite.config.ts`)

## Platform Requirements

**Development:**
- Bun (backend runtime)
- pnpm >=8.0.0
- Node >=20.0.0 (tooling)
- Docker (for PostgreSQL container only)

**Production:**
- No production deployment configuration detected; Dockerfiles present but broken for backend/frontend services
- Backend: `bun run dist/index.js` after build

---

*Stack analysis: 2026-03-09*
