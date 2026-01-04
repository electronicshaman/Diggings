# Implementation Plan: Card Type Migration

## Overview

This implementation plan migrates the card type system from legacy theme-specific names (Gold/Grit/Grog/Gamble) to unified mechanical categories (Attack/Skill/Power/Fortune). The migration follows a bottom-up approach: update core data structures first, then update dependent code, and finally migrate resource files.

## Tasks

- [x] 1. Update ThemeManager with mechanical category support
  - [x] 1.1 Add `VALID_CARD_TYPES` constant array
    - Define constant: `["Attack", "Skill", "Power", "Fortune"]`
    - _Requirements: 1.1_
  - [x] 1.2 Add `is_valid_card_type()` validation method
    - Return true if card_type is in VALID_CARD_TYPES
    - _Requirements: 1.4_
  - [x] 1.3 Update `get_card_color()` to use mechanical categories
    - Change match cases from Gold/Grit/Grog/Gamble to Attack/Skill/Power/Fortune
    - Keep same color values
    - _Requirements: 2.3_
  - [x] 1.4 Update `get_card_symbol()` to use mechanical categories
    - Change match cases from Gold/Grit/Grog/Gamble to Attack/Skill/Power/Fortune
    - Keep same symbol values
    - _Requirements: 2.4_
  - [x] 1.5 Add `get_card_display_name()` method
    - Accept card_type and optional theme parameter
    - Return themed name for "the_rush" theme, mechanical name otherwise
    - _Requirements: 2.1, 2.2, 2.5_
  - [ ]* 1.6 Write property tests for ThemeManager
    - **Property 2: Card Type Validation Rejects Legacy Values**
    - **Property 3: Theme Display Name Mapping**
    - **Property 4: ThemeManager Returns Valid Visuals for All Card Types**
    - **Validates: Requirements 1.4, 2.1, 2.3, 2.4, 2.5**

- [x] 2. Update CardData resource
  - [x] 2.1 Change `card_type` default value to "Attack"
    - Update: `@export var card_type: String = "Attack"`
    - _Requirements: 1.2_
  - [x] 2.2 Remove `mechanical_category` field
    - Delete the field and its getter method `get_mechanical_category()`
    - _Requirements: 8.3_
  - [x] 2.3 Add type helper methods
    - Add `is_attack()`, `is_skill()`, `is_power()`, `is_fortune()` convenience methods
    - _Requirements: 1.1_
  - [ ]* 2.4 Write property test for CardData valid types
    - **Property 1: Valid Card Type Constraint**
    - **Validates: Requirements 1.1**

- [x] 3. Update PlayerData cost reduction system
  - [x] 3.1 Rename cost reduction fields
    - `grit_cost_reduction` → `skill_cost_reduction`
    - `grog_cost_reduction` → `power_cost_reduction`
    - `gamble_cost_reduction` → `fortune_cost_reduction`
    - Update all duration fields similarly
    - _Requirements: 3.1, 3.2, 3.3, 3.5_
  - [x] 3.2 Update `get_actual_energy_cost()` method
    - Change match cases from Gold/Grit/Grog/Gamble to Attack/Skill/Power/Fortune
    - _Requirements: 3.4_
  - [x] 3.3 Update setter methods
    - Rename `set_grit_cost_reduction()` → `set_skill_cost_reduction()`
    - Rename `set_grog_cost_reduction()` → `set_power_cost_reduction()`
    - Rename `set_gamble_cost_reduction()` → `set_fortune_cost_reduction()`
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 3.4 Update `apply_card_cost_reductions()` method
    - Update field references to new names
    - _Requirements: 3.5_
  - [x] 3.5 Update `reset_duel_tracking()` method
    - Update field references to new names
    - _Requirements: 3.5_
  - [x] 3.6 Update serialization methods
    - Update `get_save_data()` and `load_from_data()` to use new field names
    - _Requirements: 3.5_
  - [ ]* 3.7 Write property test for cost reduction calculation
    - **Property 5: Cost Reduction Calculation Correctness**
    - **Validates: Requirements 3.4**

- [x] 4. Checkpoint - Verify core changes
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Update CardPile sorting
  - [x] 5.1 Update `sort_by_type()` method
    - Change type_order dictionary to use Attack/Skill/Power/Fortune
    - Remove Lead/Leather/Liquor/Luck references
    - _Requirements: 7.1, 7.2, 7.3_
  - [x] 5.2 Update `count_by_type()` and `get_cards_by_type()` methods
    - Ensure they work with mechanical category values
    - _Requirements: 6.3_
  - [ ]* 5.3 Write property tests for CardPile
    - **Property 9: Card Pile Sort Order Invariant**
    - **Property 10: Card Type Filtering Correctness**
    - **Validates: Requirements 6.3, 7.1, 7.2**

- [x] 6. Update CharacterClass resource
  - [x] 6.1 Update `can_use_card()` method
    - Ensure comparison uses `card_data.card_type` (not mechanical_category)
    - _Requirements: 4.3_
  - [x] 6.2 Update `get_card_weight()` method
    - Ensure comparison uses `card_data.card_type`
    - _Requirements: 4.3_
  - [ ]* 6.3 Write property test for character class card availability
    - **Property 7: Card Availability Check Uses Mechanical Categories**
    - **Validates: Requirements 4.3**

- [x] 7. Update GameConstants
  - [x] 7.1 Remove `THEME_NAMES` dictionary
    - Delete the constant
    - _Requirements: 8.1_
  - [x] 7.2 Update or remove `get_themed_card_type_name()`
    - Either remove or redirect to ThemeManager.get_card_display_name()
    - _Requirements: 8.2_
  - [x] 7.3 Add string/enum conversion helpers
    - Add `card_type_to_string()` and `string_to_card_type()` methods
    - _Requirements: 1.1_

- [x] 8. Update UI components
  - [x] 8.1 Update Card.gd
    - Change `ThemeManager.get_card_color(card_data.card_type)` calls (already correct if ThemeManager updated)
    - Change `ThemeManager.get_card_symbol(card_data.card_type)` calls
    - _Requirements: 2.3, 2.4_
  - [x] 8.2 Update CardUI.gd
    - Same updates as Card.gd
    - _Requirements: 2.3, 2.4_
  - [x] 8.3 Update any display name references
    - Use `ThemeManager.get_card_display_name()` where themed names are shown
    - _Requirements: 2.1, 2.2_

- [x] 9. Update dependent systems
  - [x] 9.1 Update EffectProcessor
    - Change `get_mechanical_category()` calls to use `card_type` directly
    - _Requirements: 8.3_
  - [x] 9.2 Update DuelManager
    - Ensure card type references use mechanical categories
    - _Requirements: 3.4_
  - [x] 9.3 Update CardInstance
    - Ensure `get_card_type()` returns mechanical category value
    - _Requirements: 1.1_
  - [x] 9.4 Update card_reward.gd (encounter outcome)
    - Update type_folders mapping to use mechanical categories
    - _Requirements: 6.3_

- [ ] 10. Checkpoint - Verify code changes
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Migrate card resource files
  - [x] 11.1 Update attack card .tres files
    - Change `card_type = "Gold"` to `card_type = "Attack"`
    - Remove `mechanical_category` field if present
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 11.2 Update skill card .tres files
    - Change `card_type = "Grit"` to `card_type = "Skill"`
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 11.3 Update power card .tres files
    - Change `card_type = "Grog"` to `card_type = "Power"`
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 11.4 Update fortune card .tres files
    - Change `card_type = "Gamble"` or `card_type = "Faith"` to `card_type = "Fortune"`
    - _Requirements: 5.1, 5.2, 5.3_
  - [x] 11.5 Update enemy card .tres files
    - Apply same mappings as above
    - _Requirements: 5.1, 5.2, 5.3_

- [x] 12. Migrate character class resource files
  - [x] 12.1 Update bushranger.tres
    - Change `preferred_card_types = Array[String](["Gold"])` to `["Attack"]`
    - _Requirements: 4.1, 4.2_
  - [x] 12.2 Update tracker.tres
    - Change `preferred_card_types = Array[String](["Grit"])` to `["Skill"]`
    - _Requirements: 4.1, 4.2_
  - [x] 12.3 Update publican.tres
    - Change `preferred_card_types = Array[String](["Grog"])` to `["Power"]`
    - _Requirements: 4.1, 4.2_
  - [x] 12.4 Update prospector.tres
    - Change `preferred_card_types = Array[String](["Gamble"])` to `["Fortune"]`
    - _Requirements: 4.1, 4.2_
  - [x] 12.5 Update preacher.tres
    - Change `preferred_card_types = Array[String](["Faith"])` to `["Fortune"]`
    - _Requirements: 4.1, 4.2_

- [x] 13. Migrate deck resource files
  - [x] 13.1 Update character starter decks
    - Change `priority_card_types` to use mechanical categories
    - _Requirements: 6.1_
  - [x] 13.2 Update enemy decks
    - Change `priority_card_types` to use mechanical categories
    - Map Lead→Attack, Leather→Skill, Liquor→Power, Luck→Fortune
    - _Requirements: 6.1_

- [ ] 14. Migrate curio resource files
  - [x] 14.1 Update curio .tres files
    - Change `target_card_type` to use lowercase mechanical categories
    - Map: attack→attack, skill→skill, power→power, fortune→fortune, faith→fortune
    - _Requirements: 6.2_

- [ ] 15. Final verification
  - [ ]* 15.1 Write integration test for resource loading
    - **Property 8: All Resource Files Use Valid Card Types**
    - Load all card, deck, character, curio resources
    - Verify all card type references are valid mechanical categories
    - **Validates: Requirements 5.1, 6.1, 6.2**
  - [ ]* 15.2 Write property test for character class card types
    - **Property 6: Character Class Card Type References Are Valid**
    - **Validates: Requirements 4.1, 4.2**

- [x] 16. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.
  - Run game and verify cards display correctly with themed names/colors/symbols

## Notes

- Tasks marked with `*` are optional property-based tests
- The migration follows a dependency order: ThemeManager → CardData → PlayerData → dependent systems → resource files
- Resource file migrations can be done with search/replace operations
- Checkpoints at tasks 4, 10, and 16 ensure incremental validation
