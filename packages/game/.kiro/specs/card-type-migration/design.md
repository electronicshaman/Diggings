# Design Document: Card Type Migration

## Overview

This design describes the migration from the legacy theme-specific card type naming (Gold/Grit/Grog/Gamble) to a unified mechanical category system (Attack/Skill/Power/Fortune). The migration consolidates the dual `card_type` and `mechanical_category` fields into a single `card_type` field using mechanical category values, while preserving theme-specific display through the ThemeManager.

The key architectural principle is **separation of concerns**: mechanical behavior is defined by the card type, while visual presentation (colors, symbols, display names) is handled by the theme layer.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   CardUI    │  │  Card.gd    │  │  CardPile   │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                      │
│         └────────────────┼────────────────┘                      │
│                          ▼                                       │
│                  ┌───────────────┐                               │
│                  │ ThemeManager  │  ← Theme-specific display     │
│                  │ get_card_color│    names, colors, symbols     │
│                  │ get_card_symbol│                              │
│                  │ get_display_name│                             │
│                  └───────────────┘                               │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  CardData   │  │ PlayerData  │  │CharacterClass│             │
│  │ card_type:  │  │ attack_cost │  │preferred_   │              │
│  │ "Attack"    │  │ skill_cost  │  │card_types   │              │
│  │ "Skill"     │  │ power_cost  │  │             │              │
│  │ "Power"     │  │ fortune_cost│  │             │              │
│  │ "Fortune"   │  │             │  │             │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### CardData Resource (Modified)

```gdscript
extends Resource
class_name CardData

# Card type using mechanical categories only
@export var card_type: String = "Attack"  # Attack/Skill/Power/Fortune

# REMOVED: mechanical_category field (consolidated into card_type)

# Helper method for type checking
func get_card_type() -> String:
    return card_type

func is_attack() -> bool:
    return card_type == "Attack"

func is_skill() -> bool:
    return card_type == "Skill"

func is_power() -> bool:
    return card_type == "Power"

func is_fortune() -> bool:
    return card_type == "Fortune"
```

### ThemeManager (Modified)

```gdscript
extends Node

# Valid mechanical categories
const VALID_CARD_TYPES: Array[String] = ["Attack", "Skill", "Power", "Fortune"]

# Theme-specific display name mapping
static func get_card_display_name(card_type: String, theme: String = "the_rush") -> String:
    if theme == "the_rush":
        match card_type:
            "Attack": return "Gold"
            "Skill": return "Grit"
            "Power": return "Grog"
            "Fortune": return "Gamble"
    return card_type  # Fallback to mechanical name

# Card colors based on mechanical type
static func get_card_color(card_type: String) -> Color:
    match card_type:
        "Attack": return Color(0.831, 0.686, 0.216)  # Gold
        "Skill": return Color(0.545, 0.271, 0.075)   # Brown
        "Power": return Color(0.722, 0.525, 0.043)   # Amber
        "Fortune": return Color(0.133, 0.545, 0.133) # Green
        _: return Color.WHITE

# Card symbols based on mechanical type
static func get_card_symbol(card_type: String) -> String:
    match card_type:
        "Attack": return "🔫"
        "Skill": return "🛡"
        "Power": return "🍺"
        "Fortune": return "🎲"
        _: return "?"

# Validation helper
static func is_valid_card_type(card_type: String) -> bool:
    return card_type in VALID_CARD_TYPES
```

### PlayerData (Modified)

```gdscript
# Renamed cost reduction fields
@export var attack_cost_reduction: int = 0
@export var attack_cost_reduction_duration: int = 0
@export var skill_cost_reduction: int = 0      # Was: grit_cost_reduction
@export var skill_cost_reduction_duration: int = 0
@export var power_cost_reduction: int = 0      # Was: grog_cost_reduction
@export var power_cost_reduction_duration: int = 0
@export var fortune_cost_reduction: int = 0    # Was: gamble_cost_reduction
@export var fortune_cost_reduction_duration: int = 0

func get_actual_energy_cost(base_cost: int, card_type: String) -> int:
    if next_card_free:
        return 0
    
    var final_cost = base_cost
    
    if all_cost_reduction_duration > 0:
        final_cost -= all_cost_reduction
    
    match card_type:
        "Attack":
            if attack_cost_reduction_duration > 0:
                final_cost -= attack_cost_reduction
        "Skill":
            if skill_cost_reduction_duration > 0:
                final_cost -= skill_cost_reduction
        "Power":
            if power_cost_reduction_duration > 0:
                final_cost -= power_cost_reduction
        "Fortune":
            if fortune_cost_reduction_duration > 0:
                final_cost -= fortune_cost_reduction
    
    return max(0, final_cost)
```

### CardPile (Modified)

```gdscript
func sort_by_type() -> void:
    var type_order: Dictionary = {
        "Attack": 0,
        "Skill": 1,
        "Power": 2,
        "Fortune": 3
    }
    cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
        return type_order.get(a.get_card_type(), 99) < type_order.get(b.get_card_type(), 99)
    )
```

### GameConstants (Modified)

```gdscript
# REMOVED: THEME_NAMES dictionary
# REMOVED: get_themed_card_type_name() - use ThemeManager.get_card_display_name()

# CardType enum remains for type-safe code paths
enum CardType {
    ATTACK,
    SKILL,
    POWER,
    FORTUNE
}

# Convert enum to string
static func card_type_to_string(card_type: CardType) -> String:
    match card_type:
        CardType.ATTACK: return "Attack"
        CardType.SKILL: return "Skill"
        CardType.POWER: return "Power"
        CardType.FORTUNE: return "Fortune"
        _: return "Attack"

# Convert string to enum
static func string_to_card_type(type_string: String) -> CardType:
    match type_string:
        "Attack": return CardType.ATTACK
        "Skill": return CardType.SKILL
        "Power": return CardType.POWER
        "Fortune": return CardType.FORTUNE
        _: return CardType.ATTACK
```

## Data Models

### Card Type Values

| Mechanical Category | Theme Display (the_rush) | Color | Symbol |
|---------------------|--------------------------|-------|--------|
| Attack | Gold | #D4AF37 | 🔫 |
| Skill | Grit | #8B4513 | 🛡 |
| Power | Grog | #B8860B | 🍺 |
| Fortune | Gamble | #228B22 | 🎲 |

### Migration Mapping

| Legacy Value | New Value |
|--------------|-----------|
| Gold | Attack |
| Grit | Skill |
| Grog | Power |
| Gamble | Fortune |
| Lead | Attack |
| Leather | Skill |
| Liquor | Power |
| Luck | Fortune |
| Faith | Fortune (special case) |

### Resource File Changes

**Card .tres files:**
- Change `card_type = "Gold"` → `card_type = "Attack"`
- Remove `mechanical_category` field

**Character .tres files:**
- Change `preferred_card_types = Array[String](["Gold"])` → `preferred_card_types = Array[String](["Attack"])`

**Deck .tres files:**
- Change `priority_card_types` to use mechanical values

**Curio .tres files:**
- Change `target_card_type` to use mechanical values (lowercase: "attack", "skill", "power", "fortune")



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Valid Card Type Constraint

*For any* CardData resource, the `card_type` field SHALL contain one of the four valid mechanical category values: "Attack", "Skill", "Power", or "Fortune".

**Validates: Requirements 1.1**

### Property 2: Card Type Validation Rejects Legacy Values

*For any* string from the set {"Gold", "Grit", "Grog", "Gamble", "Lead", "Leather", "Liquor", "Luck"}, the `ThemeManager.is_valid_card_type()` function SHALL return false.

**Validates: Requirements 1.4**

### Property 3: Theme Display Name Mapping

*For any* valid card type and any theme string, the `ThemeManager.get_card_display_name()` function SHALL return a non-empty string. For the "the_rush" theme, it SHALL return the themed name; for unknown themes, it SHALL return the mechanical category name unchanged.

**Validates: Requirements 2.1, 2.5**

### Property 4: ThemeManager Returns Valid Visuals for All Card Types

*For any* valid card type ("Attack", "Skill", "Power", "Fortune"), the ThemeManager SHALL return a non-white color from `get_card_color()` and a non-"?" symbol from `get_card_symbol()`.

**Validates: Requirements 2.3, 2.4**

### Property 5: Cost Reduction Calculation Correctness

*For any* PlayerData with cost reductions set, and *for any* card with a base energy cost and card type, the `get_actual_energy_cost()` function SHALL return a value that is:
- 0 if `next_card_free` is true
- Otherwise, `max(0, base_cost - applicable_reductions)` where applicable_reductions includes all_cost_reduction (if duration > 0) plus the type-specific reduction (if duration > 0)

**Validates: Requirements 3.4**

### Property 6: Character Class Card Type References Are Valid

*For any* CharacterClass resource, all values in `preferred_card_types` and `forbidden_card_types` arrays SHALL be valid mechanical category values ("Attack", "Skill", "Power", "Fortune").

**Validates: Requirements 4.1, 4.2**

### Property 7: Card Availability Check Uses Mechanical Categories

*For any* CharacterClass and *for any* CardData, the card availability check SHALL correctly determine availability based on comparing `card_data.card_type` against the class's `forbidden_card_types` and `preferred_card_types` using mechanical category values.

**Validates: Requirements 4.3**

### Property 8: All Resource Files Use Valid Card Types

*For any* loaded CardData, DeckData, or CurioData resource, all card type references SHALL contain valid mechanical category values.

**Validates: Requirements 5.1, 6.1, 6.2**

### Property 9: Card Pile Sort Order Invariant

*For any* CardPile after calling `sort_by_type()`, the cards SHALL be ordered such that all Attack cards come before Skill cards, all Skill cards come before Power cards, and all Power cards come before Fortune cards.

**Validates: Requirements 7.1, 7.2**

### Property 10: Card Type Filtering Correctness

*For any* CardPile and *for any* valid card type, the `get_cards_by_type()` function SHALL return only cards whose `card_type` matches the requested type, and SHALL return all such cards in the pile.

**Validates: Requirements 6.3**

## Error Handling

### Invalid Card Type Values

When an invalid card type value is encountered:
1. `ThemeManager.is_valid_card_type()` returns `false`
2. `ThemeManager.get_card_color()` returns `Color.WHITE` as fallback
3. `ThemeManager.get_card_symbol()` returns `"?"` as fallback
4. `ThemeManager.get_card_display_name()` returns the input string unchanged

### Missing or Null Card Data

When card data is missing or null:
1. `CardInstance.get_card_type()` returns empty string `""`
2. Cost calculations treat unknown types as having no type-specific reduction
3. Sorting places cards with unknown types at the end (sort order 99)

### Resource Loading Failures

When a .tres file fails to load or has invalid data:
1. Log warning via GLog.warn()
2. Skip the invalid resource
3. Continue processing remaining resources

## Testing Strategy

### Unit Tests

Unit tests will verify specific examples and edge cases:

1. **CardData Default Value**: Verify new CardData has `card_type = "Attack"`
2. **Theme Display Mapping**: Verify each mechanical category maps to correct themed name
3. **Migration Mapping**: Verify Gold→Attack, Grit→Skill, Grog→Power, Gamble→Fortune
4. **Cost Calculation Edge Cases**: Test with zero cost, max cost, multiple reductions active

### Property-Based Tests

Property-based tests will use GdUnit4 with random input generation:

1. **Valid Card Type Property**: Generate random CardData, verify card_type is valid
2. **Legacy Value Rejection**: Generate legacy values, verify validation fails
3. **Cost Reduction Property**: Generate random costs and reductions, verify calculation
4. **Sort Order Property**: Generate random card piles, verify sort order after sorting
5. **Filter Correctness Property**: Generate random piles and types, verify filter results

### Integration Tests

Integration tests will verify the migration doesn't break existing functionality:

1. **Card Loading**: Load all card .tres files, verify they have valid card_type
2. **Character Class Loading**: Load all character .tres files, verify valid card type references
3. **Deck Loading**: Load all deck .tres files, verify valid priority_card_types
4. **Curio Loading**: Load all curio .tres files, verify valid target_card_type

### Test Configuration

- Property-based tests: Minimum 100 iterations per property
- Test framework: GdUnit4 (existing project test framework)
- Tag format: **Feature: card-type-migration, Property N: [property description]**
