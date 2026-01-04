# Requirements Document

## Introduction

The current system maintains a "theme-agnostic" architecture where card types use mechanical categories (Attack/Skill/Power/Fortune) with theme-specific display names (Gold/Grit/Grog/Gamble) handled by ThemeManager. This approach adds unnecessary complexity and abstraction layers. The goal is to simplify the system by using the mechanical names (Attack/Skill/Power/Fortune) directly throughout the UI and removing the theme translation layer entirely.

## Glossary

- **Card_Type_System**: The system that categorizes cards by their mechanical behavior
- **ThemeManager**: The current system that maps mechanical categories to theme-specific display names
- **Attack_Cards**: Direct damage cards
- **Skill_Cards**: Utility and defensive cards
- **Power_Cards**: Persistent combat upgrades
- **Fortune_Cards**: Risk/reward cards with randomized effects
- **CardData**: The Resource class that defines card properties and effects
- **Character_Classes**: Player character types that have card type preferences

## Requirements

### Requirement 1: Use Mechanical Card Types Directly in UI

**User Story:** As a player, I want to see card types displayed as their mechanical names (Attack/Skill/Power/Fortune), so that the interface is clear and direct.

#### Acceptance Criteria

1. WHEN viewing cards in the UI, THE System SHALL display "Attack", "Skill", "Power", "Fortune" as card type names
2. WHEN creating new cards, THE System SHALL use mechanical type names directly
3. WHEN displaying card information, THE System SHALL show mechanical names without theme translation
4. WHEN referencing card types in tooltips and help text, THE System SHALL use mechanical names

### Requirement 2: Remove ThemeManager Translation Layer

**User Story:** As a developer, I want to eliminate the theme translation system, so that there are fewer abstraction layers to maintain.

#### Acceptance Criteria

1. WHEN the system needs card type display names, THE System SHALL use the mechanical card type directly
2. WHEN the system needs card colors and symbols, THE System SHALL map directly from mechanical names to visual properties
3. WHEN validating card types, THE System SHALL use only mechanical category names
4. THE System SHALL remove all theme-specific display name mapping functions

### Requirement 3: Update Character Class Preferences

**User Story:** As a game designer, I want character classes to reference card types by mechanical names, so that class definitions are clear and direct.

#### Acceptance Criteria

1. WHEN defining character class card preferences, THE System SHALL use "Attack", "Skill", "Power", "Fortune" type names
2. WHEN character classes specify forbidden card types, THE System SHALL use mechanical names
3. WHEN character classes specify preferred card types, THE System SHALL use mechanical names
4. WHEN validating character class card access, THE System SHALL compare against mechanical names

### Requirement 4: Maintain All Card Data Resources

**User Story:** As a content creator, I want all existing card data to continue working with mechanical type names, so that no content is lost.

#### Acceptance Criteria

1. WHEN loading existing card resources, THE System SHALL continue to use mechanical type names
2. WHEN creating new card resources, THE System SHALL use only mechanical names for card types
3. WHEN validating card resources, THE System SHALL accept only mechanical type names
4. THE System SHALL maintain all existing card functionality with mechanical type names

### Requirement 5: Update Documentation and Comments

**User Story:** As a developer, I want all documentation to reflect the simplified mechanical-direct approach, so that the codebase is consistent and clear.

#### Acceptance Criteria

1. WHEN reading code comments, THE System SHALL reference mechanical names directly
2. WHEN reading documentation files, THE Content SHALL describe the mechanical-direct approach
3. WHEN reading steering files, THE Content SHALL remove references to theme-agnostic architecture
4. THE Documentation SHALL explain the Attack/Skill/Power/Fortune card type system directly

### Requirement 6: Maintain Card Type Functionality

**User Story:** As a player, I want all existing card functionality to work exactly the same, so that gameplay is not affected by the internal changes.

#### Acceptance Criteria

1. WHEN playing Attack cards, THE System SHALL provide the same damage-dealing functionality as before
2. WHEN playing Skill cards, THE System SHALL provide the same utility and defensive functionality as before
3. WHEN playing Power cards, THE System SHALL provide the same persistent upgrade functionality as before
4. WHEN playing Fortune cards, THE System SHALL provide the same risk/reward functionality as before
5. WHEN the system processes card effects, THE System SHALL maintain all existing card behaviors

### Requirement 7: Update Enemy Deck References

**User Story:** As a game designer, I want enemy decks to reference mechanical card type names, so that enemy AI and deck building works correctly.

#### Acceptance Criteria

1. WHEN enemy decks specify preferred card types, THE System SHALL use mechanical names
2. WHEN enemy AI evaluates card priorities, THE System SHALL recognize mechanical names
3. WHEN enemy decks are validated, THE System SHALL accept only mechanical names
4. WHEN displaying enemy deck information, THE System SHALL show mechanical names directly