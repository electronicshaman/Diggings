# Curios Integration Plan

## Executive Summary

This document outlines a comprehensive plan to integrate the Curios system (relic-like persistent modifiers) into the card battler prototype using the existing theme-agnostic, data-driven architecture.

## Review of Current Curios.md

### Strengths
- Good variety of rarity tiers (Common, Rare, Legendary, Corrupted)
- Clear risk/reward mechanics especially in Corrupted tier
- Interesting cross-class synergies demonstrated
- Thematically appropriate (Australian gold rush + Lovecraftian)

### Suggested Improvements

1. **Add Mechanical Categories** - Similar to cards, curios should have theme-agnostic categories:
   - **Passive** - Always active effects (Lucky Nugget, Thick Leather)
   - **Triggered** - Activate on specific conditions (Blood Money, Rabbit's Foot)
   - **Modifier** - Change game rules (Fool's Gold Crown, Temporal Pocket Watch)
   - **Resource** - Affect resource systems (Endless Bottle, Corrupted Compass)

2. **Add Activation Timing** - Clear trigger points:
   - Combat Start, Turn Start, Card Played, Damage Dealt/Taken, etc.

3. **Add Stack Limits** - Can player have multiple of same curio?

4. **Class Synergy Scores** - Numerical affinity ratings per class

## Architecture Design

### 1. Core Data Structure

```gdscript
# data/CurioData.gd
extends Resource
class_name CurioData

# Basic Info
@export var curio_name: String = "Curio"
@export var description: String = ""
@export var icon: Texture2D
@export var flavor_text: String = ""

# Mechanical Properties
@export var mechanical_category: String = "Passive"  # Passive/Triggered/Modifier/Resource
@export var rarity: String = "Common"  # Common/Rare/Legendary/Corrupted
@export var stackable: bool = false
@export var max_stacks: int = 1

# Effects (modular like cards)
@export var effects: Array[CurioEffect] = []

# Costs/Requirements
@export var corruption_cost: int = 0  # For corrupted curios
@export var gold_cost: int = 0  # For shop purchases

# Class Relationships
@export var class_synergy: Dictionary = {}  # "Bushranger": 0.8, etc.
```

### 2. Effect System

```gdscript
# data/CurioEffect.gd
extends Resource
class_name CurioEffect

@export var effect_name: String = "Base Curio Effect"
@export var trigger_event: String = "passive"  # passive/combat_start/turn_start/card_played/etc.
@export var description: String = ""

func apply_effect(_game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
    pass

func can_trigger(_game_state: Node, _context: Dictionary) -> bool:
    return true
```

### 3. Manager System

```gdscript
# scripts/autoloads/curio_manager.gd
extends Node

signal curio_acquired(curio: CurioData)
signal curio_removed(curio: CurioData)
signal curio_triggered(curio: CurioData, effect: String)

var active_curios: Array[CurioData] = []
var curio_stacks: Dictionary = {}  # curio_name -> stack_count

func add_curio(curio: CurioData) -> bool:
    # Handle stacking logic
    # Add to active list
    # Connect to relevant events
    pass

func remove_curio(curio: CurioData) -> void:
    # Remove from active list
    # Disconnect events
    pass

func trigger_curios(event_type: String, context: Dictionary) -> void:
    # Check all curios for matching triggers
    # Apply effects in order
    pass
```

## Integration Points

### 1. EventBus Extensions

Add new signals to `event_bus.gd`:
```gdscript
signal curio_acquired(curio: CurioData)
signal curio_removed(curio: CurioData)
signal curio_triggered(curio: CurioData, effect_name: String)
signal curio_stack_changed(curio: CurioData, new_count: int)
```

### 2. PlayerData Extensions

Add to `PlayerData.gd`:
```gdscript
@export var curios: Array[CurioData] = []
@export var curio_stacks: Dictionary = {}  # For stackable curios

func add_curio(curio: CurioData) -> void:
    if curio not in curios:
        curios.append(curio)
        _emit_change("curio_added", null, curio)

func get_curio_modifier(stat_name: String) -> float:
    # Calculate cumulative modifiers from all curios
    pass
```

### 3. GameManager Extensions

Add to `game_data` dictionary:
```gdscript
"curios": [],  # Array of CurioData resources
"curio_stacks": {},  # Stacking counts
"curios_offered": [],  # Track offered curios to avoid duplicates
```

## File Structure

```
data/
  curios/
    common/
      lucky_nugget.tres
      worn_boots.tres
      old_compass.tres
      thick_leather.tres
      sharpened_blade.tres
      canvas_bag.tres
      rabbits_foot.tres
    rare/
      fools_gold_crown.tres
      corrupted_compass.tres
      temporal_pocket_watch.tres
      blood_money.tres
      gunslingers_belt.tres
      prospectors_monocle.tres
      endless_bottle.tres
    legendary/
      antipodean_star.tres
      ned_kellys_helm.tres
      eureka_license.tres
      last_drop.tres
    corrupted/
      void_touched_coin.tres
      eldritch_map.tres
      cursed_pickaxe.tres
      whispering_flask.tres

scripts/
  curios/
    CurioData.gd
    effects/
      StatModifier.gd      # +X to stat
      ResourceGain.gd       # +X gold/energy per trigger
      CardModifier.gd       # Modify card costs/damage
      DefenseBonus.gd       # +X block on condition
      ChanceEffect.gd       # X% chance to trigger
      MapModifier.gd        # Change map visibility/movement
      CombatModifier.gd     # Change combat rules
```

## Implementation Phases

### Phase 1: Core System (Foundation)
1. Create CurioData and CurioEffect base classes
2. Implement CurioManager autoload
3. Add curio storage to PlayerData
4. Create EventBus signals

### Phase 2: Basic Curios (Common Tier)
1. Implement 7 common curios with simple effects
2. Create basic curio effects (StatModifier, ResourceGain)
3. Test in debug mode with manual curio addition

### Phase 3: Acquisition Systems
1. Add curio rewards to combat victories
2. Create curio shop interface
3. Implement event-based curio acquisition
4. Add curio selection UI

### Phase 4: Advanced Curios (Rare/Legendary)
1. Implement complex effects (rule modifiers, conditionals)
2. Add visual feedback for curio triggers
3. Create curio inspection UI

### Phase 5: Corrupted System
1. Implement corruption mechanics
2. Add corrupted curios with drawbacks
3. Balance risk/reward ratios

### Phase 6: Polish & Balance
1. Add curio icons and visual effects
2. Balance curio drop rates
3. Implement curio synergy hints
4. Add save/load support

## Example Curio Implementations

### Simple Passive Curio
```gdscript
# data/curios/common/lucky_nugget.tres
[gd_resource type="Resource" script_class="CurioData"]

[ext_resource type="Script" path="res://scripts/curios/effects/ResourceGain.gd" id="1"]

[sub_resource type="Resource" id="1"]
script = ExtResource("1")
effect_name = "Gold Bonus"
trigger_event = "combat_start"
resource_type = "gold"
amount = 3

[resource]
curio_name = "Lucky Nugget"
description = "+3 gold at the start of each combat"
mechanical_category = "Passive"
rarity = "Common"
effects = [SubResource("1")]
```

### Complex Triggered Curio
```gdscript
# data/curios/rare/temporal_pocket_watch.tres
[gd_resource type="Resource" script_class="CurioData"]

[ext_resource type="Script" path="res://scripts/curios/effects/CardReturn.gd" id="1"]

[sub_resource type="Resource" id="1"]
script = ExtResource("1")
effect_name = "Temporal Return"
trigger_event = "card_played"
condition = "first_card_per_turn"
return_to_hand = true

[resource]
curio_name = "Temporal Pocket Watch"
description = "The first card played each turn returns to your hand"
mechanical_category = "Modifier"
rarity = "Rare"
effects = [SubResource("1")]
class_synergy = {
    "Prospector": 1.2,
    "Bushranger": 1.0,
    "Tracker": 1.3,
    "Publican": 0.9
}
```

## Testing Strategy

### Debug Commands
Add to debug panel:
- `/give_curio [name]` - Add curio to player
- `/remove_curio [name]` - Remove curio
- `/list_curios` - Show all active curios
- `/trigger_curio [name]` - Force trigger a curio

### Test Scenarios
1. **Basic Function**: Add curio, verify effect applies
2. **Stacking**: Test stackable curios work correctly
3. **Persistence**: Curios survive between combats
4. **Save/Load**: Curios persist through save/load
5. **UI Display**: Curios show in inventory/tooltip
6. **Trigger Order**: Multiple curios trigger in correct order

## Balance Considerations

### Drop Rates
- Common: 60% from normal combats
- Rare: 30% from elites, 10% from normals
- Legendary: Boss rewards, special events only
- Corrupted: Special corruption events, risky choices

### Power Budget
- Common: Minor stat boosts (~10-20% improvement)
- Rare: Significant advantage or rule change
- Legendary: Run-defining power with drawback
- Corrupted: High power with corruption cost

### Class Balance
Each class should have:
- 2-3 curios with high synergy
- 2-3 curios with medium synergy
- Rest with low but usable synergy

## UI/UX Requirements

### Display Locations
1. **Inventory Screen**: Grid of owned curios with tooltips
2. **Combat UI**: Active curio icons with trigger animations
3. **Reward Screen**: Curio selection with preview
4. **Shop**: Purchasable curios with prices

### Visual Feedback
- Glow effect when curio triggers
- Sound effect for activation
- Text popup showing effect applied
- Icon badges for stacked curios

## Migration Path

Since no curio system exists yet, this is a pure addition:

1. No breaking changes to existing systems
2. CurioManager loads after other autoloads
3. Curios optional for initial implementation
4. Can be disabled via GameSettings flag

## Success Metrics

- Players understand curio effects without confusion
- Curios create interesting build decisions
- No single curio becomes mandatory
- Corrupted curios see 30%+ pickup rate despite drawbacks
- Average run has 3-5 curios by completion

## Next Steps

1. Review and approve this plan
2. Create base CurioData and CurioEffect classes
3. Implement CurioManager autoload
4. Create first batch of common curios for testing
5. Integrate with existing reward system