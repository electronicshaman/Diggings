# Content Tooling Plan (Atlas → Forge)

This plan captures the phases for extracting a shared authoring core and building Forge without duplicating Atlas.

---

## Phase 0 — Scope & Goals ✅
**Outcome:** clear Forge MVP requirements.

- Forge MVP = CRUD Cards + Curios
- Bulk skeleton generation (no LLM required)
- JSON export to `/exports`
- Reuse HandlerRegistry effect IDs
- Distribution matrix required

**Docs:**
- `forge-scope.md`
- `forge-schema-mvp.md`
- `forge-distribution-matrix.md`
- `forge-id-scheme.md`
- `forge-export.md`

---

## Phase 1 — Forge Domain Definition ✅
**Outcome:** core schemas + constants.

- Forge types + Zod schemas (cards, curios, effects)
- Forge constants (types, rarity, handling)
- Distribution matrix constants
- ID utilities

**Location:** `packages/authoring-core/shared/`

---

## Phase 2 — Authoring Core Extraction (in progress)
**Outcome:** Atlas consumes shared core UI + hooks; Forge can reuse same primitives.

### Phase 2a — Extract shared UI ✅
- GenerationProgress
- QualityFeedback
- DistributionGapMatrix
- BulkGeneratePanel

### Phase 2b — Extract shared hooks ✅
- useBulkGeneration (authoring-core/frontend)

### Phase 2c — Remaining shared primitives (next)
- useGeneration (streaming) if Forge needs it
- useConfig/useNodes (if generic enough)
- Possibly shared API client utilities

---

## Phase 3 — Forge App Scaffold
**Outcome:** Forge runs as its own package using authoring-core.

- `packages/forge` created
- Routing + UI skeleton
- CRUD for cards + curios
- Reuse BulkGeneratePanel + hooks

---

## Phase 4 — Skeleton Generation (Forge)
**Outcome:** fast minimal-input content.

- `POST /api/forge/generate/bulk`
- Gap-fill generation based on distribution matrix
- Deterministic IDs
- Schema-valid placeholders

---

## Phase 5 — Pipeline Integration
**Outcome:** JSON export usable by game import.

- Export contract finalized
- Export bundle to `/exports`
- Godot importer (later)

---

## Phase 6 — Quality & UX polish
**Outcome:** authoring experience improvements.

- Bulk edit tools
- Status fields (`draft | outlined | final`)
- Graph visualization
- Search improvements
