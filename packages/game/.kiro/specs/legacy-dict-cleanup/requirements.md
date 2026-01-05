# Requirements Document

## Introduction

This spec addresses tech debt in the effect processing pipeline. The effect system was modernized to use `EffectResult` resources with flexible `values_applied` dictionaries, but `DuelManager.apply_card_results()` still expects a flat legacy dictionary format. The bridge function `_merge_results_to_legacy_dict()` converts between them but silently drops any keys it doesn't have explicit match cases for (like "faith", "gold", "custom_resources", "delayed_damage", "delayed_defense").

The goal is to eliminate this conversion layer entirely via a clean sweep refactor - updating all call sites to use `EffectResult` arrays directly.

## Glossary

- **EffectResult**: Resource class containing `success`, `values_applied` dictionary, and metadata about effect execution
- **DuelManager**: Core combat manager that applies card effects to game state
- **EffectProcessor**: System that processes GameEffect arrays and returns EffectResult arrays
- **values_applied**: Flexible dictionary in EffectResult containing effect outcomes (can have any keys)

## Requirements

### Requirement 1: Direct EffectResult Consumption

**User Story:** As a developer, I want DuelManager to consume EffectResult arrays directly, so that new effect types don't require updating a conversion layer.

#### Acceptance Criteria

1. WHEN EffectProcessor returns an Array[EffectResult], THE DuelManager SHALL process each EffectResult directly without intermediate conversion
2. WHEN an EffectResult contains a values_applied key, THE DuelManager SHALL apply that value to the appropriate game state
3. WHEN an EffectResult has success=false, THE DuelManager SHALL skip that result without applying any values

### Requirement 2: Preserve All Effect Values

**User Story:** As a developer, I want all effect values to be preserved during processing, so that no effect data is silently dropped.

#### Acceptance Criteria

1. WHEN an EffectResult contains "gold" in values_applied, THE DuelManager SHALL apply it to player's gold via stats
2. WHEN an EffectResult contains "custom_resources" in values_applied, THE DuelManager SHALL apply each resource to the player (including Faith, Ammo, Brew, Fever, Scent)
3. WHEN an EffectResult contains "delayed_damage" in values_applied, THE DuelManager SHALL add it to player's delayed_damage
4. WHEN an EffectResult contains "delayed_defense" in values_applied, THE DuelManager SHALL queue defense for next turn
5. WHEN an EffectResult contains an unknown key, THE DuelManager SHALL log a warning but continue processing

### Requirement 2.1: Consolidate Faith as Custom Resource

**User Story:** As a developer, I want Faith handled consistently as a custom resource, so that there's no special-case code for it.

#### Acceptance Criteria

1. WHEN FaithEffect outputs values_applied, THE FaithEffect SHALL use custom_resources["Faith"] format instead of top-level "faith" key
2. THE DuelManager SHALL NOT have special-case handling for "faith" key separate from custom_resources

### Requirement 3: Remove Legacy Conversion Layer

**User Story:** As a developer, I want the legacy conversion functions removed, so that there's a single clear path for effect application.

#### Acceptance Criteria

1. WHEN the refactor is complete, THE EffectProcessor SHALL NOT contain _merge_results_to_legacy_dict function
2. WHEN the refactor is complete, THE EffectProcessor SHALL NOT contain _create_legacy_results_dict function
3. WHEN the refactor is complete, THE EffectProcessor SHALL return Array[EffectResult] from process_card_effects

### Requirement 4: Effect Application Correctness

**User Story:** As a developer, I want all effect types to apply correctly after the refactor.

#### Acceptance Criteria

1. WHEN a DamageEffect is processed, THE DuelManager SHALL deal damage to the target
2. WHEN a DefenseEffect is processed, THE DuelManager SHALL grant defense to the source
3. WHEN a HealthEffect is processed, THE DuelManager SHALL heal the target
4. WHEN a CardManipulationEffect with "draw" is processed, THE DuelManager SHALL draw cards
5. WHEN a StatusEffect with "stun" is processed, THE DuelManager SHALL stun the target
6. WHEN gambling modifiers are active, THE DuelManager SHALL apply them to relevant effect values

### Requirement 5: Unified Player/Enemy Processing

**User Story:** As a developer, I want a single method that handles effect application with configurable targets, so that player and enemy cards use the same code path.

#### Acceptance Criteria

1. WHEN a player plays a card, THE DuelManager SHALL apply effects with player as source and enemy as target
2. WHEN an enemy plays a card, THE DuelManager SHALL apply effects with enemy as source and player as target
3. THE DuelManager SHALL have a single apply_effect_results method that accepts source and target parameters
