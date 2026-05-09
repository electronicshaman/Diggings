# Atlas Archive

Historical record of the `packages/atlas/` content-tooling effort. The atlas package itself remains in-tree pending final removal once `packages/content-kit/` is integrated with the hermes agent + kanban content pipeline.

## Contents

- `content-tooling/` — original atlas implementation/AI plans, forge specs, authoring-core notes
- `atlas-planning/` — atlas's `.planning/` (PROJECT, ROADMAP, REQUIREMENTS, STATE, phases, research, codebase intel)
- `atlas-CLAUDE.md` — atlas's CLAUDE.md describing dev commands, monorepo layout, schema conventions

## Replacement

Pure-markdown extraction of atlas content generation knowledge → `packages/content-kit/`:
- prompts/ (beat-outliner, prose-expander, critic, vernacular, exemplars, act-tones)
- rules/ (biomes, distributions, lookup-data, card-handlers, defaults, beat-sequences, eligibility)
- schemas/ (node, generation, eligibility, style-guide, beat-sequences)

Pipeline runtime (Drizzle, Hono routes, frontend, llm-client, beat-outliner.ts, prose-expander.ts, critic.ts, batch-processor, streaming, circuit-breaker) intentionally not extracted — hermes redefines.

## Game-facing lore

Stays at top-level — not archived:
- `docs/game/` (biomes, cards, classes, character-generation, curios, status-effects, etc.)
- `docs/pipeline/narrative-graph-spec.md` + `narrative-node-types.md`
- `docs/architecture/character-card-relationships.md` + `system-architecture.md` + `event-bus-reference.md`
