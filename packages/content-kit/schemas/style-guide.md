# Style Guide Schema

Per-biome generation guidance. One record per biome; injected into prompts.

## StyleGuideRecord

| Field | Type | Required | Notes |
|-------|------|:-------:|------|
| id              | int     | ✓ | |
| biome           | Biome   | ✓ | one of 8 |
| atmosphere      | string  |   | one phrase, e.g. "muddy desperation" |
| sensoryDetails  | string[]| ✓ | site-specific sights/sounds/smells |
| dangers         | string[]| ✓ | concrete threats characteristic of this biome |
| voiceNotes      | string  |   | how prose should *sound* |
| antipatterns    | string[]| ✓ | tropes/phrasings to avoid |
| createdAt       | date    | ✓ | |
| updatedAt       | date    | ✓ | |

## VernacularRecord

Per-term gold rush vocabulary. See `prompts/vernacular.md` for canonical list.

| Field | Type | Required |
|-------|------|:-------:|
| id         | int    | ✓ |
| term       | string | ✓ |
| definition | string | ✓ |
| era        | string |   |
| usageNotes | string |   |
| sortOrder  | int    | ✓ |

## ActToneRecord

Per-act narrative tone guidance. See `prompts/act-tones.md`.

| Field | Type | Required |
|-------|------|:-------:|
| id              | int    | ✓ |
| act             | 1..4   | ✓ |
| toneName        | string | ✓ |
| description     | string |   |
| sensoryPalette  | any    | ✓ | freeform JSON; typically string[] |

## Prompt-injection format

Style guide → typically rendered as:
```
Biome ({biome}): {atmosphere}
Sensory: {sensoryDetails[0..3].join(", ")}
Voice: {voiceNotes}
```

Anti-patterns → critic prompt:
```
Avoid: {antipatterns[0..6].join(", ")}
```

Act tone:
```
Act {act} ({toneName}):
- Tone: {description}
- Sensory Palette: {sensoryPalette.join(", ")}
```
