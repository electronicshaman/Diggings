# GameEffect System Refactor Plan

This iteration turns the proposal into an actionable plan with concrete Godot wiring, decisions on stacking/ordering/conditions, a directory layout, adapters, tests, and a migration path.

| Gold Changes | `gold_gain.gd` | `gold_reward.gd` | - |
```text
scripts/
   effects/
      core/
         game_effect.gd            # base
         effect_context.gd
         effect_result.gd
      registry/
         effect_registry.gd        # autoload
      types/                      # unified implementations
         health_effect.gd
         damage_effect.gd
         stat_effect.gd
         sanity_effect.gd
         resource_effect.gd
         defense_effect.gd
         card_manipulation_effect.gd
      adapters/                   # temporary, for migration
         legacy_card_effect_adapter.gd
         legacy_encounter_adapter.gd
         legacy_curio_adapter.gd
      wrappers/
         card_effect_wrapper.gd
         encounter_effect_wrapper.gd
         curio_effect_wrapper.gd
data/
   effects/                      # .tres instances for content
tests/
   effects/                      # unit tests
```
| Corruption | `add_corruption.gd` | `corruption_gain.gd` | - |

## Proposed Solution: Unified GameEffect System

### Core Architecture

```gdscript
# Base class for ALL effects in the game
class_name GameEffect
extends Resource

@export var effect_id: String = ""  # Unique identifier
@export var effect_type: String = ""  # "damage", "heal", "stat_modify", etc. (tag-like; class type is authoritative)
@export var target_type: String = "player"  # "player", "enemy", "all", "random"
@export var timing: String = "immediate"  # "immediate", "delayed", "persistent"
@export var description: String = ""

# Execution and ordering
@export var priority: int = 0  # Higher runs earlier within a phase
@export var phase: String = "default"  # E.g., "on_play", "turn_start", "turn_end"

# Stacking semantics
@export var stack_key: String = ""  # Effects with same key are considered the same for stacking
@export var stack_behavior: String = "independent"  # "independent" | "stack_values" | "refresh_duration" | "cap_value"
@export var stack_cap: int = 0  # 0 = no cap; used when stack_behavior == "cap_value" or for max stacks

    pass
func get_preview_text(context: EffectContext) -> String:
### Effect Context System

# State references
@export var game_manager: Node = null
@export var duel_manager: Node = null  # May be null outside combat
@export var player_data: Resource = null
@export var enemy_data: Resource = null  # May be null outside combat

# Trigger information
@export var trigger_event: String = ""  # "card_played", "turn_start", "enemy_defeated", etc.
@export var trigger_data: Dictionary = {}  # Event-specific data

# Targeting
@export var primary_target: Resource = null
@export var secondary_targets: Array[Resource] = []

# Utility/context cache to reduce allocations
var _cache: Dictionary = {}
```

### Effect Result System

```gdscript
class_name EffectResult
extends Resource

@export var success: bool = true
@export var values_applied: Dictionary = {}  # What actually happened
@export var prevented_by: String = ""  # If blocked/prevented
@export var critical: bool = false
@export var overkill: int = 0
@export var triggers: Array[String] = []  # Other effects to trigger
@export var ui_feedback: Dictionary = {}  # Info for UI display

# Diagnostics
@export var logs: Array[String] = []
```

## Specific Effect Implementations

### Core Effect Types

1. **HealthEffect** - All healing and health modifications
   - Replaces: `Heal`, `HealOutcome`, `ConditionalHeal`
   - Parameters: amount, percentage_based, full_heal, max_heal

2. **DamageEffect** - All damage dealing
   - Replaces: `Damage`, `DamageOutcome`, `MultipleDamage`, `RandomDamage`
   - Parameters: amount, ignores_defense, multi_hit, random_target

3. **StatEffect** - All stat modifications
   - Replaces: All `StatModifier` variants
   - Parameters: stat_name, modifier_value, modifier_type, duration

4. **SanityEffect** - All sanity modifications
   - Replaces: All `SanityRestore` variants
   - Parameters: amount, percentage_based, full_restore

5. **ResourceEffect** - Gold, energy, corruption changes
   - Replaces: `GoldGain`, `GoldReward`, `CorruptionGain`, `AddCorruption`
   - Parameters: resource_type, amount, can_go_negative

6. **DefenseEffect** - Armor and defense modifications
   - Replaces: `Defense`, `ConditionalDefense`, `DelayedDefense`
   - Parameters: amount, duration, condition

7. **CardManipulationEffect** - Draw, discard, deck changes
   - Replaces: `Draw`, `ForcedDiscard`, `DeckManipulation`
   - Parameters: action, amount, card_filter

## Source-Specific Properties (Integrated into GameEffect)

The functionality previously provided by wrapper classes has been integrated directly into the GameEffect base class:

### Card-Specific Properties

```gdscript
# In GameEffect class:
@export var energy_cost_modifier: int = 0
@export var exhaust_on_use: bool = false
@export var card_specific_conditions: Dictionary = {}
```

### Encounter-Specific Properties

```gdscript
# In GameEffect class:
@export var choice_requirements: Dictionary = {}
@export var narrative_text: String = ""
@export var karma_impact: int = 0
```

### Curio-Specific Properties

```gdscript
# In GameEffect class:
@export var trigger_events: Array[String] = [] # Events that trigger this effect
@export var stacks_with_duplicates: bool = false
@export var chance_to_trigger: float = 1.0
@export var max_stacks: int = 0
```

This eliminates the need for separate wrapper classes while maintaining all the source-specific functionality.
```

## Godot Project Wiring and Directory Layout

Recommended directory structure to keep effects cohesive and discoverable:

   - game_effect.gd            (base)
   - effect_context.gd
   - effect_result.gd
   - effect_registry.gd        (autoload)
   - health_effect.gd
   - damage_effect.gd
   - stat_effect.gd
   - sanity_effect.gd
   - resource_effect.gd
   - defense_effect.gd
   - card_manipulation_effect.gd
   - legacy_card_effect_adapter.gd
   - legacy_encounter_adapter.gd
   - legacy_curio_adapter.gd
   - card_effect_wrapper.gd
   - encounter_effect_wrapper.gd
   - curio_effect_wrapper.gd

Autoload wiring (Godot 4): add to project.godot

```ini
Autoload wiring (Godot 4): add to project.godot

```ini
[autoload]
EffectRegistry="*res://scripts/handlers/registry/effect_registry.gd"
```

Minimal EffectRegistry API:

```gdscript
extends Node
class_name EffectRegistry

var _by_id: Dictionary = {}
var _class_by_type: Dictionary = {
      "health": preload("res://scripts/handlers/types/health_effect.gd"),
      "damage": preload("res://scripts/handlers/types/damage_effect.gd"),
      # ... add more
}

func register_effect(effect: GameEffect) -> void:
      if effect.effect_id != "":
            _by_id[effect.effect_id] = effect

func get_by_id(id: String) -> GameEffect:
      return _by_id.get(id, null)

func new_by_type(type_key: String) -> GameEffect:
      var C = _class_by_type.get(type_key, null)
      return C.new() if C else null
```

## Migration Strategy

### Phase 1: Foundation (Week 1)

1. Create `GameEffect` base class
2. Create `EffectContext` and `EffectResult` classes
3. Create `EffectRegistry` singleton for effect lookup
4. Set up effect testing framework
5. Add `EffectRegistry` as autoload in `project.godot`
6. Create directory structure outlined above

### Phase 2: Core Effects (Week 1-2)

1. Implement `HealthEffect`
2. Implement `DamageEffect`
3. Implement `StatEffect`
4. Implement `SanityEffect`
5. Implement `ResourceEffect`, `DefenseEffect`, `CardManipulationEffect`
6. Create unit tests for each

### Phase 3: Adapter Layer (Week 2)

1. Create `LegacyCardEffectAdapter`
2. Create `LegacyEncounterAdapter`
3. Create `LegacyCurioAdapter`
4. These allow old content to work with new system
5. Add feature flags/env toggles to swap systems per-subsystem for safe rollout

### Phase 4: Encounter Migration (Week 3)

1. Update EncounterManager to use GameEffect
2. Migrate encounter .tres files
3. Test all encounters
4. Remove old EncounterOutcome classes

### Phase 5: Curio Migration (Week 3-4)

1. Update CurioManager to use GameEffect
2. Migrate curio .tres files
3. Test all curios
4. Remove old CurioEffect classes

### Phase 6: Card Migration (Week 4-5)

1. Update CardEffects system to use GameEffect
2. Create migration script for card .tres files
3. Migrate cards in batches (by type)
4. Test combat extensively
5. Remove old CardEffect classes

### Phase 7: Cleanup (Week 5-6)

1. Remove adapter layers
2. Remove old effect systems
3. Update documentation
4. Performance optimization

### Migration Tools and Guidance

- Create `scripts/tools/migrate_effects.gd` to scan `.tres` content and rewrite effect resources to unified types.
- Maintain a mapping table from legacy class names to new types and field transforms.
- Add `version` to effect resources and bump on structural changes; write an in-place upgrader.
- Keep legacy aliases in `EffectRegistry` during migration to resolve old IDs.

## Benefits

1. **Single Source of Truth**: One implementation per game mechanic
2. **Reusability**: Effects work across all game systems
3. **Consistency**: Uniform behavior and balance
4. **Extensibility**: New systems (items, skills) get all effects for free
5. **Maintainability**: Fix once, works everywhere
6. **Type Safety**: No naming conflicts
7. **Better Testing**: One test suite for all effects
8. **Easier Balancing**: Central location for all effect values

## Example: Healing Effect Migration

### Before (3 separate implementations)
```gdscript
# cards/effects/heal.gd
extends CardEffect
class_name Heal
@export var heal_amount: int = 1

# encounters/outcomes/heal_outcome.gd  
extends Resource # legacy EncounterOutcome removed; use GameEffect-based resources
class_name HealOutcome
@export var heal_amount: int = 10
@export var percentage_based: bool = false

# (Potential curio healing effect)
extends CurioEffect
class_name HealingAura
@export var heal_per_turn: int = 1
```

### After (1 unified implementation)
```gdscript
# effects/core/health_effect.gd
extends GameEffect
class_name HealthEffect

@export var amount: int = 0
@export var percentage_based: bool = false
@export var percentage: float = 0.0
@export var full_heal: bool = false
@export var can_overheal: bool = false

func apply_effect(context: EffectContext) -> EffectResult:
    # One implementation handles all healing scenarios
    var result = EffectResult.new()
    var target = _get_target(context)
    var heal_amount = _calculate_amount(target)
    
    # Apply healing
    target.heal(heal_amount)
    
    # Record results
    result.values_applied["healing"] = heal_amount
    result.success = true
    
    # Trigger events
    if context.game_manager:
        context.game_manager.emit_signal("healing_applied", heal_amount)
    
    return result

func _get_target(context: EffectContext) -> Object:
   return context.primary_target if context.primary_target else context.player_data

func _calculate_amount(target: Object) -> int:
   if full_heal and hasattr(target, "max_hp"):
      return int(target.max_hp)
   if percentage_based and hasattr(target, "max_hp"):
      return int(round(target.max_hp * clamp(percentage, 0.0, 1.0)))
   return max(0, amount)
```

## Implementation Checklist

### Immediate Actions (Before Any Refactoring)
- [ ] Create this documentation
- [ ] Get team buy-in on approach
- [ ] Create refactor/gameeffect branch
- [ ] Set up test environment
- [ ] Add EffectRegistry autoload entry
- [ ] Scaffold directory structure under scripts/effects/

### Quick Fixes (Can do now)
- [ ] Rename `SanityRestore` in encounters to `SanityRestoreOutcome`
- [ ] Rename `StatModifier` in encounters to `StatModifierOutcome`
- [ ] Fix any other naming conflicts
- [ ] Add unique `effect_id` to existing effect resources where ambiguous

### Foundation Work
- [ ] Create effects/ directory structure
- [ ] Implement GameEffect base class
- [ ] Implement EffectContext
- [ ] Implement EffectResult
- [ ] Create EffectRegistry singleton
- [ ] Set up effect unit tests
- [ ] Decide on `phase` values and default `priority` ranges

### Migration Work
- [ ] Create adapter classes
- [ ] Migrate encounters (smallest scope)
- [ ] Migrate curios (medium scope)
- [ ] Migrate cards (largest scope)
- [ ] Update all .tres files
- [ ] Remove legacy systems
- [ ] Implement `scripts/tools/migrate_effects.gd` with mapping table
- [ ] Add `version` field and upgrader for resources

## Risks and Mitigation

### Risk: Breaking existing content
**Mitigation**: Adapter layer allows gradual migration

### Risk: Performance impact
**Mitigation**: Profile before/after, optimize hot paths

### Risk: Save game compatibility
**Mitigation**: Version saves, provide migration path

### Risk: Mod compatibility
**Mitigation**: Keep legacy effect names as aliases

## Success Criteria

1. No naming conflicts in the codebase
2. All effects share common implementation
3. New effect types can be added in one place
4. All existing content works without changes
5. Performance is same or better
6. Test coverage for all effects
7. Documentation updated

## Timeline Estimate

- **Planning & Setup**: 2-3 days
- **Core Implementation**: 1 week
- **Migration**: 2-3 weeks
- **Testing & Polish**: 1 week
- **Total**: 4-5 weeks for complete refactor

## Alternative Approaches Considered

### Option 1: Namespace Effects
- Keep separate systems but namespace them
- Pros: Less work, no migration needed
- Cons: Doesn't solve duplication, still have multiple implementations

### Option 2: Effect Composition
- Build effects from smaller atomic operations
- Pros: Very flexible, highly reusable
- Cons: More complex, harder to understand

### Option 3: Effect Inheritance Tree
- Use inheritance for effect variants
- Pros: OOP approach, type safe
- Cons: Deep hierarchies, rigid structure

**Chosen: Unified System** because it best balances simplicity, flexibility, and maintainability.

## Decisions (resolving open questions)

1. Recursive triggers: Allowed via `EffectResult.triggers` and/or event emissions. Depth is capped (default 8) with cycle detection using a per-context trigger set. If a cycle is detected, set `prevented_by = "cycle"` and stop.
2. Stacking: Governed by `stack_key`, `stack_behavior`, `stack_cap`. Default is `independent`. Status-like persistent effects should use `refresh_duration` or `stack_values`. Duplicate curios may set `curio_effect_wrapper.max_stacks` and `stacks_with_duplicates`.
3. Priority/ordering: Effects run by `phase` buckets with ascending lexicographic phase order configurable in the manager, then by `priority` (higher first). Ties resolve by insertion order.
4. Conditional effects: Use `can_apply()` plus optional `conditions: Array[Condition]` on wrappers. Provide a simple `Condition` Resource with `passes(context) -> bool`. For complex logic, compose multiple conditions.
5. Custom scripting: Supported by authoring new `GameEffect` subclasses. For data-only customization, expose parameters; avoid arbitrary code injection in content files to keep determinism and security.

## Next Steps

1. Review this plan with team
2. Create quick fixes for naming conflicts
3. Begin Phase 1 implementation
4. Create prototype with 2-3 effects
5. Test in encounter system first

---

Notes
- Prefer class types over stringly-typed `effect_type` for logic; keep `effect_type` only for tagging/queries and analytics.
- Keep public APIs stable during migration; mark adapters with `@warning_ignore("deprecated")` comments where needed.