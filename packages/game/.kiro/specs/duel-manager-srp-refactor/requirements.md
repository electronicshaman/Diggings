# Requirements Document

## Introduction

This specification covers the refactoring of the DuelManager class (966 lines) to follow the Single Responsibility Principle (SRP). The current DuelManager mixes flow control, effect application, AI logic, class-specific passives, and test sequence handling into a single monolithic class. This refactor extracts each distinct responsibility into focused components while maintaining existing functionality.

## Glossary

- **DuelManager**: The existing 966-line class, refactored to be a thin coordinator/facade
- **DuelFlowController**: New component responsible for turn state management and phase transitions
- **EnemyAIController**: New component responsible for enemy card selection and AI behavior
- **CardResolver**: New component responsible for card validation, cost payment, and effect resolution
- **ClassPassiveHandler**: New component responsible for character class passive abilities
- **TestSequenceHandler**: New component responsible for test/debug multi-battle sequence logic
- **DuelState**: Existing data class holding the current state of a duel (hands, decks, battlefield)
- **EffectProcessor**: Existing component that processes card effects
- **Turn_Phase**: The current phase within a turn (start, main, end)
- **AI_Type**: Enemy behavior pattern (aggressive, defensive, balanced, cunning)

## Requirements

### Requirement 1: Extract Turn Flow Management

**User Story:** As a developer, I want turn flow logic separated from card resolution, so that I can modify turn structure without affecting card mechanics.

#### Acceptance Criteria

1. WHEN a duel starts, THE DuelFlowController SHALL manage the initial setup sequence (draw hands, start first turn)
2. WHEN a turn begins, THE DuelFlowController SHALL handle phase transitions (start → main → end)
3. WHEN a turn ends, THE DuelFlowController SHALL determine the next turn owner (player or enemy)
4. WHEN checking win/loss conditions, THE DuelFlowController SHALL evaluate player death, enemy death, and sanity loss
5. IF a win/loss condition is met, THEN THE DuelFlowController SHALL trigger the appropriate duel end sequence
6. THE DuelFlowController SHALL emit signals for turn_started, turn_ended, and duel_ended events

### Requirement 2: Extract Enemy AI Logic

**User Story:** As a developer, I want enemy AI logic in a dedicated controller, so that I can add new AI behaviors without modifying duel flow.

#### Acceptance Criteria

1. WHEN an enemy turn begins, THE EnemyAIController SHALL select cards to play based on AI type
2. WHEN AI type is "aggressive", THE EnemyAIController SHALL prioritize Attack cards
3. WHEN AI type is "defensive", THE EnemyAIController SHALL prioritize Skill cards and low-cost options
4. WHEN AI type is "balanced", THE EnemyAIController SHALL adapt based on health ratios of both combatants
5. WHEN AI type is "cunning", THE EnemyAIController SHALL counter player patterns using card memory
6. THE EnemyAIController SHALL respect energy constraints when selecting cards
7. THE EnemyAIController SHALL limit cards played per turn to prevent infinite loops

### Requirement 3: Extract Class Passive Abilities

**User Story:** As a developer, I want class-specific passive abilities in a dedicated handler, so that I can add new character classes without modifying core duel logic.

#### Acceptance Criteria

1. THE ClassPassiveHandler SHALL register passive abilities based on the player's character class
2. WHEN the player class is Preacher, THE ClassPassiveHandler SHALL implement Fervent Faith (gain +1 defense when gaining Faith)
3. WHEN the player class is Preacher, THE ClassPassiveHandler SHALL implement Temptation (trigger choice at max Faith)
4. WHEN the player class is Preacher, THE ClassPassiveHandler SHALL implement Holy Conviction (+10% Fortune success at Faith >= 5)
5. THE ClassPassiveHandler SHALL connect to EventBus signals for resource_gained and gambling_modifier_query
6. WHEN a duel ends, THE ClassPassiveHandler SHALL disconnect its signal handlers to prevent memory leaks

### Requirement 4: Extract Test Sequence Handling

**User Story:** As a developer, I want test sequence logic separated from production duel flow, so that debug features don't pollute core game logic.

#### Acceptance Criteria

1. THE TestSequenceHandler SHALL manage multi-battle test sequences independently from normal duels
2. WHEN a test sequence is active, THE TestSequenceHandler SHALL track persistent health/energy between battles
3. WHEN a sequence battle ends in victory, THE TestSequenceHandler SHALL advance to the next enemy or complete the sequence
4. WHEN a sequence battle ends in defeat, THE TestSequenceHandler SHALL reset the sequence and return to test setup
5. THE TestSequenceHandler SHALL respect the show_rewards setting for test sequences
6. IF is_test_duel flag is false, THEN THE TestSequenceHandler SHALL not interfere with normal duel flow

### Requirement 5: Extract Card Validation and Resolution

**User Story:** As a developer, I want card validation and resolution logic in a dedicated component, so that card mechanics are isolated from duel orchestration.

#### Acceptance Criteria

1. THE CardResolver SHALL validate if a card can be played (energy, sanity, resource costs)
2. THE CardResolver SHALL calculate actual energy costs including modifiers
3. THE CardResolver SHALL pay all card costs (energy, sanity, Faith, custom resources)
4. THE CardResolver SHALL resolve card effects using EffectProcessor
5. THE CardResolver SHALL apply effect results to appropriate targets (source vs target)
6. THE CardResolver SHALL handle card destination after resolution (discard, exhaust, hold)
7. THE CardResolver SHALL support both player and enemy card resolution

### Requirement 6: Slim Down DuelManager to Coordinator

**User Story:** As a developer, I want DuelManager to be a thin facade that coordinates between components, so that it has minimal logic of its own.

#### Acceptance Criteria

1. THE DuelManager SHALL instantiate and wire together all component dependencies
2. THE DuelManager SHALL delegate turn flow to DuelFlowController
3. THE DuelManager SHALL delegate AI decisions to EnemyAIController
4. THE DuelManager SHALL delegate card operations to CardResolver
5. THE DuelManager SHALL delegate class passives to ClassPassiveHandler
6. THE DuelManager SHALL delegate test sequences to TestSequenceHandler
7. THE DuelManager SHALL expose public methods that route to appropriate components
8. THE DuelManager SHALL contain no business logic beyond delegation

### Requirement 7: Maintain Backward Compatibility

**User Story:** As a developer, I want existing code that uses DuelManager to continue working, so that the refactor doesn't break the game.

#### Acceptance Criteria

1. THE DuelManager SHALL maintain existing public method signatures
2. THE DuelManager SHALL maintain existing signal emissions (duel_started, turn_started, turn_ended, card_played, duel_ended, enemy_card_played)
3. WHEN external code calls start_new_duel(), THE DuelManager SHALL coordinate with DuelFlowController to start the duel
4. WHEN external code calls play_card(), THE DuelManager SHALL process the card as before
5. WHEN external code calls end_player_turn(), THE DuelManager SHALL delegate to DuelFlowController
