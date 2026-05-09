# Plan: Integrate AI Content Generation and Configuration Management

## User Requirements

### AI Content Generation
- **Dual Mode**: Support both full node generation and assisted/partial content generation
- **Multiple LLM Providers**: Configurable support for OpenAI, Anthropic Claude, and potentially others
- **Real-time with Streaming**: User sees content being generated live (for single nodes)
- **Minimal Input**: Generate complete nodes from just type, biome, and basic metadata

### Bulk Generation
- **Distribution-Based**: Auto-generate nodes to meet configured biome/node-type distribution targets
- **Gap Filling**: Identify missing nodes and generate them automatically

### Configuration Management
- **Biome Definitions**: Make themes, entity types, and act presence fully editable in UI
- **Hook/Lookup Data**: Convert seeded constants to user-editable configuration (enemy types, environmental contexts, consequence hooks, etc.)
- **Beat Roles**: Allow customization of story beat types and validation rules
- **Defaults & Distributions**: Make default values and target distributions configurable

### API Key Management
- **Dual Storage**: Support both environment variables (production) and database storage (personal deployments)
- **Encryption**: Keys stored in DB must be encrypted at rest

## CLI Analysis Complete

Analyzed the graph-grammar-generator CLI at `/Users/rob/Projects/graph-grammar-generator`.

**Key Findings:**
- **3-Stage Pipeline**: Beat Outlining → Prose Expansion → Critic Review
- **OpenRouter Integration**: Claude Sonnet 4 via OpenRouter API
- **Batch Processing**: Concurrent generation with progress tracking
- **Configuration-Driven**: Beat sequences, style guides, distributions all data-driven
- **Quality Gates**: Critic scores content 0-100, requires 70+ to pass

**Portable Components:**
- Beat template system (~300 lines)
- Style guide architecture (~300 lines)
- LLM client with retry logic (~120 lines)
- Distribution matrix and defaults (~800 lines)
- Batch processing with progress callbacks

## Planned Architecture

### Backend Changes

#### New Database Tables

**LLM Configuration:**
```sql
llm_providers (
  id, name, type (openai|openrouter|anthropic),
  base_url, encrypted_api_key, model,
  temperature, max_retries, is_active, created_at
)

generation_settings (
  id, batch_size, critic_threshold,
  enable_critic_stage, default_temperature
)
```

**Editable Configuration (migrate from constants):**
```sql
beat_roles (
  id, key (setup|escalation|...),
  display_name, description,
  is_core (bool), sort_order
)

beat_sequences (
  id, node_type, sequence_key,
  beat_structure (jsonb), weight,
  act_constraints (jsonb),
  required_tags (jsonb)
)

style_guide (
  id, biome, atmosphere,
  sensory_details (jsonb), dangers (jsonb),
  voice_notes (text), antipatterns (jsonb)
)

vernacular (
  id, term, definition, era,
  usage_notes
)

act_tones (
  id, act, tone_name,
  description, sensory_palette (jsonb)
)
```

**Expand existing tables:**
- `biomes`: Add `atmosphere`, `voice_notes`, make all fields editable
- All lookup tables: Add UI-editable flag, sort_order
- `distributions`: Add validation rules, min/max counts

#### New Backend Packages/Services

**Generation Service** (`packages/backend/src/services/generation/`):
```
generation/
├── llm-client.ts          # Port from CLI, multi-provider support
├── beat-outliner.ts       # Stage 1: Structure generation
├── prose-expander.ts      # Stage 2: Full prose from outline
├── critic.ts              # Stage 3: Quality scoring
├── prompt-builder.ts      # Compositional prompt construction
├── batch-processor.ts     # Concurrent batch processing
└── streaming.ts           # SSE streaming for real-time updates
```

**Configuration Service** (`packages/backend/src/services/config/`):
```
config/
├── beat-template-manager.ts
├── style-guide-manager.ts
├── distribution-analyzer.ts  # Find gaps vs target distributions
└── default-loader.ts         # Migrate CLI defaults to DB
```

#### New API Routes

**Generation:**
- `POST /api/generate/node` - Single node with SSE streaming
- `POST /api/generate/bulk` - Batch generation to meet distributions
- `GET /api/generate/status/:jobId` - Poll bulk job status
- `POST /api/generate/validate` - Critic-only validation

**LLM Providers:**
- `GET /api/llm/providers` - List configured providers
- `POST /api/llm/providers` - Add provider with encrypted key
- `PUT /api/llm/providers/:id` - Update provider
- `DELETE /api/llm/providers/:id` - Remove provider
- `POST /api/llm/test` - Test provider connection

**Expanded Config:**
- `GET/PUT /api/config/beat-roles` - CRUD beat role definitions
- `GET/PUT /api/config/beat-sequences` - Manage beat templates
- `GET/PUT /api/config/style-guide` - Per-biome style rules
- `GET/PUT /api/config/vernacular` - Historical term glossary
- `GET/PUT /api/config/act-tones` - Act-specific tone guidance
- `GET /api/config/distributions/gaps` - Analyze missing nodes

### Frontend Changes

#### New Pages

**`/settings`** - LLM & Generation Settings
- Provider management (add OpenRouter, OpenAI, Anthropic)
- API key configuration (encrypted storage warning)
- Test connection button
- Generation defaults (batch size, critic threshold, temperature)
- Environment variable override display (read-only)

**`/generate`** - AI Generation Hub
- **Quick Generate Tab**: Minimal input (type, biome, theme) → full node
- **Assisted Create Tab**: Hybrid manual/AI form with field-level assist
- **Bulk Generate Tab**: Distribution gap analysis, batch job launcher
- Real-time streaming display with beat-by-beat updates

**`/config/advanced`** - Configuration Management
- Beat Roles: Add/edit/reorder beat types
- Beat Sequences: Template editor with JSON view
- Style Guide: Per-biome atmosphere, voice notes, antipatterns
- Vernacular: Historical term glossary
- Act Tones: Tone/sensory guidance per act
- Import/Export: Backup/restore all config as JSON

#### Enhanced Node Creation (`/nodes/create`)

**Mode Selection (Step 0):**
- "Generate with AI" → Minimal form → streaming generation
- "Create Manually" → Current wizard with AI assist buttons

**AI Assist Features:**
- "Generate Hook" button on narrative_hook field
- "Suggest Beats" on beats section
- "AI Enhance" on mood descriptor
- Inline streaming display (doesn't navigate away)

#### New Components

**`GenerationProgress.tsx`**
- Multi-stage progress (Outlining 33% → Expanding 66% → Reviewing 100%)
- Real-time beat display as they're generated
- Retry/Cancel/Accept controls
- Critic score display with breakdown

**`DistributionGapChart.tsx`**
- Visual matrix of target vs actual node counts
- Highlight gaps in red, excesses in yellow
- Click gap → pre-fill bulk generation form

**`BeatSequenceEditor.tsx`**
- Visual beat structure builder
- Drag-drop beat ordering
- Act/tag constraint UI
- Weight slider for probabilistic selection

**`StyleGuideEditor.tsx`**
- Per-biome atmosphere input
- Sensory details tag input
- Dangers/threats list
- Voice notes textarea
- Antipatterns list (phrases to avoid)

### Shared Package Changes

**New Schemas** (`packages/shared/src/schemas/`):

```typescript
// generation.ts
GenerationRequestSchema
GenerationResponseSchema
CriticScoreSchema
ProgressEventSchema

// llm.ts
LLMProviderSchema (type, baseUrl, model, temperature, maxRetries)
LLMProviderConfigSchema (includes encrypted key)

// beat-sequences.ts
BeatSequenceSchema (nodeType, key, structure, weight, constraints)

// style-guide.ts
StyleGuideSchema (biome, atmosphere, sensory, dangers, voiceNotes, antipatterns)
```

**Schema Modifications:**

- `BeatRoleSchema`: Change from enum to dynamic (validate against DB)
- `NodeContentSchema`: Add optional `critic_score` field
- `BiomeSchema`: Expand with style guide fields
- Add `ActToneSchema` for act-specific guidance

**New Constants** (`packages/shared/src/constants/`):

```typescript
// defaults.ts - Port from CLI
DEFAULT_LLM_SETTINGS
DEFAULT_GENERATION_SETTINGS
DEFAULT_CRITIC_THRESHOLD

// prompts.ts - System prompts
BEAT_OUTLINER_SYSTEM_PROMPT
PROSE_EXPANDER_SYSTEM_PROMPT
CRITIC_SYSTEM_PROMPT
```

## Implementation Phases

### Phase 1: Database & Configuration Foundation
**Goal:** Migrate CLI constants to editable database configuration

**Tasks:**
1. Create new database tables (llm_providers, generation_settings, beat_roles, beat_sequences, style_guide, vernacular, act_tones)
2. Write Drizzle schema definitions
3. Generate and run migrations
4. Create seed script to populate from CLI defaults (`/Users/rob/Projects/graph-grammar-generator/src/config/`)
5. Expand existing biomes/distributions tables with new fields

**Files to modify:**
- `packages/backend/src/db/schema.ts` (add ~200 lines)
- `packages/backend/src/db/seed.ts` (expand to load all config)
- `packages/backend/drizzle/` (new migrations)

**Files to create:**
- `packages/backend/src/db/migrations/seed-data/` (JSON exports from CLI config)

### Phase 2: Backend Generation Service
**Goal:** Port 3-stage generation pipeline from CLI

**Tasks:**
1. Create `packages/backend/src/services/generation/` directory
2. Port LLM client with multi-provider support
3. Implement beat-outliner (Stage 1)
4. Implement prose-expander (Stage 2)
5. Implement critic (Stage 3)
6. Create prompt-builder for compositional prompts
7. Implement batch-processor with progress callbacks
8. Add SSE streaming support

**Files to create:**
- `packages/backend/src/services/generation/llm-client.ts` (~150 lines, port from CLI)
- `packages/backend/src/services/generation/beat-outliner.ts` (~200 lines)
- `packages/backend/src/services/generation/prose-expander.ts` (~200 lines)
- `packages/backend/src/services/generation/critic.ts` (~150 lines)
- `packages/backend/src/services/generation/prompt-builder.ts` (~300 lines)
- `packages/backend/src/services/generation/batch-processor.ts` (~200 lines)
- `packages/backend/src/services/generation/streaming.ts` (~100 lines)

**Dependencies to add:**
- `openai` (SDK for OpenAI/OpenRouter)
- `eventsource-parser` (for SSE)
- Encryption library for API keys (e.g., `@node-rs/bcrypt` or `crypto`)

### Phase 3: Backend API Routes
**Goal:** Expose generation and config management endpoints

**Tasks:**
1. Create generation routes (single, bulk, validate)
2. Create LLM provider routes (CRUD + test)
3. Expand config routes for new tables
4. Add distribution gap analysis endpoint
5. Implement API key encryption/decryption middleware

**Files to create:**
- `packages/backend/src/routes/generate.ts` (~250 lines)
- `packages/backend/src/routes/llm-providers.ts` (~150 lines)
- `packages/backend/src/routes/config-advanced.ts` (~200 lines)
- `packages/backend/src/middleware/encryption.ts` (~50 lines)

**Files to modify:**
- `packages/backend/src/index.ts` (add routes)
- `packages/backend/src/routes/config.ts` (expand existing)

### Phase 4: Shared Package Schemas
**Goal:** Add validation schemas for generation and config

**Tasks:**
1. Create generation schemas (request, response, progress)
2. Create LLM provider schemas
3. Create beat sequence, style guide schemas
4. Port system prompts from CLI
5. Make BeatRoleSchema dynamic

**Files to create:**
- `packages/shared/src/schemas/generation.ts` (~150 lines)
- `packages/shared/src/schemas/llm.ts` (~100 lines)
- `packages/shared/src/schemas/beat-sequences.ts` (~100 lines)
- `packages/shared/src/schemas/style-guide.ts` (~100 lines)
- `packages/shared/src/constants/prompts.ts` (~400 lines, port from CLI)

**Files to modify:**
- `packages/shared/src/schemas/node.ts` (make BeatRoleSchema dynamic)

### Phase 5: Frontend - Settings & Config Pages
**Goal:** UI for managing providers and configuration

**Tasks:**
1. Create `/settings` page for LLM providers
2. Create `/config/advanced` page for configuration management
3. Build LLM provider CRUD UI
4. Build style guide editor
5. Build beat sequence editor
6. Build vernacular glossary editor

**Files to create:**
- `packages/frontend/src/routes/settings.tsx` (~200 lines)
- `packages/frontend/src/routes/config/advanced.tsx` (~300 lines)
- `packages/frontend/src/components/settings/ProviderForm.tsx` (~150 lines)
- `packages/frontend/src/components/config/StyleGuideEditor.tsx` (~200 lines)
- `packages/frontend/src/components/config/BeatSequenceEditor.tsx` (~250 lines)
- `packages/frontend/src/components/config/VernacularEditor.tsx` (~150 lines)
- `packages/frontend/src/hooks/useLLMProviders.ts` (~100 lines)
- `packages/frontend/src/hooks/useAdvancedConfig.ts` (~150 lines)

### Phase 6: Frontend - AI Generation UI
**Goal:** Real-time streaming generation interface

**Tasks:**
1. Create `/generate` page with tabs (Quick, Assisted, Bulk)
2. Build GenerationProgress component with SSE
3. Build DistributionGapChart
4. Add "Generate with AI" to node creation flow
5. Add field-level AI assist buttons to forms
6. Implement streaming display

**Files to create:**
- `packages/frontend/src/routes/generate/index.tsx` (~300 lines)
- `packages/frontend/src/components/generation/GenerationProgress.tsx` (~200 lines)
- `packages/frontend/src/components/generation/QuickGenerate.tsx` (~150 lines)
- `packages/frontend/src/components/generation/AssistedCreate.tsx` (~200 lines)
- `packages/frontend/src/components/generation/BulkGenerate.tsx` (~250 lines)
- `packages/frontend/src/components/generation/DistributionGapChart.tsx` (~150 lines)
- `packages/frontend/src/hooks/useGeneration.ts` (~200 lines, SSE streaming)
- `packages/frontend/src/lib/streaming.ts` (~100 lines, SSE client)

**Files to modify:**
- `packages/frontend/src/routes/nodes/create.tsx` (add AI mode option)
- `packages/frontend/src/components/forms/BaseNodeForm.tsx` (add assist buttons)

### Phase 7: Testing & Polish
**Goal:** Ensure reliability and UX quality

**Tasks:**
1. Test LLM provider connections
2. Test full generation pipeline (all 7 node types)
3. Test bulk generation with progress tracking
4. Test critic quality gates
5. Test configuration import/export
6. Add loading states and error boundaries
7. Add toast notifications for generation events
8. Documentation updates (CLAUDE.md)

## Critical Files to Modify

**Backend:**
- `packages/backend/src/db/schema.ts` - Add 8 new tables
- `packages/backend/src/index.ts` - Wire up new routes
- `packages/backend/package.json` - Add openai, encryption deps

**Frontend:**
- `packages/frontend/src/App.tsx` - Add /settings, /generate, /config/advanced routes
- `packages/frontend/src/components/layout/Sidebar.tsx` - Add nav links
- `packages/frontend/package.json` - Add eventsource-parser if needed

**Shared:**
- `packages/shared/src/schemas/node.ts` - Make BeatRoleSchema dynamic
- `packages/shared/package.json` - No new deps needed

## Migration Strategy for Constants

**From CLI to Database:**
1. Export CLI config as JSON:
   - `/config/biome-distributions.ts` → `seed-data/distributions.json`
   - `/config/defaults.ts` → `seed-data/defaults.json`
   - `/config/beat-sequences.ts` → `seed-data/beat-sequences.json`
   - `/config/style-guide.ts` → `seed-data/style-guide.json`

2. Seed script loads JSON into DB tables

3. Backend config service reads from DB, caches in memory

4. Zod schemas validate against DB values (not hardcoded enums)

**Backward Compatibility:**
- Keep `packages/shared/src/constants/` for default values
- DB values override constants if present
- Allows gradual migration

## Verification & Testing

### End-to-End Test Scenarios

**1. LLM Provider Setup:**
- Add OpenRouter provider with API key
- Test connection
- Set as active provider
- Verify encrypted key storage

**2. Single Node Generation:**
- Navigate to `/generate`
- Select "Quick Generate"
- Choose: type=combat, biome=township, theme=greed
- Watch streaming progress (outlining → expanding → reviewing)
- Verify critic score >70
- Accept and save node
- Verify node appears in `/nodes` list

**3. Bulk Generation:**
- Navigate to `/generate` → Bulk tab
- View distribution gap chart
- Click "Generate Missing Nodes" for The Mines
- Monitor batch progress (5 nodes at a time)
- Wait for completion
- Verify all nodes created in DB
- Check distributions now match targets

**4. Configuration Management:**
- Navigate to `/config/advanced`
- Edit Township style guide (change atmosphere)
- Add new beat role "climax"
- Update beat sequence for combat
- Save changes
- Generate new node and verify new config is used

**5. Field-Level Assist:**
- Navigate to `/nodes/create`
- Choose "Create Manually"
- Fill metadata
- Click "Generate Hook" on narrative_hook field
- Verify hook generated and populated
- Continue with manual beat creation
- Save node

### Success Criteria

- All 7 node types can be generated via AI
- Streaming progress updates work smoothly
- Critic rejects poor quality (score <70) and retries
- Bulk generation handles 20+ nodes without errors
- Configuration changes immediately affect generation
- API keys are encrypted in DB
- Environment variables override DB settings
- No hardcoded constants remain (all in DB or config)

## Dependencies to Add

**Backend:**
```json
{
  "openai": "^4.20.0",
  "@node-rs/bcrypt": "^1.9.0"
}
```

**Frontend:**
```json
{
  "eventsource-parser": "^1.1.1"
}
```

## Estimated Scope

**New Files:** ~35 files
**Modified Files:** ~12 files
**New Database Tables:** 8 tables
**Total Lines of Code:** ~5,000-6,000 lines (including migrations, schemas, components)

**Breakdown:**
- Backend generation service: ~1,500 lines
- Backend routes: ~600 lines
- Database schema/migrations: ~400 lines
- Shared schemas: ~800 lines
- Frontend components: ~2,000 lines
- Frontend hooks/utilities: ~500 lines
- Configuration seed data: ~200 lines JSON
