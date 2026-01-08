# Curio Creation Guide

## Overview

Curios are persistent artifacts that provide lasting effects throughout a run. This guide explains how to create new curios using the template system.

## Quick Start

1. Copy `template_curio.tres` to the appropriate rarity folder
2. Rename it to match your curio (e.g., `lucky_nugget.tres`)
3. Edit the fields according to your curio's design
4. Attach appropriate effect resources
5. Test using the debug commands

## Directory Structure

```
data/curios/
├── common/       # Common rarity curios (gray)
├── rare/         # Rare rarity curios (cyan)
├── legendary/    # Legendary rarity curios (gold)
├── corrupted/    # Corrupted rarity curios (purple)
└── template_curio.tres  # Template for new curios
```

## Creating a New Curio

### Step 1: Choose the Right Effect Type

Available effect scripts in `scripts/curios/effects/`:
- **ResourceGain.gd**: Add/remove resources (gold, energy, cards, health, sanity, defense)
- **StatModifier.gd**: Modify player stats (max health, max energy, etc.)
- **CardModifier.gd**: Change card behavior (cost, damage, effects)

### Step 2: Set Trigger Events

Common trigger events:
- `"passive"` - Always active
- `"combat_start"` - When combat begins
- `"turn_start"` - Start of each turn
- `"turn_end"` - End of each turn
- `"card_played"` - When any card is played
- `"damage_dealt"` - When dealing damage
- `"damage_taken"` - When taking damage
- `"enemy_defeated"` - When an enemy dies
- `"combat_end"` - When combat ends
- `"shop_entered"` - When entering a shop
- `"node_selected"` - When choosing a map node

### Step 3: Configure Properties

#### Rarity Guidelines
- **Common**: Simple effects, 5-15% power increase
- **Rare**: Complex effects, 15-30% power increase
- **Legendary**: Run-defining, 30-50% power increase
- **Corrupted**: 40-60% power with major drawback

#### Class Synergy Scores
- **0.5-0.8**: Poor synergy (anti-synergistic)
- **0.9-1.1**: Neutral synergy
- **1.2-1.5**: Good synergy
- **1.6-2.0**: Excellent synergy

Classes:
- **Bushranger**: Attack-focused, aggressive
- **Prospector**: Resource management, gold generation
- **Tracker**: Defensive, setup-based
- **Publican**: Support, healing

#### Gold Costs by Rarity
- **Common**: 50-150 gold
- **Rare**: 150-300 gold
- **Legendary**: 300-500 gold
- **Corrupted**: 100-200 gold (+ corruption cost)

### Step 4: Add Multiple Effects (Optional)

To add multiple effects to a curio:

1. Add additional ExtResource declarations
2. Create additional SubResource blocks
3. Add all SubResources to the effects array

Example:
```gdscript
effects = [SubResource("SubResource_1"), SubResource("SubResource_2")]
```

## Example: Creating Lucky Nugget

1. Copy `template_curio.tres` to `common/lucky_nugget.tres`
2. Edit the following fields:
```
curio_name = "Lucky Nugget"
description = "+3 gold at the start of each combat"
flavor_text = "A small gold nugget that seems to attract wealth wherever you go."
mechanical_category = "Resource"
rarity = "Common"
stackable = true
max_stacks = 3
gold_cost = 100

# In the effect SubResource:
effect_name = "Gold Bonus"
trigger_event = "combat_start"
resource_type = "gold"
amount = 3

# Class synergies:
bushranger_synergy = 1.0
prospector_synergy = 1.3  # Good for gold-focused Prospector
tracker_synergy = 1.0
publican_synergy = 1.2
```

## Testing Curios

### Debug Commands

In the debug console or through CurioManager:
```gdscript
# Add a curio to player
CurioManager.debug_add_curio("Lucky Nugget")

# List all active curios
CurioManager.debug_list_curios()

# Remove a curio
CurioManager.remove_curio(curio_resource)
```

### Test Checklist

- [ ] Curio appears in reward pool
- [ ] Effect triggers at correct time
- [ ] Stacking works if applicable
- [ ] Visual feedback shows on trigger
- [ ] Persists between combats
- [ ] Saves/loads correctly
- [ ] Class synergies affect drop rates

## Common Issues

### Curio Not Loading
- Check file path in ExtResource declarations
- Verify script_class matches ("CurioData")
- Ensure .tres file is in correct rarity folder

### Effect Not Triggering
- Verify trigger_event matches EventBus signal
- Check CurioManager event connections
- Ensure effect's can_trigger() returns true

### Stacking Not Working
- Set stackable = true
- Set max_stacks > 1
- Verify curio_name matches exactly for stacking

## Adding New Effect Types

To create a new effect type:

1. Create new script extending CurioEffect in `scripts/curios/effects/`
2. Override `apply_effect()` method
3. Override `can_trigger()` if needed
4. Add any custom export variables
5. Use in curio .tres files

Example custom effect:
```gdscript
extends CurioEffect
class_name LifestealEffect

@export var lifesteal_percent: float = 0.1

func apply_effect(game_state: Node, curio_data: Resource, context: Dictionary) -> void:
    var damage = context.get("damage_dealt", 0)
    var heal_amount = int(damage * lifesteal_percent)
    # Heal player for percentage of damage dealt
    var player = game_state.get_player_data()
    if player:
        player.heal(heal_amount)
```

## Best Practices

1. **Keep effects simple and clear** - Players should understand what a curio does at a glance
2. **Test stacking behavior** - Ensure stacked effects don't become overpowered
3. **Consider class balance** - Each class should have some curios with good synergy
4. **Use appropriate triggers** - Match trigger frequency to effect power
5. **Document unlock conditions** - If a curio has special requirements, make them clear
6. **Playtest thoroughly** - Curios affect entire runs, so balance is crucial

## Reference: All 40 Curios

See `docs/CURIOS_CATALOG.md` for the complete list of planned curios with their properties and effects.