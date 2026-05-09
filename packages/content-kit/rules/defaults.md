# Generation Defaults

Default values used when generation request omits fields.

## Output directory
`./nodes`

## Node name prefixes (per type)

| Node type | Prefixes |
|-----------|---------|
| combat       | Encounter, Ambush, Confrontation, Battle, Skirmish |
| choice       | Decision, Crossroads, Dilemma, Opportunity, Moment |
| trade        | Market, Trader, Exchange, Merchant, Vendor |
| rest         | Camp, Shelter, Haven, Rest, Refuge |
| passage      | Path, Route, Trail, Journey, Crossing |
| state_check  | Check, Test, Gate, Branch, Condition |
| transition   | Shift, Change, Turn, Pivot, Threshold |

## Themes — see `biomes.md`
## Entity types — see `biomes.md`
## Difficulty curves — see `lookup-data.md`
## Trader archetypes per biome — see `lookup-data.md`
## Rest types per biome — see `lookup-data.md`

## LLM defaults
- temperature: 0.7
- maxTokens: 2048
- maxRetries: 3

## Generation defaults
- batchSize: 5
- criticThreshold: 70 (0–100 scale)
- enableCriticStage: true
- defaultTemperature: 70 (0–100 scale, maps to 0.7)
