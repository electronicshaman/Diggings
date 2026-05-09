# content-kit

Pure markdown extraction from `packages/atlas/` — content generation lore, templates, rules, and schemas. No code, no runtime. Hermes agent + kanban consume these as LLM context.

## Layout

```
content-kit/
  prompts/           # System prompts and style hints (LLM-ready)
  rules/             # Generation rules: biomes, distributions, lookups, defaults
  schemas/           # Data shape specs: node types, generation contracts
```

## Files

### prompts/
- `beat-outliner.md` — Stage 1 system prompt (beat structure)
- `prose-expander.md` — Stage 2 system prompt (prose generation)
- `critic.md` — Stage 3 system prompt (quality eval)
- `vernacular.md` — 1850s Australian gold rush vocabulary
- `exemplars.md` — Good vs bad prose examples
- `act-tones.md` — Per-act tonal palette

### rules/
- `biomes.md` — Biome list + per-act presence weights
- `distributions.md` — Node-type distribution per biome
- `lookup-data.md` — Per-biome enemy types, environmental contexts, hooks, etc.
- `card-handlers.md` — Card mechanic handler registry
- `defaults.md` — Default themes, entity types, difficulty curves, name prefixes
- `beat-sequences.md` — Beat sequence template format

### schemas/
- `node.md` — Node metadata + content shape (all 7 types)
- `generation.md` — Generation request/response contracts
- `eligibility.md` — Eligibility/saliency/binding rules
- `style-guide.md` — Style guide record format
- `beat-sequences.md` — Beat sequence record format

## Source provenance

Extracted from:
- `packages/atlas/packages/shared/src/constants/`
- `packages/atlas/packages/shared/src/schemas/`
- `packages/atlas/packages/backend/src/services/generation/`

Pipeline runtime (llm-client, beat-outliner, prose-expander, critic logic, batch-processor, streaming, circuit-breaker) intentionally dropped. Hermes redefines.

## Setting

1850s Australian Gold Rush cosmic horror. Four acts: Arrival → Fever → Blasphemy → Unmaking. Eight biomes: township, the_diggings, the_bush, the_mines, the_waste, the_scar, sacred_site, the_river.
