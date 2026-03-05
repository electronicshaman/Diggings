# Character-Card Relationship Architecture

Last verified: 2025-08-18

## Overview

This document describes the implemented system for managing relationships between character classes and cards in the card battler prototype.

## Implementation Status: ✅ Complete

### Core Components

#### 1. CharacterClass Resource (`scripts/characters/character_class.gd`)

The `CharacterClass` resource defines everything about a playable character:

```gdscript
extends Resource
class_name CharacterClass

# Character identity and stats
@export_group("Character Identity")
@export var character_class_name: String
@export var mechanical_specialization: String  # Attack/Skill/Power/Fortune
@export var difficulty_rating: int  # 1-4 difficulty scale

@export_group("Starting Stats")
@export var base_health: int
@export var base_sanity: int
@export var base_energy: int
@export var starting_gold: int

# Mechanics and abilities
@export_group("Class Mechanics")
@export var passive_abilities: Array[String]
@export var active_abilities: Array[String]
@export var unique_resources: Array[String]  # e.g., "Ammo", "Brew Tokens"

# Card accessibility rules
@export_group("Card Access")
@export var class_exclusive_cards: Array[String]
@export var preferred_card_types: Array[String]
@export var forbidden_card_types: Array[String]
```

#### 2. CardData Resource Updates (scripts/cards/CardData.gd)

Cards now include class affinity information:

```gdscript
# Character class relationships
@export_group("Class Accessibility")
@export var class_affinity: Array[String] = []  # Empty = all classes
@export var accessibility_tier: String = "Neutral"  # Starting/Class/Neutral/Rare
@export var mechanical_category: String = "Attack"  # Attack/Skill/Power/Fortune
```

### Card Accessibility Tiers

1. **Starting Cards** (`accessibility_tier = "Starting"`)
   - Appear in character starting decks
   - Usually basic, fundamental cards
   - Balanced for early game

2. **Class Cards** (`accessibility_tier = "Class"`)
   - Character-specific cards found during runs
   - Synergize with class mechanics
   - Often more powerful than neutral cards

3. **Neutral Cards** (`accessibility_tier = "Neutral"`)
   - Available to all characters
   - Provide universal utility
   - Fill gaps in class specializations

4. **Rare Cards** (`accessibility_tier = "Rare"`)
   - Special cards with limited availability
   - May require specific conditions to obtain
   - Often game-changing effects

### Class Affinity System

#### How It Works

1. **Card Perspective**: Each card has a `class_affinity` array
   - Empty array = available to all classes
   - Populated array = only available to listed classes

2. **Character Perspective**: Each character has:
   - `class_exclusive_cards`: Names of cards only they can use
   - `preferred_card_types`: Theme types they favor (e.g., "Gold", "Grit")
   - `forbidden_card_types`: Theme types they cannot use

3. **Compatibility Check**:
 
```gdscript
# In CharacterClass
func can_use_card(card_data: CardData) -> bool:
    # Check if card is forbidden
    if card_data.card_type in forbidden_card_types:
        return false
    
    # Check class affinity
    if card_data.has_method("get_class_affinity"):
        var affinity = card_data.get_class_affinity()
        if affinity.size() > 0 and not character_class_name in affinity:
            return false
    
    return true
```

### Implemented Character Classes

All four character classes have been created as resource files in `data/characters/`:

| Class | File | Specialization | Starting Stats | Unique Mechanics |
|-------|------|---------------|----------------|------------------|
| **Bushranger** | `bushranger.tres` | Attack | 55 HP, 90 San, 10 Gold | Ammo system, Outlaw's Edge, Quick Draw |
| **Prospector** | `prospector.tres` | Fortune | 45 HP, 110 San, 25 Gold | Gold Rush, Risk Tolerance, Fortune Streak |
| **Tracker** | `tracker.tres` | Skill | 50 HP, 105 San, 15 Gold | Setup Counter, Pathfinding, Sacred Knowledge |
| **Publican** | `publican.tres` | Power | 50 HP, 95 San, 20 Gold | Brew Tokens, Social Hub, House Advantage |

Note: `data/decks/character/` currently has no deck resource files. Starting decks are resolved via `starting_deck_paths` on `CharacterClass` until deck resources are added.

### Card Weight System

Characters calculate preferences for card rewards:

```gdscript
func get_card_preference_weight(card_data: CardData) -> float:
    if not can_use_card(card_data):
        return 0.0
    
    # Class exclusive cards have highest weight
    if card_data.card_name in class_exclusive_cards:
        return 3.0
    
    # Preferred types get bonus weight
    if card_data.card_type in preferred_card_types:
        return 2.0
    
    # Matching mechanical specialization
    if card_data.get_mechanical_category() == mechanical_specialization:
        return 1.5
    
    return 1.0  # Default neutral weight
```

## Integration Points

### 1. Character Selection

When a player selects a character:

- Load the CharacterClass resource
- Build starting deck from `starting_deck` array
- Apply starting stat modifiers
- Initialize unique resources (Ammo, Brew Tokens, etc.)

### 2. Card Rewards

When generating card rewards:

- Filter cards by `can_use_card()`
- Weight selection by `get_card_preference_weight()`
- Respect accessibility tiers
- Consider current deck composition

### 3. Shop Systems

Shops should:

- Only offer cards the character can use
- Price cards based on character preferences
- Potentially offer class-specific discounts

### 4. Card Display

UI should indicate:

- Class-exclusive cards with special borders/icons
- Neutral vs class cards
- Cards that synergize with character abilities

## Future Enhancements

### Planned Features

1. **Character Progression**: Unlock new class cards through play
2. **Cross-Class Synergies**: Cards that work specially with multiple classes
3. **Dynamic Affinities**: Cards that change affinity based on conditions
4. **Class Mastery**: Improve card weights through repeated play

### Potential Expansions

1. **Hybrid Classes**: Characters that blend two specializations
2. **Corrupted Variants**: Dark versions of class cards
3. **Legendary Class Cards**: Ultra-rare class-specific cards
4. **Class Challenges**: Special runs that unlock new cards

## Best Practices

### When Adding New Cards

1. Decide accessibility tier (Starting/Class/Neutral/Rare)
2. Set appropriate class_affinity array
3. Assign mechanical_category for theme-agnostic systems
4. Test with all character classes for balance

### When Creating New Characters

1. Define clear mechanical identity
2. Set balanced starting statistics
3. Create unique ability combinations
4. Establish card pool relationships
5. Write flavorful descriptions and quotes

### Balancing Considerations

- Class cards should be ~20% stronger than neutral equivalents
- Starting decks should enable basic strategy immediately
- Each class needs viable paths to victory
- Cross-class cards should never be mandatory

This system creates meaningful character identity while maintaining flexibility for deck building and strategic diversity.
