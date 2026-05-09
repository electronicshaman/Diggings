# Eligibility Rules

Hard gates and saliency rules that determine when a beat/node is eligible to fire. Inspired by storylet systems (parametrised beats, repeatability, saliency scoring).

## Top-level shape

```yaml
eligibility:
  when: <BoolExpr>          # hard gate; if false, ineligible
  saliency:                 # optional specificity signals for selection
    qualityRules: [...]
    cooldownBias: [...]
  repeat:                   # repetition policy
    mode: once | repeatable
    minStepsBetween: 5
    maxTimesPerRun: 2
  bindings: [...]           # entity/location binding specs
```

## BoolExpr (recursive)

Either a logical combinator or a leaf condition.

```yaml
{ allOf:  [ <BoolExpr>, ... ] }
{ anyOf:  [ <BoolExpr>, ... ] }
{ noneOf: [ <BoolExpr>, ... ] }
<Condition>                  # leaf
```

## Conditions

Discriminated by `kind`.

### flag
```yaml
kind: flag
key: "met_publican"
op: "==" | "!="
value: true
```

### resource
```yaml
kind: resource
key: "health" | "sanity" | "gold" | "food" | "ammo" | <custom>
op: "==" | "!=" | ">" | ">=" | "<" | "<=" | "in" | "not_in" | "contains" | "not_contains"
value: <number> | [<min>, <max>]   # tuple for `in` ranges
```

### tag
```yaml
kind: tag
scope: "player" | "run" | "biome" | "world" | "deck" | "node_context"
op: "contains" | "not_contains"
value: "tainted"
```

### biome
```yaml
kind: biome
op: "in" | "not_in" | "=="
value: "the_mines" | ["the_mines", "the_scar"]
```

### act
```yaml
kind: act
op: "in" | "not_in" | "==" | ">=" | "<="
value: 3 | [2, 3, 4]
```

### difficulty
```yaml
kind: difficulty
op: "<=" | ">="
value: 3
```

### cooldown
```yaml
kind: cooldown
key: "void_whisper"
op: ">=" | "<="
value: 5         # steps since last occurrence
```

### seen
```yaml
kind: seen
key: <node_id | beat_id | group_id>
op: "==" | "!=" | ">=" | "<="
value: 0
```

### bind_exists
Used when storylet needs a parametrised entity to attach to. Fails if no candidate matches.

```yaml
kind: bind_exists
role: "npc" | "enemy" | "landmark"
requiredTags: ["rival"]
count: { op: ">=", value: 1 }
```

## Saliency

Quality rules add to a saliency score; cooldown bias subtracts when overused.

```yaml
saliency:
  qualityRules:
    - if: <BoolExpr>
      add: 5
      reason: "rare combo"
  cooldownBias:
    - key: "combat"
      minSteps: 3
      weight: -2
```

More-specific conditions usually score higher (storylet best practice — pick the most specific match).

## RepeatPolicy

```yaml
# Single-fire
repeat: { mode: once }

# Repeatable with throttling
repeat:
  mode: repeatable
  minStepsBetween: 5
  maxTimesPerRun: 3
```

## BindingSpec

Pulls a runtime entity into the beat. Use for "the rival you wronged shows up here" or "a landmark from earlier returns".

```yaml
bindings:
  - role: "npc.rival"
    requiredTags: ["wronged_by_player"]
    optionalTags: ["recently_seen"]
    maxCandidates: 3
    prefer:
      - { tag: "owes_debt", weight: 2 }
      - { tag: "armed",     weight: 1 }
```
