# Requirements Document

## Introduction

This specification covers the migration of the card type system from the legacy theme-specific naming convention (Gold/Grit/Grog/Gamble) to a unified mechanical category system (Attack/Skill/Power/Fortune). The goal is to create a cleaner, theme-agnostic architecture where card types are defined by their mechanical behavior, with theme-specific display names handled separately by the UI layer.

## Glossary

- **Card_Type_System**: The system that categorizes cards by their mechanical behavior (Attack, Skill, Power, Fortune)
- **Mechanical_Category**: The theme-agnostic classification of a card's behavior (Attack/Skill/Power/Fortune)
- **Theme_Display**: The UI layer that converts mechanical categories to theme-specific display names
- **CardData**: The Resource class that defines card properties and effects
- **PlayerData**: The Resource class that tracks player state including cost reductions
- **ThemeManager**: The autoload that provides theme-specific visual styling and display names
- **Class_Resource**: Character-specific resources like Faith, Ammo, Brew that buff cards (separate from card types)

## Requirements

### Requirement 1: Unified Card Type Field

**User Story:** As a developer, I want cards to use a single `card_type` field with mechanical category values, so that the codebase has consistent card type handling.

#### Acceptance Criteria

1. THE CardData resource SHALL use `card_type` with values "Attack", "Skill", "Power", or "Fortune"
2. WHEN a card is created, THE CardData SHALL default `card_type` to "Attack"
3. THE CardData SHALL remove the redundant `mechanical_category` field after migration
4. WHEN legacy card type values (Gold/Grit/Grog/Gamble) are encountered, THE Card_Type_System SHALL treat them as invalid

### Requirement 2: Theme-Specific Display Names

**User Story:** As a player, I want to see theme-appropriate card type names in the UI, so that the game maintains its thematic identity.

#### Acceptance Criteria

1. THE ThemeManager SHALL provide a method to convert mechanical categories to theme display names
2. WHEN displaying card type in UI, THE Theme_Display SHALL show "Gold" for Attack, "Grit" for Skill, "Grog" for Power, "Gamble" for Fortune (in "the_rush" theme)
3. THE ThemeManager SHALL provide card colors based on mechanical category values
4. THE ThemeManager SHALL provide card symbols based on mechanical category values
5. WHEN a non-standard theme is active, THE Theme_Display SHALL fall back to mechanical category names

### Requirement 3: Cost Reduction System Migration

**User Story:** As a developer, I want cost reduction fields to use mechanical category names, so that the code is consistent and maintainable.

#### Acceptance Criteria

1. THE PlayerData SHALL rename `grit_cost_reduction` to `skill_cost_reduction`
2. THE PlayerData SHALL rename `grog_cost_reduction` to `power_cost_reduction`
3. THE PlayerData SHALL rename `gamble_cost_reduction` to `fortune_cost_reduction`
4. WHEN calculating actual energy cost, THE PlayerData SHALL match card types using mechanical category values ("Attack", "Skill", "Power", "Fortune")
5. THE PlayerData SHALL update all related duration fields to match the new naming convention

### Requirement 4: Character Class Card Preferences

**User Story:** As a game designer, I want character classes to reference card types by mechanical category, so that class definitions are theme-agnostic.

#### Acceptance Criteria

1. THE CharacterClass resource SHALL use mechanical category values in `preferred_card_types`
2. THE CharacterClass resource SHALL use mechanical category values in `forbidden_card_types`
3. WHEN checking card availability for a class, THE Card_Type_System SHALL compare using mechanical category values

### Requirement 5: Card Resource File Migration

**User Story:** As a developer, I want all card .tres files to use mechanical category values, so that the data layer is consistent.

#### Acceptance Criteria

1. WHEN a card .tres file is loaded, THE CardData SHALL have `card_type` set to a mechanical category value
2. THE Card_Type_System SHALL update all existing card .tres files to use mechanical category values
3. WHEN migrating card files, THE Card_Type_System SHALL map: Gold→Attack, Grit→Skill, Grog→Power, Gamble→Fortune

### Requirement 6: Deck and Curio Resource Migration

**User Story:** As a developer, I want deck and curio resources to reference card types consistently, so that all game data uses the same conventions.

#### Acceptance Criteria

1. THE DeckData resource SHALL use mechanical category values in `priority_card_types`
2. THE CurioData resource SHALL use mechanical category values in `target_card_type`
3. WHEN filtering cards by type, THE Card_Type_System SHALL use mechanical category values

### Requirement 7: Card Pile Sorting

**User Story:** As a player, I want my cards sorted consistently by type, so that I can easily find cards in my deck.

#### Acceptance Criteria

1. THE CardPile SHALL sort cards using mechanical category values
2. WHEN sorting by type, THE CardPile SHALL use order: Attack, Skill, Power, Fortune
3. THE CardPile SHALL remove references to legacy type names (Lead/Leather/Liquor/Luck)

### Requirement 8: Remove Legacy Code

**User Story:** As a developer, I want legacy theme-specific code removed after migration, so that the codebase is clean and maintainable.

#### Acceptance Criteria

1. THE GameConstants SHALL remove the `THEME_NAMES` mapping dictionary
2. THE GameConstants SHALL remove or update `get_themed_card_type_name()` to use ThemeManager
3. THE CardData SHALL remove the `mechanical_category` field (consolidated into `card_type`)
4. THE Card_Type_System SHALL remove all match statements using Gold/Grit/Grog/Gamble values
