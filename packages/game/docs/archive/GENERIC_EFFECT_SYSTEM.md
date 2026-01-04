# Generic Effect System Architecture

This document outlines a clean, universal effect system for a new card battler project. The system is designed to handle effects from ANY source - cards, encounters, curios, status effects, environmental hazards, and more.

## Core Philosophy

- **Universal**: One effect system for everything
- **Context-Aware**: Effects understand their source and situation
- **Data-Driven**: Effects are Godot Resources, easily created in editor
- **Reusable**: Same effect types work across all systems
- **Clean**: No legacy code, designed from scratch
- **Extensible**: Easy to add new effect types

## Project Structure

```
new-card-battler/
├── project.godot
├── effects/
│   ├── core/
│   │   ├── Effect.gd
│   │   ├── EffectContext.gd
│   │   ├── EffectResult.gd
│   │   └── EffectProcessor.gd
│   └── types/
│       ├── combat/
│       │   ├── DamageEffect.gd
│       │   ├── HealEffect.gd
│       │   └── DefenseEffect.gd
│       ├── resource/
│       │   ├── ResourceEffect.gd
│       │   └── EnergyEffect.gd
│       └── card/
│           ├── DrawEffect.gd
│           └── DiscardEffect.gd
├── game/
│   ├── cards/
│   │   └── Card.gd
│   ├── encounters/
│   │   └── Encounter.gd
│   └── curios/
│       └── Curio.gd
├── data/
│   ├── cards/
│   ├── encounters/
│   └── curios/
└── autoloads/
    └── EffectProcessor.gd  # Singleton processor
```

## Core System Implementation

### 1. Base Effect Class

```gdscript
# effects/core/Effect.gd
extends Resource
class_name Effect

@export var effect_type: String = ""
@export var target: String = "self"  # self, enemy, all_enemies, random, all
@export var amount: int = 0
@export var duration: int = 0  # 0 = instant, >0 = turns for persistent effects
@export var tags: Array[String] = []  # For filtering/searching effects

# Generic parameters for maximum flexibility
@export var params: Dictionary = {}

# Core execution method - override in subclasses
func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    return result

# Check if effect can be executed in current context
func can_execute(context: EffectContext) -> bool:
    return true

# Get human-readable description for UI
func get_description(context: EffectContext = null) -> String:
    return "Base effect"

# Helper method for chaining effect creation
func set_amount(value: int) -> Effect:
    amount = value
    return self

func set_target(target_type: String) -> Effect:
    target = target_type
    return self

func set_param(key: String, value) -> Effect:
    params[key] = value
    return self
```

### 2. Effect Context

```gdscript
# effects/core/EffectContext.gd
extends Resource
class_name EffectContext

# Source information - what triggered this effect?
@export var source_type: String  # "card", "encounter", "curio", "status", "environment"
@export var source: Resource     # The actual triggering object

# Actor information - who's involved?
var caster: Resource   # Who/what is causing the effect
var target: Resource   # Primary target of the effect
var targets: Array     # Multiple targets if needed

# Game state references (set by processor)
var combat_state: Resource = null  # Only available during combat
var world_state: Resource = null   # Always available for world state
var player: Resource = null        # Player data

# Contextual information
@export var trigger_event: String = ""  # "card_played", "turn_start", "combat_end"
@export var params: Dictionary = {}     # Additional context data

# Timing information
@export var turn_number: int = 0
@export var cards_played_this_turn: int = 0
@export var is_first_card: bool = false
@export var is_last_card: bool = false

# Helper methods
func get_target_by_type(target_type: String):
    match target_type:
        "self", "caster":
            return caster
        "enemy":
            if combat_state:
                return combat_state.get_primary_enemy()
            return null
        "player":
            return player
        "random_enemy":
            if combat_state:
                var enemies = combat_state.get_all_enemies()
                return enemies[randi() % enemies.size()] if enemies.size() > 0 else null
            return null
        _:
            return target

func has_tag(tag: String) -> bool:
    return params.has("tags") and tag in params.tags
```

### 3. Effect Result

```gdscript
# effects/core/EffectResult.gd
extends Resource
class_name EffectResult

@export var success: bool = true
@export var effect_type: String = ""

# Values that were applied/calculated
@export var values: Dictionary = {}

# Additional result data
@export var prevented_by: String = ""  # What prevented execution (if failed)
@export var triggered_effects: Array[Effect] = []  # Effects that this effect triggered
@export var ui_feedback: Dictionary = {}  # Data for UI animations/feedback
@export var logs: Array[String] = []  # Debug/combat log entries

# Helper methods
func add_value(key: String, value):
    values[key] = value

func get_value(key: String, default_value = null):
    return values.get(key, default_value)

func add_log(message: String):
    logs.append(message)
```

### 4. Effect Processor (Singleton)

```gdscript
# autoloads/EffectProcessor.gd
extends Node

signal effect_executed(effect: Effect, result: EffectResult, context: EffectContext)
signal effect_failed(effect: Effect, reason: String, context: EffectContext)
signal effect_batch_completed(results: Array[EffectResult])

# Execute a single effect
func execute_effect(effect: Effect, context: EffectContext) -> EffectResult:
    if not effect.can_execute(context):
        var result = EffectResult.new()
        result.success = false
        result.prevented_by = "conditions_not_met"
        effect_failed.emit(effect, result.prevented_by, context)
        return result
    
    var result = effect.execute(context)
    
    if result.success:
        # Apply the result to game state
        _apply_result(result, context)
        effect_executed.emit(effect, result, context)
    else:
        effect_failed.emit(effect, result.prevented_by, context)
    
    return result

# Execute multiple effects in sequence
func execute_effects(effects: Array[Effect], context: EffectContext) -> Array[EffectResult]:
    var results: Array[EffectResult] = []
    
    for effect in effects:
        var result = execute_effect(effect, context)
        results.append(result)
        
        # Check if we should stop processing on failure
        if not result.success and context.params.get("stop_on_failure", false):
            break
    
    effect_batch_completed.emit(results)
    return results

# Apply effect results to actual game state
func _apply_result(result: EffectResult, context: EffectContext):
    # Damage
    if result.values.has("damage_dealt"):
        var target = context.get_target_by_type(context.target.target if context.target else "enemy")
        if target and target.has_method("take_damage"):
            target.take_damage(result.values.damage_dealt)
    
    # Healing
    if result.values.has("health_restored"):
        var target = context.get_target_by_type(context.target.target if context.target else "self")
        if target and target.has_method("heal"):
            target.heal(result.values.health_restored)
    
    # Defense
    if result.values.has("defense_gained"):
        var target = context.get_target_by_type(context.target.target if context.target else "self")
        if target and target.has_method("add_defense"):
            target.add_defense(result.values.defense_gained)
    
    # Resources (gold, energy, etc.)
    if result.values.has("resource_gained"):
        var resource_type = result.values.get("resource_type", "gold")
        var amount = result.values.resource_gained
        if context.player and context.player.has_method("add_resource"):
            context.player.add_resource(resource_type, amount)
    
    # Card manipulation
    if result.values.has("cards_drawn"):
        if context.combat_state and context.combat_state.has_method("draw_cards"):
            context.combat_state.draw_cards(result.values.cards_drawn)
    
    # Add more result applications as needed...
```

## Core Effect Types

### Combat Effects

```gdscript
# effects/types/combat/DamageEffect.gd
extends Effect
class_name DamageEffect

@export var damage_type: String = "physical"  # physical, magical, true
@export var can_crit: bool = true
@export var piercing: bool = false  # Ignores armor/defense
@export var multi_hit: bool = false
@export var hits: int = 1

func _init():
    effect_type = "damage"
    target = "enemy"

func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    
    var target = context.get_target_by_type(target)
    if not target:
        result.success = false
        result.prevented_by = "no_target"
        return result
    
    var final_amount = amount
    var final_hits = hits if multi_hit else 1
    
    # Apply context modifiers
    if context.params.has("damage_multiplier"):
        final_amount = int(final_amount * context.params.damage_multiplier)
    
    # Calculate actual damage
    var total_damage = 0
    for hit in final_hits:
        var hit_damage = final_amount
        
        # Apply critical hits
        if can_crit and context.params.get("can_crit", true):
            if randf() < context.params.get("crit_chance", 0.1):
                hit_damage = int(hit_damage * context.params.get("crit_multiplier", 2.0))
                result.add_log("Critical hit!")
        
        # Apply armor reduction (unless piercing)
        if not piercing and target.has_method("get_defense"):
            var defense = target.get_defense()
            hit_damage = max(0, hit_damage - defense)
        
        total_damage += hit_damage
    
    result.add_value("damage_dealt", total_damage)
    result.add_value("hits", final_hits)
    result.add_value("piercing", piercing)
    result.success = true
    
    result.add_log("Dealt %d damage" % total_damage)
    if multi_hit:
        result.add_log("(%d hits)" % final_hits)
    
    return result

func get_description(context: EffectContext = null) -> String:
    var desc = "Deal %d damage" % amount
    if multi_hit:
        desc += " %d times" % hits
    if piercing:
        desc += " (piercing)"
    return desc
```

```gdscript
# effects/types/combat/HealEffect.gd
extends Effect
class_name HealEffect

@export var can_overheal: bool = false
@export var heal_type: String = "normal"  # normal, regeneration, vampiric

func _init():
    effect_type = "heal"
    target = "self"

func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    
    var target = context.get_target_by_type(target)
    if not target:
        result.success = false
        result.prevented_by = "no_target"
        return result
    
    var final_amount = amount
    
    # Apply context modifiers
    if context.params.has("heal_multiplier"):
        final_amount = int(final_amount * context.params.heal_multiplier)
    
    result.add_value("health_restored", final_amount)
    result.add_value("can_overheal", can_overheal)
    result.success = true
    
    result.add_log("Restored %d health" % final_amount)
    
    return result

func get_description(context: EffectContext = null) -> String:
    return "Restore %d health" % amount
```

```gdscript
# effects/types/combat/DefenseEffect.gd
extends Effect
class_name DefenseEffect

@export var defense_type: String = "armor"  # armor, shield, barrier
@export var temporary: bool = true  # Lost at end of turn

func _init():
    effect_type = "defense"
    target = "self"

func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    
    var target = context.get_target_by_type(target)
    if not target:
        result.success = false
        result.prevented_by = "no_target"
        return result
    
    var final_amount = amount
    
    # Apply context modifiers
    if context.params.has("defense_multiplier"):
        final_amount = int(final_amount * context.params.defense_multiplier)
    
    result.add_value("defense_gained", final_amount)
    result.add_value("defense_type", defense_type)
    result.add_value("temporary", temporary)
    result.success = true
    
    result.add_log("Gained %d defense" % final_amount)
    
    return result

func get_description(context: EffectContext = null) -> String:
    return "Gain %d defense" % amount
```

### Resource Effects

```gdscript
# effects/types/resource/ResourceEffect.gd
extends Effect
class_name ResourceEffect

@export var resource_type: String = "gold"  # gold, energy, sanity, karma
@export var operation: String = "add"  # add, subtract, set, multiply

func _init():
    effect_type = "resource"
    target = "self"

func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    
    var final_amount = amount
    
    # Apply context modifiers
    var multiplier_key = resource_type + "_multiplier"
    if context.params.has(multiplier_key):
        final_amount = int(final_amount * context.params[multiplier_key])
    
    result.add_value("resource_gained", final_amount)
    result.add_value("resource_type", resource_type)
    result.add_value("operation", operation)
    result.success = true
    
    result.add_log("Gained %d %s" % [final_amount, resource_type])
    
    return result

func get_description(context: EffectContext = null) -> String:
    match operation:
        "add":
            return "Gain %d %s" % [amount, resource_type]
        "subtract":
            return "Lose %d %s" % [amount, resource_type]
        "set":
            return "Set %s to %d" % [resource_type, amount]
        _:
            return "Modify %s by %d" % [resource_type, amount]
```

### Card Effects

```gdscript
# effects/types/card/DrawEffect.gd
extends Effect
class_name DrawEffect

@export var card_filter: String = ""  # "", "attack", "skill", "power"
@export var reveal: bool = false

func _init():
    effect_type = "draw"
    target = "self"

func execute(context: EffectContext) -> EffectResult:
    var result = EffectResult.new()
    result.effect_type = effect_type
    
    if not context.combat_state:
        result.success = false
        result.prevented_by = "not_in_combat"
        return result
    
    var final_amount = amount
    
    result.add_value("cards_drawn", final_amount)
    result.add_value("card_filter", card_filter)
    result.add_value("reveal", reveal)
    result.success = true
    
    result.add_log("Drew %d cards" % final_amount)
    
    return result

func get_description(context: EffectContext = null) -> String:
    var desc = "Draw %d card" % amount
    if amount != 1:
        desc += "s"
    if card_filter != "":
        desc += " (%s)" % card_filter
    return desc
```

## Advanced Effect Types

### Conditional Effects

```gdscript
# effects/types/advanced/ConditionalEffect.gd
extends Effect
class_name ConditionalEffect

@export var condition: String = ""  # "first_card", "hp_below_50", "enemy_stunned"
@export var true_effect: Effect
@export var false_effect: Effect

func _init():
    effect_type = "conditional"

func execute(context: EffectContext) -> EffectResult:
    var condition_met = _check_condition(condition, context)
    var chosen_effect = true_effect if condition_met else false_effect
    
    if chosen_effect:
        return chosen_effect.execute(context)
    else:
        var result = EffectResult.new()
        result.success = true  # Not executing is still success
        return result

func _check_condition(condition_string: String, context: EffectContext) -> bool:
    match condition_string:
        "first_card":
            return context.is_first_card
        "last_card":
            return context.is_last_card
        "hp_below_50":
            return context.player and context.player.get_health_percent() < 0.5
        "enemy_stunned":
            var enemy = context.get_target_by_type("enemy")
            return enemy and enemy.has_method("is_stunned") and enemy.is_stunned()
        _:
            return false

func get_description(context: EffectContext = null) -> String:
    var desc = ""
    if true_effect:
        desc += true_effect.get_description(context)
    if condition != "":
        desc += " (if %s)" % condition.replace("_", " ")
    return desc
```

### Scaling Effects

```gdscript
# effects/types/advanced/ScalingEffect.gd
extends Effect
class_name ScalingEffect

@export var base_effect: Effect
@export var scale_with: String = "missing_hp"  # missing_hp, cards_played, gold, etc.
@export var scale_ratio: float = 1.0

func _init():
    effect_type = "scaling"

func execute(context: EffectContext) -> EffectResult:
    if not base_effect:
        var result = EffectResult.new()
        result.success = false
        result.prevented_by = "no_base_effect"
        return result
    
    # Calculate scaling value
    var scale_value = _get_scale_value(scale_with, context)
    var multiplier = 1.0 + (scale_value * scale_ratio)
    
    # Apply scaling to base effect
    var original_amount = base_effect.amount
    base_effect.amount = int(original_amount * multiplier)
    
    var result = base_effect.execute(context)
    
    # Restore original amount
    base_effect.amount = original_amount
    
    if result.success:
        result.add_log("(scaled by %s: %.1fx)" % [scale_with, multiplier])
    
    return result

func _get_scale_value(scale_type: String, context: EffectContext) -> float:
    match scale_type:
        "missing_hp":
            if context.player:
                return context.player.get_missing_health_percent()
            return 0.0
        "cards_played":
            return context.cards_played_this_turn
        "gold":
            if context.player:
                return context.player.get_resource("gold") * 0.01  # Scale by 1% per gold
            return 0.0
        _:
            return 0.0
```

## Usage Examples

### Card Implementation

```gdscript
# game/cards/Card.gd
extends Resource
class_name Card

@export var name: String = "Card"
@export var cost: int = 1
@export var effects: Array[Effect] = []
@export var description: String = ""

func play(context: EffectContext):
    context.source_type = "card"
    context.source = self
    return EffectProcessor.execute_effects(effects, context)

func get_description() -> String:
    if description != "":
        return description
    
    # Generate description from effects
    var parts: Array[String] = []
    for effect in effects:
        parts.append(effect.get_description())
    
    return ". ".join(parts)

# Example card creation
static func create_basic_attack() -> Card:
    var card = Card.new()
    card.name = "Strike"
    card.cost = 1
    card.effects = [
        DamageEffect.new().set_amount(6).set_target("enemy")
    ]
    return card

static func create_defensive_card() -> Card:
    var card = Card.new()
    card.name = "Defend"
    card.cost = 1
    card.effects = [
        DefenseEffect.new().set_amount(5).set_target("self")
    ]
    return card

static func create_complex_card() -> Card:
    var card = Card.new()
    card.name = "Berserker's Strike"
    card.cost = 2
    
    # Damage that scales with missing health
    var scaling_damage = ScalingEffect.new()
    scaling_damage.base_effect = DamageEffect.new().set_amount(8)
    scaling_damage.scale_with = "missing_hp"
    scaling_damage.scale_ratio = 1.0  # +100% per missing HP percent
    
    card.effects = [scaling_damage]
    return card
```

### Encounter Implementation

```gdscript
# game/encounters/Encounter.gd
extends Resource
class_name Encounter

@export var name: String = "Encounter"
@export var description: String = ""
@export var choices: Array[EncounterChoice] = []

# game/encounters/EncounterChoice.gd
extends Resource
class_name EncounterChoice

@export var text: String = "Choice"
@export var effects: Array[Effect] = []
@export var requirements: Dictionary = {}  # gold >= 50, hp > 10, etc.

func can_choose(context: EffectContext) -> bool:
    # Check requirements
    for req_key in requirements:
        var req_value = requirements[req_key]
        # Implement requirement checking logic
        pass
    return true

func choose(context: EffectContext):
    context.source_type = "encounter"
    context.source = self
    return EffectProcessor.execute_effects(effects, context)

# Example encounter
static func create_treasure_encounter() -> Encounter:
    var encounter = Encounter.new()
    encounter.name = "Old Treasure Chest"
    encounter.description = "You find an old, rusted chest."
    
    # Safe choice: small gold
    var safe_choice = EncounterChoice.new()
    safe_choice.text = "Carefully open the chest"
    safe_choice.effects = [
        ResourceEffect.new().set_param("resource_type", "gold").set_amount(25)
    ]
    
    # Risky choice: more gold but damage
    var risky_choice = EncounterChoice.new()
    risky_choice.text = "Force the chest open"
    risky_choice.effects = [
        ResourceEffect.new().set_param("resource_type", "gold").set_amount(50),
        DamageEffect.new().set_amount(5).set_target("self")
    ]
    
    encounter.choices = [safe_choice, risky_choice]
    return encounter
```

### Curio Implementation

```gdscript
# game/curios/Curio.gd
extends Resource
class_name Curio

@export var name: String = "Curio"
@export var description: String = ""
@export var passive_effects: Array[Effect] = []  # Always active
@export var triggered_effects: Array[Effect] = []  # Triggered by events
@export var trigger_conditions: Array[String] = []  # When triggered effects activate

func get_description() -> String:
    if description != "":
        return description
    
    var parts: Array[String] = []
    
    # Add passive effects
    for effect in passive_effects:
        parts.append(effect.get_description())
    
    # Add triggered effects with conditions
    for i in range(triggered_effects.size()):
        var effect_desc = triggered_effects[i].get_description()
        if i < trigger_conditions.size():
            effect_desc += " (%s)" % trigger_conditions[i]
        parts.append(effect_desc)
    
    return ". ".join(parts)

# Example curio
static func create_healing_pendant() -> Curio:
    var curio = Curio.new()
    curio.name = "Healing Pendant"
    
    # Heal at start of each turn
    curio.triggered_effects = [
        HealEffect.new().set_amount(2).set_target("self")
    ]
    curio.trigger_conditions = ["turn_start"]
    
    return curio

static func create_lucky_coin() -> Curio:
    var curio = Curio.new()
    curio.name = "Lucky Coin"
    
    # Passive: +10% crit chance
    # This would be handled by the context system adding crit_chance modifier
    curio.description = "Increases critical hit chance by 10%"
    
    return curio
```

## Implementation Timeline

### Day 1: Core Foundation
1. Create project structure
2. Implement Effect, EffectContext, EffectResult base classes
3. Create EffectProcessor singleton
4. Set up basic autoloads and project settings

### Day 2: Basic Effect Types
1. Implement DamageEffect, HealEffect, DefenseEffect
2. Implement ResourceEffect (gold, energy)
3. Create simple test scenes to verify effects work
4. Test effect chaining and context passing

### Day 3: Card System Integration
1. Create Card resource class
2. Implement card playing mechanics
3. Create 10 basic test cards using effects
4. Test card effects in combat scenarios

### Day 4: Encounter & Curio Systems
1. Create Encounter and EncounterChoice classes
2. Create Curio class with passive/triggered effects
3. Test cross-system effect compatibility
4. Ensure same effects work in all contexts

### Day 5: Advanced Features
1. Implement ConditionalEffect and ScalingEffect
2. Add more sophisticated effect types as needed
3. Create complex cards/encounters showcasing advanced effects
4. Polish and bug-fix

## Testing Strategy

### Unit Testing
```gdscript
# Test individual effects
func test_damage_effect():
    var damage = DamageEffect.new().set_amount(10)
    var context = EffectContext.new()
    var result = damage.execute(context)
    assert(result.success)
    assert(result.get_value("damage_dealt") == 10)

# Test effect combinations
func test_effect_chain():
    var effects = [
        DamageEffect.new().set_amount(5),
        HealEffect.new().set_amount(3)
    ]
    var context = EffectContext.new()
    var results = EffectProcessor.execute_effects(effects, context)
    assert(results.size() == 2)
    assert(results[0].get_value("damage_dealt") == 5)
    assert(results[1].get_value("health_restored") == 3)
```

### Integration Testing
- Test cards with multiple effects
- Test encounters with complex choice trees
- Test curios with triggered effects
- Test cross-system interactions (card triggering curio effect)

### Performance Testing
- Benchmark effect execution with large numbers of effects
- Test memory usage with many active persistent effects
- Profile effect resolution during complex combat scenarios

## Extension Guidelines

### Adding New Effect Types
1. Extend Effect base class
2. Override execute() method
3. Add result application to EffectProcessor._apply_result()
4. Create tests for the new effect type
5. Update documentation

### Adding New Context Types
1. Extend EffectContext for specific use cases
2. Add context creation helpers
3. Update EffectProcessor to handle new contexts
4. Test compatibility with existing effects

### Adding New Trigger Types
1. Define trigger constants
2. Add trigger detection logic
3. Update curio/status effect systems to respond to triggers
4. Test trigger timing and order

This system provides a solid foundation for a clean, extensible effect system that can grow with your game's complexity while maintaining consistency across all game systems.