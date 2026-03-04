# Technology Stack

**Analysis Date:** 2026-01-25

## Languages

**Primary:**
- TypeScript 5.3.3 - All source code across backend, frontend, and shared packages
- JavaScript (ES2022+ targeting) - Runtime target for all packages

**Secondary:**
- YAML - Docker Compose and pnpm workspace configuration
- SQL - Database migrations and schema (PostgreSQL dialect)

## Runtime

**Environment:**
- Bun 1.x - Runtime for both backend development and execution
- Node.js >= 20.0.0 - Minimum required version (per package.json engines)

**Package Manager:**
- pnpm >= 8.0.0 - Workspace monorepo manager
- Lockfile: `pnpm-lock.yaml` (present)

## Frameworks

**Core:**
- Hono 4.0.0 - Backend HTTP framework (web server with routing, middleware, CORS)
- React 18.2.0 - Frontend UI library
- React Router DOM 6.21.0 - Client-side routing

**Database:**
- Drizzle ORM 0.36.0 - Type-safe database ORM for PostgreSQL
- Drizzle Kit 0.30.0 - Migration generation and studio tools
- postgres 3.4.3 - PostgreSQL client library

**Form & Validation:**
- Zod 3.22.4 - Runtime schema validation (shared across all packages)
- React Hook Form 7.49.0 - Frontend form state and validation
- @hookform/resolvers 3.3.3 - Zod integration for React Hook Form
- @hono/zod-validator 0.2.1 - Backend request validation middleware

**Styling:**
- Tailwind CSS 4.1.18 - Utility-first CSS framework
- @tailwindcss/vite 4.1.18 - Vite plugin for Tailwind
- class-variance-authority 0.7.0 - Component variant management
- clsx 2.1.0 - Conditional className utility
- tailwind-merge 2.2.0 - Merge Tailwind classes intelligently

**UI Components:**
- shadcn/ui (via Radix UI) - Headless component library
  - @radix-ui/react-checkbox 1.3.3
  - @radix-ui/react-dialog 1.1.15
  - @radix-ui/react-dropdown-menu 2.1.16
  - @radix-ui/react-label 2.1.8
  - @radix-ui/react-progress 1.1.8
  - @radix-ui/react-scroll-area 1.2.10
  - @radix-ui/react-select 2.2.6
  - @radix-ui/react-separator 1.1.8
  - @radix-ui/react-slider 1.3.6
  - @radix-ui/react-slot 1.2.4
  - @radix-ui/react-switch 1.2.6
  - @radix-ui/react-tabs 1.1.13
  - @radix-ui/react-tooltip 1.2.8

**State Management:**
- TanStack React Query 5.17.0 - Server state management (data fetching, caching)
- Zustand 4.4.7 - Lightweight client state management
- next-themes 0.4.6 - Theme provider (light/dark mode)

**Utilities:**
- Sonner 2.0.7 - Toast notifications
- lucide-react 0.563.0 - Icon library

**Testing:**
- Not detected

**Build/Dev:**
- Vite 5.0.8 - Frontend build tool and dev server
- @vitejs/plugin-react 4.2.1 - React support for Vite
- TypeScript compiler (tsc) - Type checking

**LLM Integrations:**
- OpenAI 4.77.0 - OpenAI API client
- @anthropic-ai/sdk 0.32.0 - Anthropic API client (for Claude models)

## Key Dependencies

**Critical:**
- Hono - Server routing and middleware framework; core to API structure
- Drizzle ORM - Type-safe database layer; critical for data persistence
- React + React Router - Frontend application framework
- Zod - Shared validation schema across all layers

**Infrastructure:**
- postgres - Direct PostgreSQL connection management
- TanStack React Query - Manages all frontend data fetching and server state

## Configuration

**Environment:**
- DATABASE_URL - PostgreSQL connection string (required for backend)
  - Default: `postgresql://nodegen:nodegen_dev_password@localhost:5432/nodegen`
  - Used in `packages/backend/src/db/index.ts` and drizzle.config.ts
- PORT - Backend server port (default: 3000)
- VITE_API_URL - Frontend API base URL (optional, defaults to relative `/api`)

**Build:**
- `packages/backend/tsconfig.json` - Backend TypeScript configuration (ES2022 target, Bun types)
- `packages/frontend/tsconfig.json` - Frontend TypeScript configuration (ES2020 target, React JSX)
- `packages/shared/tsconfig.json` - Shared package TypeScript configuration
- `packages/backend/drizzle.config.ts` - Drizzle ORM configuration
- `packages/frontend/vite.config.ts` - Vite build and dev server configuration
- `pnpm-workspace.yaml` - Workspace configuration

## Platform Requirements

**Development:**
- Node.js >= 20.0.0
- pnpm >= 8.0.0
- Docker & Docker Compose (for PostgreSQL development container)
- Bun runtime

**Production:**
- Bun runtime for server execution
- PostgreSQL 16 database (as configured in docker-compose.yml)
- Environment variables: DATABASE_URL, PORT (optional)

## Docker Setup

**Services** (docker-compose.yml):
- `postgres:16-alpine` - PostgreSQL database container (port 5432)
- `backend` - Bun application running on port 3000
- `frontend` - Vite dev server running on port 5173

**Build Image for Backend:**
- Base: `oven/bun:1-alpine`
- Workdir: `/app`
- Entrypoint: `bun run dev` (for development)

---

*Stack analysis: 2026-01-25*
