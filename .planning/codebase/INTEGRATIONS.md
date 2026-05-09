# External Integrations

**Analysis Date:** 2026-03-09

## APIs & External Services

**LLM Providers (user-configured, stored in database):**
- OpenAI - Chat completions for content generation
  - SDK/Client: `openai` ^4.77.0 (`packages/atlas/packages/backend/src/services/generation/llm-client.ts`)
  - Auth: API key stored encrypted in `llm_providers` table; decrypted at runtime using `ENCRYPTION_KEY`
  - Endpoint: `https://api.openai.com` (default)

- OpenRouter - OpenAI-compatible multi-model proxy
  - SDK/Client: `openai` ^4.77.0 (same client, custom `baseURL`)
  - Auth: API key stored encrypted in `llm_providers` table
  - Special headers: `HTTP-Referer: https://github.com/node-gen-web`, `X-Title: Node Gen Web`
  - Base URL: Configurable per provider record in database

- Anthropic Claude - Direct Claude API for content generation
  - SDK/Client: `@anthropic-ai/sdk` ^0.32.0 (`packages/atlas/packages/backend/src/services/generation/llm-client.ts`)
  - Auth: API key stored encrypted in `llm_providers` table; decrypted at runtime using `ENCRYPTION_KEY`

**Provider Management:**
- Providers are CRUD-managed via `GET/POST/PUT/DELETE /api/llm/providers`
- Only one provider is "active" at a time (`isActive` flag in `llm_providers` table)
- Provider test endpoint: `POST /api/llm/providers/test`
- Provider selection is dynamic at generation time via `getActiveProvider()` in `packages/atlas/packages/backend/src/services/generation/llm-client.ts`

## Data Storage

**Databases:**
- PostgreSQL 16-alpine
  - Connection: `DATABASE_URL` env var (default: `postgresql://nodegen:nodegen_dev_password@localhost:5432/nodegen`)
  - Client: Drizzle ORM + `postgres` driver (`packages/atlas/packages/backend/src/db/index.ts`)
  - Schema: `packages/atlas/packages/backend/src/db/schema.ts`
  - Migrations: `packages/atlas/packages/backend/drizzle/`
  - Dev: Docker container `nodegen-postgres` via `packages/atlas/docker-compose.yml`

**File Storage:**
- Local filesystem only - no object storage detected

**Caching:**
- None server-side - TanStack Query provides client-side cache in the frontend

## Authentication & Identity

**Auth Provider:**
- None - no user authentication system detected
- The application has no login/session management; it is a single-user tool
- API key security: LLM provider API keys are encrypted at rest using AES-256-GCM (production) or base64 (development fallback) via `packages/atlas/packages/backend/src/middleware/encryption.ts`

## Monitoring & Observability

**Error Tracking:**
- None - no external error tracking service (Sentry, etc.) detected

**Logs:**
- Hono built-in `logger()` middleware - structured HTTP request logging to stdout
- `console.error` / `console.log` throughout backend services
- Circuit breaker emits log events on state changes (open/half-open/close) via `packages/atlas/packages/backend/src/services/generation/circuit-breaker.ts`

**Circuit Breaker:**
- `opossum` library wraps LLM completion calls; opens after 50% failure rate in 10s window, recovers after 30s
- Implemented in `packages/atlas/packages/backend/src/services/generation/circuit-breaker.ts`

## CI/CD & Deployment

**Hosting:**
- Not configured for production deployment

**CI Pipeline:**
- None detected (no `.github/workflows/`, no CI config files)

## Environment Configuration

**Required env vars (backend):**
- `DATABASE_URL` - PostgreSQL connection string
- `PORT` - HTTP server port (default: 3000)
- `NODE_ENV` - Runtime environment
- `ENCRYPTION_KEY` - 32+ character string for AES-256-GCM API key encryption (required in production, optional in dev)

**Optional env vars (frontend via Vite):**
- `VITE_API_URL` - API base URL (only used in Docker; Vite dev proxy handles `/api` → `http://localhost:3000` locally)

**Secrets location:**
- LLM provider API keys: encrypted in PostgreSQL `llm_providers.encrypted_api_key` column
- `ENCRYPTION_KEY`: `packages/atlas/packages/backend/.env` (never committed; `.env.example` provided)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None - all external calls are request/response to LLM provider APIs

## Streaming

**Server-Sent Events (SSE):**
- Node content generation: `POST /api/generate` responds with SSE stream; events: `progress`, `partial`, `complete`, `error`, `ping`
  - Implementation: `packages/atlas/packages/backend/src/services/generation/streaming.ts`
- Bulk card generation: `POST /api/generate/cards/bulk` responds with SSE stream; events: `bulk_start`, `card_start`, `card_complete`, `card_error`, `bulk_complete`, `ping`
  - Implementation: `packages/atlas/packages/backend/src/routes/generate-cards.ts`
- Heartbeat ping sent every 12 seconds on both SSE streams to keep connection alive

---

*Integration audit: 2026-03-09*
