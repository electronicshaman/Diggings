# Eligibility Schema

Compact reference. Full rules with examples in `rules/eligibility.md`.

## Eligibility

| Field | Type | Required |
|-------|------|:-------:|
| when     | BoolExpr        | ✓ |
| saliency | Saliency        |   |
| repeat   | RepeatPolicy    |   |
| bindings | BindingSpec[]   |   |

## BoolExpr (recursive union)

```
{ allOf: BoolExpr[] }
{ anyOf: BoolExpr[] }
{ noneOf: BoolExpr[] }
| Condition
```

## Comparator

`==` `!=` `>` `>=` `<` `<=` `in` `not_in` `contains` `not_contains`

## Condition (discriminated by `kind`)

| kind | Fields |
|------|--------|
| flag         | `key:string`, `op: == \| !=`, `value: boolean` |
| resource     | `key:string`, `op:Comparator`, `value: number \| [number,number]` |
| tag          | `scope: player\|run\|biome\|world\|deck\|node_context`, `op: contains\|not_contains`, `value:string` |
| biome        | `op: in\|not_in\|==`, `value: string \| string[]` |
| act          | `op: in\|not_in\|==\|>=\|<=`, `value: number \| number[]` |
| difficulty   | `op: <=\|>=`, `value:number` |
| cooldown     | `key:string`, `op: >=\|<=`, `value:number` |
| seen         | `key:string`, `op: ==\|!=\|>=\|<=`, `value:number` |
| bind_exists  | `role:string`, `requiredTags?:string[]`, `count?: { op:>=\|==\|<=, value:number }` |

## RepeatPolicy

```
{ mode: "once" }
| { mode: "repeatable", minStepsBetween?:number, maxTimesPerRun?:number }
```

## Saliency

| Field | Type |
|-------|------|
| qualityRules | `{ if: BoolExpr, add:number, reason?:string }[]` |
| cooldownBias | `{ key:string, minSteps?:number, weight:number }[]` |

## BindingSpec

| Field | Type | Required |
|-------|------|:-------:|
| role          | string                          | ✓ |
| requiredTags  | string[]                        |   |
| optionalTags  | string[]                        |   |
| maxCandidates | number                          |   |
| prefer        | `{ tag:string, weight:number }[]` |   |
