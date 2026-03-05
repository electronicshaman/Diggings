# Character Generation System

Last verified: 2026-01-13

## Overview

The character generation system creates procedurally-generated characters with coherent backstories that influence gameplay mechanics and narrative outcomes. Each character is defined by a **backstory chain** of four elements that together determine starting stats, curios, objectives, and—critically—**narrative tags** that drive graph rewriting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CharacterGenerator (Autoload)                   │
│         Orchestrates generation using SeedManager for RNG           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
           ┌──────────────┐ ┌────────────┐ ┌──────────────────┐
           │ BackstoryPools│ │ NamePools  │ │ GenerationRules  │
           │ (.tres files) │ │ (.json)    │ │ (.json)          │
           └──────────────┘ └────────────┘ └──────────────────┘
                    │
                    ▼
           ┌──────────────────────────────────────────────────────────┐
           │                  GeneratedCharacter                       │
           │    Resource containing complete character data            │
           └──────────────────────────────────────────────────────────┘
```

## Backstory Chain

Characters are built from four **BackstoryElement** resources, selected in order:

| Order | Element      | Purpose                                        | Selection Logic                    |
|-------|--------------|------------------------------------------------|------------------------------------|
| 1     | **Origin**   | Who they were before the goldfields            | Class-weighted random              |
| 2     | **Tragedy**  | What drove them from their old life            | Compatible with origin             |
| 3     | **Motivation**| What they're seeking now                      | Compatible with origin + tragedy   |
| 4     | **Quirk**    | Personality trait (70% chance)                 | Compatible with chain, optional    |

### Compatibility Rules

Each `BackstoryElement` defines:
- `compatible_next_elements: Array[String]` — IDs of elements that can follow
- `incompatible_elements: Array[String]` — IDs that cannot coexist
- `required_elements: Array[String]` — IDs that must exist in chain

Example chain:
```
aboriginal_guide → tribe_massacred → honor_ancestors → spiritual
       ↓                ↓                  ↓                ↓
    Origin          Tragedy          Motivation          Quirk
```

## File Structure

```
data/character_generation/
├── backstory_element.gd              # Resource script (shared)
├── backstory_resources/
│   ├── origins/                      # 4 origins implemented
│   │   ├── aboriginal_guide.tres
│   │   ├── failed_banker.tres
│   │   ├── inherited_pub.tres
│   │   └── wrongly_accused.tres
│   ├── tragedies/
│   │   ├── family_held_hostage.tres
│   │   ├── framed_for_murder.tres
│   │   ├── pub_cursed.tres
│   │   └── tribe_massacred.tres
│   ├── motivations/
│   │   ├── break_family_curse.tres
│   │   ├── honor_ancestors.tres
│   │   ├── one_big_score.tres
│   │   └── prove_innocence.tres
│   └── quirks/
│       ├── collects_newspapers.tres
│       ├── compulsive_gambler.tres
│       ├── lucky_charm_obsession.tres
│       └── talks_to_animals.tres
├── data_pools/
│   ├── generation_rules.json         # Class → element weights
│   ├── names.json                    # Cultural name pools
│   └── nicknames.json
└── starting_curios/                  # Class-specific starting curios
```

## BackstoryElement Resource

Each `.tres` file extends `BackstoryElement` ([backstory_element.gd](../../src/data/character_generation/backstory_element.gd)):

```gdscript
@export var element_id: StringName = &""         # Unique ID (e.g., "wrongly_accused")
@export var element_type: String = "origin"      # origin|tragedy|motivation|quirk
@export var display_name: String = ""            # UI display name
@export var description: String = ""             # Short narrative description
@export var flavor_text: String = ""             # Extended prose

# Selection weights
@export var weight: float = 10.0                 # Base selection weight
@export var class_compatibility: Dictionary = {} # Class → multiplier (0.5-2.0)

# Chain compatibility
@export var compatible_next_elements: Array[String] = []
@export var incompatible_elements: Array[String] = []
@export var required_elements: Array[String] = []

# Optional objective
@export var adds_objective: bool = false
@export var objective_type: String = ""
@export var objective_value: int = 0
@export var objective_reward: String = ""
```

### Modifiers (Proposed Refactor)

The current `stat_modifiers`, `percentage_modifiers`, and `special_modifiers` dictionaries reference mechanics that don't exist. Replace with:

```gdscript
@export_group("Starting Stats")
@export var health_adjustment: int = 0           # Applied to base_health at generation
@export var sanity_adjustment: int = 0           # Applied to base_sanity at generation  
@export var gold_adjustment: int = 0             # Applied to starting_gold at generation
@export var corruption_adjustment: int = 0       # Applied to starting_corruption

@export_group("Run Modifiers")
@export var starting_statuses: Array[StatusEffectData] = []  # Applied at combat start
@export var starting_status_stacks: Dictionary = {}          # effect_id → stack count
```

**Available Status Effects** (from `data/status_effects/`):

| Buffs | Debuffs |
|-------|--------|
| clarity, drain, focus, grit, guard, recovery, resolve, surge | burn, confusion, curse, disarmed, dread, poison, rattled, thorns, weak, wounded |

**Example**: A "tribe_massacred" tragedy might grant:
- `sanity_adjustment = -10`
- `starting_statuses = [resolve.tres]` with 2 stacks (survivor's determination)

## Generation Flow

The `CharacterGenerator` autoload ([character_generator.gd](../../src/scripts/autoloads/character_generator.gd)) orchestrates:

```gdscript
CharacterGenerator.generate_character(class_name: String) -> GeneratedCharacter:
    1. Select origin (class-weighted)
    2. Filter tragedies by compatibility → select weighted
    3. Filter motivations by compatibility → select weighted
    4. 70% chance: filter quirks → select weighted
    5. Generate name from cultural pools
    6. Apply stat modifiers from chain
    7. Select starting curio (class + origin weighted)
    8. Generate backstory summary prose
    9. Check for special objectives
    10. Return GeneratedCharacter resource
```

## Class-Specific Pools

The `generation_rules.json` defines class-specific element pools:

| Class      | Favored Origins                           | Favored Motivations        |
|------------|-------------------------------------------|----------------------------|
| Bushranger | wrongly_accused, irish_rebel, ex_trooper  | clear_name, revenge        |
| Prospector | failed_banker, indebted_farmer, widow     | one_big_score, save_family |
| Tracker    | aboriginal_guide, bounty_hunter, amnesiac | find_truth, protect_land   |
| Publican   | inherited_pub, ex_priest, merchant        | build_community, hide_identity |
| Preacher   | *(not yet defined in rules)*              | *(not yet defined)*        |

## Name Generation

Names are generated from cultural pools based on class and origin:

```json
{
  "prospector": {
    "first_names": {
      "irish": ["Patrick", "Seamus", ...],
      "chinese": ["Chen", "Wei", ...],
      "cornish": ["Jago", "Piran", ...]
    }
  }
}
```

Format patterns (70% nickname chance):
- `{first_name} '{nickname}' {surname}`
- `{first_name} {surname}`
- `{first_name} the {nickname}`

---

## Narrative Integration

### Current State: Gameplay Rules

Backstory elements emit `gameplay_rules` strings checked by combat/event systems:

```gdscript
# Examples from existing resources:
"can_clear_name"         # wrongly_accused origin
"guided_by_spirits"      # tribe_massacred tragedy
"ancestral_obligations"  # honor_ancestors motivation
```

### Proposed: Narrative Tag Injection

To integrate with the **Narrative Graph System** ([NARRATIVE_GRAPH_SPEC.md](../specifications/NARRATIVE_GRAPH_SPEC.md)), backstory elements should inject **narrative tags** at run start.

#### Step 1: Extend BackstoryElement

Add to `backstory_element.gd`:

```gdscript
@export_group("Narrative Integration")
@export var narrative_tags: Array[StringName] = []      # Tags to add at run start
@export var tag_values: Dictionary = {}                  # Tag → value pairs
@export var unlocks_locations: Array[StringName] = []   # Locations this enables
@export var blocks_locations: Array[StringName] = []    # Locations this disables
@export var injects_nodes: Array[StringName] = []       # Node IDs to add to pool
@export var removes_nodes: Array[StringName] = []       # Node IDs to remove from pool
```

#### Step 2: Example Resource Update

`wrongly_accused.tres`:
```gdscript
narrative_tags = [&"origin_wrongly_accused", &"wants_justice", &"outlaw"]
tag_values = {
    &"reputation_with_law": -50,
    &"boss_kills_to_clear_name": 3
}
injects_nodes = [&"magistrate_appeal", &"witness_encounter"]
```

#### Step 3: Inject at Run Start

In `CharacterGenerator` or a new `BackstoryNarrativeBridge`:

```gdscript
func inject_narrative_tags(character: GeneratedCharacter) -> void:
    for element in [character.origin, character.tragedy, character.motivation, character.quirk]:
        if element == null:
            continue
        
        # Inject presence tag
        var presence_tag := StringName("backstory_%s" % element.element_id)
        NarrativeManager.add_tag(presence_tag, true, "backstory")
        
        # Inject custom tags
        for tag in element.narrative_tags:
            NarrativeManager.add_tag(tag, true, element.element_id)
        
        for tag in element.tag_values:
            NarrativeManager.add_tag(tag, element.tag_values[tag], element.element_id)
        
        # Inject/remove narrative nodes
        for node_id in element.injects_nodes:
            NarrativeManager.inject_node(node_id)
        for node_id in element.removes_nodes:
            NarrativeManager.remove_node_from_pool(node_id)
```

#### Step 4: Use in Narrative Conditions

Narrative nodes can now check backstory:

```gdscript
# NarrativeCondition in magistrate_appeal.tres:
condition_type = "HasTag"
string_value = &"origin_wrongly_accused"
# → Shows choice: "Approach the magistrate to plead your case"
```

---

## Improvement Recommendations

### 1. SOLID Violations to Address

#### Single Responsibility
`CharacterGenerator` currently handles resource loading, weighted selection, name generation, stat calculation, and curio selection.

**Recommendation**: Extract into focused classes:
```
CharacterGenerator          → Orchestration only
├── BackstorySelector       → Element selection + compatibility
├── NameGenerator           → Cultural name pools
├── StatCalculator          → Modifier application
└── CurioSelector           → Starting curio logic
```

#### Open/Closed
Adding new element types requires modifying `generate_backstory_chain()`.

**Recommendation**: Registry pattern for element types.

### 2. Godot 4.5 Best Practices

```gdscript
# Use StringName for IDs (interned strings, faster comparison)
@export var element_id: StringName = &""  # Not String

# Use typed arrays
@export var gameplay_rules: PackedStringArray = []

# Store resource references, not path strings
@export var compatible_next_elements: Array[BackstoryElement] = []
```

### 3. Preacher Class Definition

Add to `generation_rules.json`:
```json
"preacher": {
  "origins": [
    {"id": "fallen_minister", "weight": 20},
    {"id": "self_appointed", "weight": 15},
    {"id": "missionary", "weight": 15}
  ],
  "motivations": ["save_souls", "smite_corruption", "find_proof", "redemption"]
}
```

### 4. Editor Validation

Add to `backstory_element.gd`:
```gdscript
@tool
func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if element_id == "":
        warnings.append("element_id is required")
    if element_type not in ["origin", "tragedy", "motivation", "quirk"]:
        warnings.append("Unknown element_type: %s" % element_type)
    return warnings
```

---

## Example: Full Backstory Chain

**Character**: Billy "Last" Walker (Tracker)

| Element | Resource | Tags Injected | Stat Adjustments | Starting Statuses |
|---------|----------|---------------|------------------|-------------------|
| Origin | `aboriginal_guide.tres` | `origin_aboriginal_guide`, `knows_land` | — | — |
| Tragedy | `tribe_massacred.tres` | `tragedy_tribe_massacred`, `seeking_vengeance` | sanity -10 | resolve ×2 |
| Motivation | `honor_ancestors.tres` | `motivation_honor_ancestors`, `has_ritual_objective` | sanity +5 | clarity ×1 |
| Quirk | `talks_to_animals.tres` | `quirk_talks_to_animals` | — | — |

**Net Starting Stats**: sanity -5, with `resolve` (2 stacks) and `clarity` (1 stack) at first combat

**Narrative Impact**:
- Node `sacred_site_desecrated` becomes available (requires `origin_aboriginal_guide`)
- Choice "Speak with the spirits" appears when `spiritual` tag present
- Personal objective: Complete 5 rituals → unlock "Ancestral Blessing"

---

## Related Documents

- [NARRATIVE_GRAPH_SPEC.md](../specifications/NARRATIVE_GRAPH_SPEC.md) — Graph rewriting system
- [CLASS_RESOURCE_SPEC.md](../CLASS_RESOURCE_SPEC.md) — Character class definitions
- [CURIOS_CATALOG.md](../CURIOS_CATALOG.md) — Starting curio options
