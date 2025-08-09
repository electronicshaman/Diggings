# Card Effect Template

## Effect System Overview

Card effects are modular, reusable components that define what cards actually do when played. Each effect is a separate GDScript class extending `CardEffect` base class.

## Basic Effect Structure

### Required Components

```gdscript
extends Resource
class_name [EffectName]

# Core properties every effect needs
@export var effect_name: String = "[Effect Name]"
@export var description: String = "[Description template with %s placeholders]"

# Effect-specific parameters
@export var [parameter_name]: [Type] = [default_value]

# Core method that executes the effect
func apply_effect(context: Dictionary) -> Dictionary:
    # Implementation here
    return context  # Return modified context
```

### Context Dictionary
The context contains all game state information needed for effects:

```gdscript
context = {
    "player_data": PlayerData,      # Player stats and resources
    "enemy_data": EnemyData,        # Enemy stats and state
    "duel_state": DuelState,        # Combat state
    "card_played": CardData,        # The card that triggered this effect
    "target": Node,                 # Target of the effect (if any)
    "source": Node,                 # Source of the effect
    "modifications": {},            # Temporary modifiers
    "events": []                    # Events to broadcast after resolution
}
```

## Effect Categories

### 1. Damage Effects

**Purpose**: Deal direct harm to targets

```gdscript
extends Resource
class_name Damage

@export var effect_name: String = "Damage"
@export var description: String = "Deal %s damage"
@export var damage_amount: int = 1
@export var ignores_defense: bool = false
@export var damage_type: String = "physical"  # physical, mental, corruption

func apply_effect(context: Dictionary) -> Dictionary:
    var target = context.get("target", context.get("enemy_data"))
    var actual_damage = damage_amount
    
    # Apply defense if not ignoring
    if not ignores_defense and target.has_method("get_defense"):
        actual_damage = max(0, actual_damage - target.get_defense())
    
    # Deal the damage
    if target.has_method("take_damage"):
        target.take_damage(actual_damage, damage_type)
    
    # Add event for UI/effects
    context.events.append({
        "type": "damage_dealt",
        "amount": actual_damage,
        "target": target,
        "damage_type": damage_type
    })
    
    return context
```

### 2. Defense Effects

**Purpose**: Provide protection and damage reduction

```gdscript
extends Resource  
class_name Defense

@export var effect_name: String = "Defense"
@export var description: String = "Gain %s block"
@export var defense_amount: int = 1
@export var duration: int = 1  # turns, -1 for permanent
@export var stacks: bool = true  # whether multiple applications stack

func apply_effect(context: Dictionary) -> Dictionary:
    var target = context.get("target", context.get("player_data"))
    
    if target.has_method("gain_defense"):
        target.gain_defense(defense_amount, duration, stacks)
    
    context.events.append({
        "type": "defense_gained", 
        "amount": defense_amount,
        "target": target
    })
    
    return context
```

### 3. Resource Effects

**Purpose**: Modify player resources (health, sanity, energy, gold)

```gdscript
extends Resource
class_name Heal

@export var effect_name: String = "Heal"  
@export var description: String = "Restore %s health"
@export var heal_amount: int = 1
@export var heal_type: String = "health"  # health, sanity, energy
@export var percentage_based: bool = false  # heal % of max instead of flat
@export var overheal_allowed: bool = false

func apply_effect(context: Dictionary) -> Dictionary:
    var target = context.get("target", context.get("player_data"))
    var actual_heal = heal_amount
    
    # Calculate percentage healing if needed
    if percentage_based:
        var max_value = target.get("max_" + heal_type, 100)
        actual_heal = int(max_value * (heal_amount / 100.0))
    
    # Apply healing
    match heal_type:
        "health":
            if target.has_method("heal_health"):
                target.heal_health(actual_heal, overheal_allowed)
        "sanity":
            if target.has_method("restore_sanity"):
                target.restore_sanity(actual_heal, overheal_allowed)
        "energy":
            if target.has_method("gain_energy"):
                target.gain_energy(actual_heal)
    
    context.events.append({
        "type": "healing_applied",
        "heal_type": heal_type,
        "amount": actual_heal,
        "target": target
    })
    
    return context
```

### 4. Card Manipulation Effects

**Purpose**: Draw cards, modify hand/deck, generate cards

```gdscript
extends Resource
class_name Draw

@export var effect_name: String = "Draw"
@export var description: String = "Draw %s card(s)"  
@export var draw_amount: int = 1
@export var specific_type: String = ""  # Filter by card type
@export var from_pile: String = "deck"  # deck, discard, any

func apply_effect(context: Dictionary) -> Dictionary:
    var duel_state = context.get("duel_state")
    
    if not duel_state or not duel_state.has_method("draw_cards"):
        return context
    
    var drawn_cards = []
    
    for i in range(draw_amount):
        var card = null
        
        # Apply filters if specified
        if specific_type.length() > 0:
            card = duel_state.draw_card_of_type(specific_type, from_pile)
        else:
            card = duel_state.draw_card(from_pile)
            
        if card:
            drawn_cards.append(card)
    
    context.events.append({
        "type": "cards_drawn",
        "cards": drawn_cards,
        "amount": drawn_cards.size()
    })
    
    return context
```

### 5. Fortune/Gambling Effects

**Purpose**: Variable outcomes, risk/reward mechanics

```gdscript
extends Resource
class_name Gambling

@export var effect_name: String = "Gambling"
@export var description: String = "Take a risk for potential reward"
@export var success_chance: float = 0.5  # 0.0 to 1.0
@export var success_effects: Array[CardEffect] = []
@export var failure_effects: Array[CardEffect] = []
@export var modifier_source: String = ""  # What can modify the odds

func apply_effect(context: Dictionary) -> Dictionary:
    var actual_chance = success_chance
    
    # Apply modifiers from context
    if context.has("gambling_bonus"):
        actual_chance += context.gambling_bonus
    
    # Check for class-specific modifiers
    var player = context.get("player_data")
    if player and player.has_method("get_fortune_bonus"):
        actual_chance += player.get_fortune_bonus()
    
    # Clamp to valid range
    actual_chance = clamp(actual_chance, 0.0, 1.0)
    
    # Roll the dice
    var roll = randf()
    var success = roll <= actual_chance
    
    # Apply appropriate effects
    var effects_to_apply = success_effects if success else failure_effects
    
    for effect in effects_to_apply:
        if effect and effect.has_method("apply_effect"):
            context = effect.apply_effect(context)
    
    context.events.append({
        "type": "gambling_resolved",
        "success": success,
        "roll": roll,
        "required": actual_chance,
        "effects_applied": effects_to_apply.size()
    })
    
    return context
```

## Advanced Effect Types

### Conditional Effects

Effects that only trigger under certain conditions:

```gdscript
@export var condition_type: String = "player_health"
@export var condition_operator: String = "less_than"  # less_than, greater_than, equals
@export var condition_value: int = 50
@export var conditional_bonus: int = 0

func check_condition(context: Dictionary) -> bool:
    var target_value = get_condition_value(context, condition_type)
    
    match condition_operator:
        "less_than":
            return target_value < condition_value
        "greater_than":  
            return target_value > condition_value
        "equals":
            return target_value == condition_value
        _:
            return false
```

### Multi-Effect Combinations

Effects that apply multiple sub-effects:

```gdscript
extends Resource
class_name ComboEffect

@export var sub_effects: Array[CardEffect] = []
@export var apply_all: bool = true  # false = choose one randomly

func apply_effect(context: Dictionary) -> Dictionary:
    if apply_all:
        for effect in sub_effects:
            if effect:
                context = effect.apply_effect(context)
    else:
        if sub_effects.size() > 0:
            var chosen = sub_effects[randi() % sub_effects.size()]
            context = chosen.apply_effect(context)
    
    return context
```

## Implementation Guidelines

### 1. Effect Creation Process

1. **Identify Core Function**: What does this effect do fundamentally?
2. **Define Parameters**: What values need to be configurable?
3. **Handle Edge Cases**: What happens with invalid targets/states?
4. **Add Events**: What UI/audio feedback should trigger?
5. **Test Thoroughly**: Verify effect works in various scenarios

### 2. Naming Conventions

```
Class Names: PascalCase (Damage, DefenseBonus, CardDraw)
File Names: PascalCase.gd (Damage.gd, DefenseBonus.gd) 
Variables: snake_case (damage_amount, success_chance)
```

### 3. Parameter Guidelines

- **Keep parameters simple**: Avoid complex nested structures
- **Use sensible defaults**: Effect should work with minimal configuration
- **Add validation**: Check for valid ranges and types
- **Document clearly**: Description should explain what each parameter does

### 4. Context Usage

- **Don't modify context directly**: Return modified version instead
- **Check for required data**: Verify needed objects exist before using
- **Handle missing data gracefully**: Fail safely if context is incomplete
- **Add meaningful events**: UI needs to know what happened

## Quality Checklist

Before finalizing an effect:

- [ ] **Clear Purpose**: Effect has single, well-defined responsibility
- [ ] **Proper Validation**: Handles invalid inputs gracefully  
- [ ] **Event Generation**: Appropriate events for UI feedback
- [ ] **Context Safety**: Doesn't break if context missing data
- [ ] **Performance**: Efficient implementation without unnecessary computation
- [ ] **Testable**: Can be tested in isolation
- [ ] **Documentation**: Clear description and parameter explanations
- [ ] **Integration**: Works properly with existing effect system

## Example: Complete Effect Implementation

```gdscript
# File: scripts/cards/effects/ExplosiveDamage.gd
extends Resource
class_name ExplosiveDamage

@export var effect_name: String = "Explosive Damage"
@export var description: String = "Deal %s damage. If target dies, deal %s damage to self."
@export var primary_damage: int = 12
@export var self_damage: int = 3
@export var damage_type: String = "explosive"

func apply_effect(context: Dictionary) -> Dictionary:
    var target = context.get("enemy_data")
    var player = context.get("player_data")
    
    if not target or not player:
        GLog.error("ExplosiveDamage: Missing required targets")
        return context
    
    # Deal primary damage
    var initial_health = target.current_health
    
    if target.has_method("take_damage"):
        target.take_damage(primary_damage, damage_type)
    
    context.events.append({
        "type": "damage_dealt",
        "amount": primary_damage, 
        "target": target,
        "damage_type": damage_type
    })
    
    # Check if target died from the damage
    var target_died = target.current_health <= 0 and initial_health > 0
    
    if target_died and player.has_method("take_damage"):
        player.take_damage(self_damage, damage_type)
        
        context.events.append({
            "type": "damage_dealt",
            "amount": self_damage,
            "target": player, 
            "damage_type": damage_type,
            "source": "explosive_recoil"
        })
    
    return context

# Override to provide dynamic description
func get_formatted_description() -> String:
    return description % [primary_damage, self_damage]
```

This effect demonstrates proper structure, validation, event generation, and clear documentation while providing interesting gameplay mechanics.