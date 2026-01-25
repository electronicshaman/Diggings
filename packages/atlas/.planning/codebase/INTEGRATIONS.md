# External Integrations

**Analysis Date:** 2026-01-25

## APIs & External Services

**LLM Providers:**
- OpenAI API - Content generation via GPT models
  - SDK: `openai@4.77.0`
  - Auth: API key stored in database (encrypted in `llmProviders` table)
  - Implementation: `packages/backend/src/services/generation/llm-client.ts`

- Anthropic API - Claude model support for content generation
  - SDK: `@anthropic-ai/sdk@0.32.0`
  - Auth: API key stored in database (encrypted in `llmProviders` table)
  - Implementation: `packages/backend/src/services/generation/llm-client.ts`

- OpenRouter - Compatible with OpenAI client, acts as proxy to multiple models
  - SDK: Uses `openai@4.77.0` with custom baseURL
  - Auth: API key stored in database (encrypted in `llmProviders` table)
  - Base URL: Configurable per provider instance
  - Implementation: `packages/backend/src/services/generation/llm-client.ts`

## Data Storage

**Databases:**
- PostgreSQL 16
  - Connection: `DATABASE_URL` environment variable (default: `postgresql://nodegen:nodegen_dev_password@localhost:5432/nodegen`)
  - Client: `postgres@3.4.3` with Drizzle ORM abstraction
  - ORM: Drizzle ORM 0.36.0
  - Schema location: `packages/backend/src/db/schema.ts`

**Database Tables:**
- Primary: `nodes` - Stores 7 node types with discriminated union pattern (nullable type-specific fields)
- Configuration: `biomes`, `distributions`, `beat_roles`, `beat_sequences`, `style_guide`
- Lookup data: `enemy_types`, `environmental_contexts`, `consequence_hooks`, `dream_hooks`, `travel_event_hooks`, `environmental_storytelling`, `condition_hooks`, `trader_archetypes`, `pricing_hooks`
- LLM: `llm_providers`, `generation_settings`
- Content: `vernacular`, `act_tones`

**File Storage:**
- Not detected - Application only uses database storage

**Caching:**
- None detected - TanStack Query manages client-side cache

## Authentication & Identity

**Auth Provider:**
- Custom - No external identity provider detected
- Implementation: API routes have no authentication checks currently
- API keys for LLM providers encrypted before storage: `packages/backend/src/middleware/encryption.ts`
  - Current method: Base64 encoding (TODO: Upgrade to AES-256 per code comments)
  - Location: `encryptedApiKey` field in `llmProviders` table

## Monitoring & Observability

**Error Tracking:**
- None detected

**Logs:**
- Console logging via Hono middleware
  - `logger()` middleware in `packages/backend/src/index.ts` logs all requests
  - Error logging to stdout in error handler

**Debug/Development Tools:**
- Drizzle Studio - Database GUI accessible via `pnpm --filter @node-gen-web/backend db:studio`

## CI/CD & Deployment

**Hosting:**
- Docker Compose setup for development/deployment
- Backend: Bun application containerized with `oven/bun:1-alpine`
- Frontend: Vite dev server containerized
- Database: PostgreSQL 16 Alpine container

**CI Pipeline:**
- None detected

**Build Commands:**
- Backend: `bun build src/index.ts --outdir dist --target bun`
- Frontend: `tsc && vite build`

## Environment Configuration

**Required env vars:**
- `DATABASE_URL` - PostgreSQL connection string (development default provided)
- `PORT` - Server port (optional, default: 3000)
- `VITE_API_URL` - Frontend API base URL (optional, defaults to relative `/api`)

**Secrets location:**
- LLM provider API keys: Stored in database table `llmProviders.encryptedApiKey` (encrypted)
- Database password: In `docker-compose.yml` environment variables (dev-only defaults)
- No .env files detected; all configuration via environment variables or database

## Webhooks & Callbacks

**Incoming:**
- Not detected - Application has no webhook ingestion endpoints

**Outgoing:**
- Not detected - No external API callbacks currently implemented

## API Routes & Backend Integration Points

**Backend API** (`packages/backend/src/routes/`):
- `/api/nodes` - Node CRUD operations (GET list, GET by ID, POST, PUT, DELETE)
- `/api/config` - Biome and distribution configuration retrieval
- `/api/search` - Node search functionality
- `/api/generate` - AI content generation endpoints
  - POST `/api/generate/node` - Single node generation
  - POST `/api/generate/batch` - Batch node generation with streaming
  - POST `/api/generate/batch/stream` - SSE streaming for batch progress
- `/api/llm/providers` - LLM provider management (CRUD)
- `/api/config/advanced` - Advanced configuration management

**Frontend API Client** (`packages/frontend/src/lib/api.ts`):
- Base: `/api` (proxied via Vite dev server or deployed path)
- HTTP client: Native `fetch()` API
- No external HTTP library; raw fetch with error handling

**CORS Configuration:**
- Allowed origins: `http://localhost:5173` (frontend dev), `http://localhost:3000` (backend)
- Credentials: Enabled
- Configuration: `packages/backend/src/index.ts` via Hono CORS middleware

## Generation Pipeline Integration

**Multi-Stage LLM Generation:**
1. **Beat Outliner** - Creates narrative beat structure
   - File: `packages/backend/src/services/generation/beat-outliner.ts`

2. **Prose Expander** - Expands beats into full prose
   - File: `packages/backend/src/services/generation/prose-expander.ts`

3. **Critic Stage** - Validates generated content quality
   - File: `packages/backend/src/services/generation/critic.ts`
   - Scored output (0-100) stored in `nodes.criticScore`

**Batch Processing:**
- File: `packages/backend/src/services/generation/batch-processor.ts`
- Supports multiple generation requests with streaming progress
- SSE streaming: `packages/backend/src/services/generation/streaming.ts`

**Prompt Building:**
- File: `packages/backend/src/services/generation/prompt-builder.ts`
- Constructs system and user prompts from node metadata

---

*Integration audit: 2026-01-25*
