# Node Schema

Narrative graph node shape. All node types share a base; type-specific extensions add fields. Stored as discriminated union on `type`.

## Enums

- **Act**: `1 | 2 | 3 | 4` (Arrival, Fever, Blasphemy, Unmaking)
- **Biome**: `township | the_diggings | the_bush | the_mines | the_waste | the_scar | sacred_site | the_river`
- **NodeType**: `combat | choice | state_check | trade | passage | rest | transition`
- **BeatRole**: `setup | escalation | reveal | choice | consequence | button | tension | relief | foreshadow | reflection`

## Base node fields

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id                        | string                  | ✓ | non-empty |
| type                      | NodeType                | ✓ | discriminator |
| biome                     | Biome                   | ✓ | |
| name                      | string                  | ✓ | |
| acts                      | Act[]                   | ✓ | min 1 |
| actVariant                | boolean                 |   | when true, `actVariants` populated instead of `content` |
| isReplaceable             | boolean                 | ✓ | |
| replacementTags           | string[]                | ✓ | |
| themes                    | string[]                | ✓ | see `rules/biomes.md` |
| entityTypes               | string[]                | ✓ | see `rules/biomes.md` |
| eligibility               | Eligibility             |   | see `schemas/eligibility.md` |
| estimatedCombatDifficulty | 1\|2\|3\|4\|5           |   | required for combat |
| resourceCost              | ResourceCheck           |   | required for passage |
| potentialRewards          | string[]                |   | |
| content                   | NodeContent             |   | when `actVariant=false` |
| actVariants               | { [act:1..4]: NodeContent } |   | when `actVariant=true` |

### ResourceCheck

| Field | Type | Required |
|-------|------|:-------:|
| type     | string  | ✓ |
| amount   | number  | ✓ |
| optional | boolean |   |

## NodeContent (per-node prose)

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| narrative_hook | string                | ✓ | 20–500 chars; 1–3 sentences |
| beats          | StoryBeat[]           | ✓ | min 1 |
| options        | ChoiceOption[]        |   | choice nodes only |
| outcomes       | NodeOutcomes          |   | combat / state_check / passage |
| mood           | MoodDescriptor        | ✓ | |

### StoryBeat

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id            | string   | ✓ | non-empty |
| role          | BeatRole | ✓ | |
| text          | string   | ✓ | 10–500 chars (1–3 sentences) |
| playerPrompt  | string   |   | |
| outcomeTags   | string[] |   | |

### ChoiceOption

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id              | string   | ✓ | |
| label           | string   | ✓ | 3–60 chars (5–10 words) |
| description     | string   | ✓ | 10–200 chars (1 sentence) |
| consequenceTags | string[] | ✓ | |

### NodeOutcomes

```
victory?: OutcomeText
defeat?:  OutcomeText
neutral?: OutcomeText
```

### OutcomeText

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| text       | string | ✓ | 10–300 chars (1–2 sentences) |
| buttonText | string | ✓ | 1–30 chars |

### MoodDescriptor

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| tension        | 1\|2\|3\|4\|5 | ✓ | |
| atmosphere     | string        | ✓ | one word or short phrase |
| sensoryDetails | string[]      | ✓ | min 2, max 5 |

---

## Type-specific extensions

### CombatNode (`type: "combat"`)
| Field | Type | Required |
|-------|------|:-------:|
| enemyTypeHooks            | string[]              | ✓ (min 1) |
| environmentalContext      | string                | ✓ |
| estimatedCombatDifficulty | 1\|2\|3\|4\|5         | ✓ |

### ChoiceNode (`type: "choice"`)
| Field | Type | Required |
|-------|------|:-------:|
| consequenceHooks | string[]                                  | ✓ (min 1) |
| dilemmaType      | "moral" \| "practical" \| "survival"      | ✓ |

### TradeNode (`type: "trade"`)
| Field | Type | Required |
|-------|------|:-------:|
| traderArchetype | string   | ✓ |
| pricingHooks    | string[] | ✓ |

### RestNode (`type: "rest"`)
| Field | Type | Required |
|-------|------|:-------:|
| restType            | "safe" \| "risky" \| "sacred"           | ✓ |
| interruptionChance  | "none" \| "low" \| "medium" \| "high"   | ✓ |
| dreamHooks          | string[]                                |   |

### PassageNode (`type: "passage"`)
| Field | Type | Required |
|-------|------|:-------:|
| travelEventHooks          | string[]      | ✓ |
| environmentalStorytelling | string        | ✓ |
| resourceCost              | ResourceCheck | ✓ |

### StateCheckNode (`type: "state_check"`)
| Field | Type | Required |
|-------|------|:-------:|
| conditionHooks | string[]                              | ✓ |
| branchTargets  | { success: string, failure: string }  | ✓ |

### TransitionNode (`type: "transition"`)
| Field | Type | Required |
|-------|------|:-------:|
| actChangeTrigger | Act      |   |
| narrativeSummary | string   | ✓ |
| worldStateShifts | string[] | ✓ |
