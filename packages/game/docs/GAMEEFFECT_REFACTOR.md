# GameEffect System Refactor Plan

## Problem Statement

The current codebase has three separate effect systems that implement overlapping functionality:

1. **CardEffect** - Used by cards during combat
2. **EncounterOutcome** - Used by encounter choices
3. **CurioEffect** - Used by curios/relics

This separation has led to:
- **Naming conflicts**: Multiple classes with the same name (e.g., `SanityRestore`, `StatModifier`)
- **Code duplication**: Same mechanics implemented 3+ times
- **Inconsistency**: Different APIs and behaviors for the same game mechanics
- **Maintenance burden**: Changes must be made in multiple places
- **Future scaling issues**: More overlaps will emerge as content grows

### Current Overlaps Identified

| Effect Type | Card System | Encounter System | Curio System |
|------------|-------------|------------------|--------------|
| Sanity Restore | `sanity_restore.gd` | `sanity_restore.gd` | - |
| Stat Modifier | - | `stat_modifier.gd` | `stat_modifier.gd` |
| Healing | `heal.gd` | `heal_outcome.gd` | - |
| Damage | `damage.gd` | `damage_outcome.gd` | - |
| Gold Changes | `gold_gain.gd` | `gold_reward.gd` | - |
| Corruption | `add_corruption.gd` | `corruption_gain.gd` | - |

## Proposed Solution: Unified GameEffect System

### Core Architecture

```gdscript
# Base class for ALL effects in the game
class_name GameEffect
extends Resource

@export var effect_id: String = ""  # Unique identifier
@export var effect_type: String = ""  # "damage", "heal", "stat_modify", etc.
@export var target_type: String = "player"  # "player", "enemy", "all", "random"
@export var timing: String = "immediate"  # "immediate", "delayed", "persistent"
@export var description: String = ""

# Core method that all effects implement
func apply_effect(context: EffectContext) -> EffectResult:
    pass

func can_apply(context: EffectContext) -> bool:
    return true

func get_preview_text(context: EffectContext) -> String:
    return description
```

### Effect Context System

```gdscript
class_name EffectContext
extends Resource

# Source information
@export var source_type: String = ""  # "card", "encounter", "curio", "status", etc.
@export var source_object: Resource = null  # The card/encounter/curio that triggered this

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

## Source-Specific Wrappers

### For Cards
```gdscript
class_name CardEffectWrapper
extends Resource

@export var base_effect: GameEffect
@export var energy_cost_modifier: int = 0
@export var exhaust_on_use: bool = false
@export var card_specific_conditions: Dictionary = {}
```

### For Encounters
```gdscript
class_name EncounterEffectWrapper
extends Resource

@export var base_effect: GameEffect
@export var choice_requirements: Dictionary = {}
@export var narrative_text: String = ""
@export var karma_impact: int = 0
```

### For Curios
```gdscript
class_name CurioEffectWrapper
extends Resource

@export var base_effect: GameEffect
@export var trigger_event: String = "passive"
@export var stacks_with_duplicates: bool = false
@export var chance_to_trigger: float = 1.0
```

## Migration Strategy

### Phase 1: Foundation (Week 1)
1. Create `GameEffect` base class
2. Create `EffectContext` and `EffectResult` classes
3. Create `EffectRegistry` singleton for effect lookup
4. Set up effect testing framework

### Phase 2: Core Effects (Week 1-2)
1. Implement `HealthEffect`
2. Implement `DamageEffect`
3. Implement `StatEffect`
4. Implement `SanityEffect`
5. Create unit tests for each

### Phase 3: Adapter Layer (Week 2)
1. Create `LegacyCardEffectAdapter`
2. Create `LegacyEncounterAdapter`
3. Create `LegacyCurioAdapter`
4. These allow old content to work with new system

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
extends EncounterOutcome
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
```

## Implementation Checklist

### Immediate Actions (Before Any Refactoring)
- [ ] Create this documentation
- [ ] Get team buy-in on approach
- [ ] Create refactor/gameeffect branch
- [ ] Set up test environment

### Quick Fixes (Can do now)
- [ ] Rename `SanityRestore` in encounters to `SanityRestoreOutcome`
- [ ] Rename `StatModifier` in encounters to `StatModifierOutcome`
- [ ] Fix any other naming conflicts

### Foundation Work
- [ ] Create effects/ directory structure
- [ ] Implement GameEffect base class
- [ ] Implement EffectContext
- [ ] Implement EffectResult
- [ ] Create EffectRegistry singleton
- [ ] Set up effect unit tests

### Migration Work
- [ ] Create adapter classes
- [ ] Migrate encounters (smallest scope)
- [ ] Migrate curios (medium scope)
- [ ] Migrate cards (largest scope)
- [ ] Update all .tres files
- [ ] Remove legacy systems

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

## Questions to Resolve

1. Should effects be able to trigger other effects recursively?
2. How do we handle effect stacking (multiple of same effect)?
3. Should effects have priority/ordering?
4. How do we handle conditional effects?
5. Should effects support custom scripting?

## Next Steps

1. Review this plan with team
2. Create quick fixes for naming conflicts
3. Begin Phase 1 implementation
4. Create prototype with 2-3 effects
5. Test in encounter system first