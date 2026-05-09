# Generation Contracts

Request/response shapes for the LLM generation pipeline. Three stages: Outline → Expand → Critique.

## Stage 1 — BeatOutline (Beat Outliner output)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| narrative_hook | string                                  | ✓ | 1–500 chars |
| beats          | { id, role, intent }[]                  | ✓ | role validated against beat_roles catalog |
| mood           | { tension:1..5, atmosphere, sensoryDetails:string[] } | ✓ | |

## Stage 2 — ExpandedContent (Prose Expander output)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| narrative_hook | string                                                              | ✓ | 1–500 chars |
| beats          | { id, role, text:string }[]                                         | ✓ | text 10–500 chars |
| outcomes       | { victory?, defeat?, neutral? } each `{ text, buttonText }`         |   | combat/state_check/passage |
| options        | { id, label, description }[]                                        |   | choice nodes only |

## Stage 3 — CriticResult (Critic output)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| pass               | boolean                                                                                                                        | ✓ | |
| score              | number                                                                                                                         | ✓ | 0–100 |
| issues             | { severity, category, description, beatId\|null, suggestion }[]                                                                | ✓ | severity: critical \| major \| minor; category: completeness \| length \| tone \| authenticity \| cliche \| quality |
| strengths          | string[]                                                                                                                       | ✓ | |
| repairInstructions | string \| null                                                                                                                 | ✓ | populated when pass=false |

---

## GenerationRequest (single node)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| nodeId      | string             |   | when editing existing |
| nodeType    | NodeType           | ✓ | |
| biome       | Biome              | ✓ | |
| name        | string             | ✓ | 1–255 chars |
| themes      | string[]           | ✓ | min 1 |
| entityTypes | string[]           | ✓ | min 1 |
| acts        | Act[]              | ✓ | min 1 |
| actVariant  | boolean            |   | default false |
| estimatedCombatDifficulty | 1..5 |   | combat only |

Type-specific (validated against `nodeType`):
- combat: `enemyTypeHooks`, `environmentalContext`
- choice: `consequenceHooks`, `dilemmaType`
- trade: `traderArchetype`, `pricingHooks`
- rest: `restType`, `interruptionChance`, `dreamHooks`
- passage: `travelEventHooks`, `environmentalStorytelling`
- state_check: `conditionHooks`
- transition: `actChangeTrigger`, `narrativeSummary`, `worldStateShifts`

## BulkGenerationRequest

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| biome    | Biome    |   | filter scope |
| nodeType | NodeType |   | filter scope |
| count    | 1..100   |   | hard cap on total nodes |
| fillGaps | boolean  |   | default true; analyze distributions and fill gaps |

## ProgressEvent (SSE)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| stage    | "outlining" \| "expanding" \| "reviewing" \| "completed" \| "error" | ✓ | |
| progress | number                                                              | ✓ | 0–100 |
| message  | string                                                              |   | |
| data     | any                                                                 |   | stage-specific payload |
| error    | string                                                              |   | |

## GenerationResponse (single)

| Field | Type | Required |
|-------|------|:-------:|
| success      | boolean         | ✓ |
| nodeId       | string          |   |
| content      | ExpandedContent |   |
| criticScore  | 0..100          |   |
| criticResult | CriticResult    |   |
| error        | string          |   |

## BatchGenerationResponse

| Field | Type | Required |
|-------|------|:-------:|
| jobId          | string                                                | ✓ |
| totalNodes     | number                                                | ✓ |
| status         | "pending" \| "running" \| "completed" \| "failed"     | ✓ |
| progress       | 0..100                                                | ✓ |
| completedNodes | string[]                                              | ✓ |
| failedNodes    | string[]                                              | ✓ |
| message        | string                                                |   |

---

## Card generation contracts

### CardGenerationRequest

| Field | Type | Required |
|-------|------|:-------:|
| cardType          | enum (CARD_TYPES)         | ✓ |
| rarity            | enum (CARD_RARITIES)      | ✓ |
| cardOwner         | enum (CARD_OWNERS)        | ✓ |
| handling          | enum (CARD_HANDLING)      | ✓ |
| accessibilityTier | enum (ACCESSIBILITY_TIERS)| ✓ |
| classAffinity     | string[]                  |   |
| themeHint         | string                    |   |

### BulkCardGenerationRequest

| Field | Type | Required |
|-------|------|:-------:|
| targetTotal | 1..200             | ✓ |
| cardOwner   | enum (CARD_OWNERS) |   |
