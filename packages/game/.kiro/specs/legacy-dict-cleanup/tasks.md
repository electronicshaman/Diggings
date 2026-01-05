# Implementation Plan: Legacy Dict Cleanup

## Overview

Clean sweep refactor to eliminate the `_merge_results_to_legacy_dict()` conversion layer. DuelManager will consume `Array[EffectResult]` directly via a unified `apply_effect_results()` method.

## Tasks

- [x] 1. Update FaithEffect to use custom_resources format
  - Change `values_applied["faith"]` to `values_applied["custom_resources"]["Faith"]`
  - Remove the shadowed `EffectResult` preload (use class_name directly)
  - _Requirements: 2.1.1_

- [x] 2. Create unified apply_effect_results method in DuelManager
  - [x] 2.1 Add `apply_effect_results(effect_results: Array[EffectResult], source, target)` method
    - Handle all known keys from values_applied
    - Log warnings for unknown keys
    - Skip results with success=false
    - _Requirements: 1.1, 1.2, 1.3, 2.5_
  
  - [x] 2.2 Add `_apply_single_result(values: Dictionary, source, target)` helper
    - Map each key to appropriate state mutation
    - Handle source vs target correctly (damage→target, defense→source)
    - _Requirements: 5.1, 5.2_

- [x] 3. Update EffectProcessor to return Array[EffectResult] directly
  - [x] 3.1 Modify `apply_card_instance_effects` to return Array[EffectResult]
    - Remove call to `_merge_results_to_legacy_dict`
    - Remove call to `_create_legacy_results_dict`
    - Return effect_results directly
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [x] 3.2 Modify `apply_card_instance_effects_with_context` similarly
    - Same changes as 3.1
    - _Requirements: 3.3_
  
  - [x] 3.3 Update gambling modifier application
    - Move `_apply_gambling_modifiers` to work on Array[EffectResult] instead of Dictionary
    - _Requirements: 4.6_

- [x] 4. Update DuelManager call sites
  - [x] 4.1 Update `resolve_single_card_with_context` for player cards
    - Call `apply_effect_results` with player as source, enemy as target
    - Remove call to `apply_card_results`
    - _Requirements: 5.1_
  
  - [x] 4.2 Update `resolve_single_card_with_context` for enemy cards
    - Call `apply_effect_results` with enemy as source, player as target
    - Remove call to `apply_enemy_card_results`
    - _Requirements: 5.2_
  
  - [x] 4.3 Update `resolve_battlefield` method
    - Use new `apply_effect_results` for both player and enemy cards
    - _Requirements: 5.3_

- [x] 5. Remove legacy code
  - [x] 5.1 Remove `apply_card_results` method from DuelManager
    - Delete the entire method
    - _Requirements: 3.1_
  
  - [x] 5.2 Remove `apply_enemy_card_results` method from DuelManager
    - Delete the entire method
    - _Requirements: 3.1_
  
  - [x] 5.3 Remove `_merge_results_to_legacy_dict` from EffectProcessor
    - Delete the entire function
    - _Requirements: 3.1_
  
  - [x] 5.4 Remove `_create_legacy_results_dict` from EffectProcessor
    - Delete the entire function
    - _Requirements: 3.2_
  
  - [x] 5.5 Remove special "faith" handling from DuelManager
    - Delete the `if results.has("faith")` block
    - Faith now handled via custom_resources
    - _Requirements: 2.1.2_

- [x] 6. Checkpoint - Verify compilation and basic functionality
  - Ensure all scripts compile without errors
  - Run a test duel to verify cards still work
  - Ask the user if questions arise

- [x] 7. Fix ResourceEffect shadowed variable warning
  - Rename local `resource_name` variable to avoid shadowing base class property
  - Remove shadowed `EffectResult` preload
  - _Requirements: Code quality_

- [ ]* 8. Property-based tests
  - [ ]* 8.1 Write property test for failed results being skipped
    - **Property 1: Failed Results Are Skipped**
    - **Validates: Requirements 1.3**
  
  - [ ]* 8.2 Write property test for source/target assignment
    - **Property 4: Source/Target Assignment**
    - **Validates: Requirements 5.1, 5.2**
  
  - [ ]* 8.3 Write property test for FaithEffect output format
    - **Property 5: FaithEffect Output Format**
    - **Validates: Requirements 2.1.1**

- [ ] 9. Final checkpoint
  - Ensure all tests pass
  - Verify no GDScript warnings in modified files
  - Ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The refactor is a clean sweep - no backward compatibility wrappers
- All call sites must be updated in the same pass to avoid broken state
