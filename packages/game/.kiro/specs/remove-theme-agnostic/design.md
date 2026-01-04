# Design Document: Remove Theme-Agnostic Approach

## Overview

This design removes the ThemeManager autoload and its theme-specific naming conventions (Gold/Grit/Grog/Gamble), simplifying the codebase to use Attack/Skill/Power/Fortune directly everywhere. The useful utility functions (colors, symbols, handling definitions) will be moved to a simpler CardTypeUtils static class.

## Architecture

The current architecture has ThemeManager as an autoload that:
1. Validates card types (Attack/Skill/Power/Fortune)
2. Maps mechanical types to theme-specific display names (Attack→Gold, etc.)
3. Provides card colors and symbols
4. Provides card handling definitions

The new architecture will:
1. Remove ThemeManager as an autoload
2. Create a simple CardTypeUtils static class with only the needed utilities
3. Remove all theme-specific display name mapping
4. Update all call sites to use card types directly

```
Before:
┌─────────────────────────────────────────────────────────┐
│                    ThemeManager                          │
│  - VALID_CARD_TYPES                                     │
│  - is_valid_card_type()                                 │
│  - get_card_display_name() → Gold/Grit/Grog/Gamble     │
│  - get_card_color()                                     │
│  - get_card_symbol()                                    │
│  - get_card_handling_display_name()                     │
│  - get_card_handling_definition()                       │
└─────────────────────────────────────────────────────────┘

After:
┌─────────────────────────────────────────────────────────┐
│                   CardTypeUtils                          │
│  - VALID_CARD_TYPES                                     │
│  - is_valid_card_type()                                 │
│  - get_card_color()                                     │
│  - get_card_symbol()                                    │
│  - get_card_handling_definition()                       │
└─────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### CardTypeUtils (New Static Class)

Location: `scripts/config/card_type_utils.gd`

```gdscript
class_name CardTypeUtils
extends RefCounted

const VALID_CARD_TYPES: Array[String] = ["Attack", "Skill", "Power", "Fortune"]

static func is_valid_card_type(card_type: String) -> bool:
    return card_type in VALID_CARD_TYPES

static func get_card_color(card_type: String) -> Color:
    match card_type:
        "Attack": return Color(0.831, 0.686, 0.216)
        "Skill": return Color(0.545, 0.271, 0.075)
        "Power": return Color(0.722, 0.525, 0.043)
        "Fortune": return Color(0.133, 0.545, 0.133)
        _: return Color.WHITE

static func get_card_symbol(card_type: String) -> String:
    match card_type:
        "Attack": return "🔫"
        "Skill": return "🛡"
        "Power": return "🍺"
        "Fortune": return "🎲"
        _: return "?"

static func get_card_handling_definition(handling: String) -> Dictionary:
    # Same implementation as current ThemeManager
```

### Files to Modify

| File | Change |
|------|--------|
| `scripts/autoloads/theme_manager.gd` | DELETE |
| `project.godot` | Remove ThemeManager autoload |
| `scripts/config/card_type_utils.gd` | CREATE - new utility class |
| `scripts/cards/card.gd` | Replace ThemeManager → CardTypeUtils |
| `scripts/cards/card_ui.gd` | Replace ThemeManager → CardTypeUtils |
| `scripts/ui/deck_management.gd` | Use card type directly, remove display name calls |
| `scripts/encounters/outcomes/card_reward.gd` | Use card type directly |
| `scripts/config/game_constants.gd` | Remove get_themed_card_type_name() |

### Call Site Changes

1. **card.gd** - Replace `ThemeManager.get_card_symbol()`, `ThemeManager.get_card_color()`, `ThemeManager.get_card_handling_display_name()` with CardTypeUtils equivalents

2. **card_ui.gd** - Same replacements as card.gd

3. **deck_management.gd** - Change filter buttons from themed names to direct types:
   ```gdscript
   # Before
   filter_attack_button.text = ThemeManager.get_card_display_name("Attack")
   # After
   filter_attack_button.text = "Attack"
   ```

4. **card_reward.gd** - Use card type directly in description:
   ```gdscript
   # Before
   var display_name = ThemeManager.get_card_display_name(card_type)
   # After
   var display_name = card_type
   ```

5. **game_constants.gd** - Remove `get_themed_card_type_name()` function entirely

## Data Models

No data model changes required. CardData already uses Attack/Skill/Power/Fortune internally.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Property 1: Card type validation accepts only valid types
*For any* string input, `CardTypeUtils.is_valid_card_type()` SHALL return true if and only if the input is exactly one of "Attack", "Skill", "Power", "Fortune"
**Validates: Requirements 2.3**

Property 2: Valid card types have complete visual mappings
*For any* valid card type (Attack/Skill/Power/Fortune), `CardTypeUtils.get_card_color()` SHALL return a non-white Color AND `CardTypeUtils.get_card_symbol()` SHALL return a non-"?" symbol
**Validates: Requirements 2.2**

Property 3: Card handling definitions are complete
*For any* valid handling type (Standard/Equipped/Flash/Keep/Hold/Oneshot), `CardTypeUtils.get_card_handling_definition()` SHALL return a Dictionary containing all five required keys: discards_after_use, discards_end_of_turn, starts_in_hand, removed_after_use, triggers_on_draw
**Validates: Requirements 6.1-6.4**

## Error Handling

- Invalid card types passed to utility functions return sensible defaults (Color.WHITE, "?")
- No exceptions thrown - graceful degradation
- GLog warnings for invalid inputs during development

## Testing Strategy

### Unit Tests
- Test CardTypeUtils.is_valid_card_type() with valid and invalid inputs
- Test CardTypeUtils.get_card_color() returns expected colors for each type
- Test CardTypeUtils.get_card_symbol() returns expected symbols for each type
- Test CardTypeUtils.get_card_handling_definition() returns complete dictionaries

### Property-Based Tests
- Use GUT framework for property-based testing
- Generate random strings to verify is_valid_card_type() only accepts valid types
- Verify all valid card types have non-default colors and symbols

### Integration Tests
- Verify cards display correctly with new utility class
- Verify deck management filters work with direct type names
- Verify card rewards show correct type names
