# Implementation Plan: Remove Theme-Agnostic Approach

## Overview

This plan removes the ThemeManager autoload and theme-specific naming, replacing it with a simpler CardTypeUtils static class. The implementation follows a create-then-migrate-then-delete approach to ensure no broken references.

## Tasks

- [x] 1. Create CardTypeUtils static class
  - Create `scripts/config/card_type_utils.gd`
  - Implement VALID_CARD_TYPES constant
  - Implement is_valid_card_type() function
  - Implement get_card_color() function
  - Implement get_card_symbol() function
  - Implement get_card_handling_definition() function
  - Do NOT include get_card_display_name() - this is intentionally removed
  - _Requirements: 2.1, 2.2, 2.3_

- [ ]* 1.1 Write property tests for CardTypeUtils
  - **Property 1: Card type validation accepts only valid types**
  - **Property 2: Valid card types have complete visual mappings**
  - **Property 3: Card handling definitions are complete**
  - **Validates: Requirements 2.2, 2.3, 6.1-6.4**

- [x] 2. Update card.gd to use CardTypeUtils
  - Replace `ThemeManager.get_card_symbol()` with `CardTypeUtils.get_card_symbol()`
  - Replace `ThemeManager.get_card_color()` with `CardTypeUtils.get_card_color()`
  - Replace `ThemeManager.get_card_handling_display_name()` with direct handling string (remove translation)
  - _Requirements: 1.1, 1.3, 2.1_

- [x] 3. Update card_ui.gd to use CardTypeUtils
  - Replace `ThemeManager.get_card_symbol()` with `CardTypeUtils.get_card_symbol()`
  - Replace `ThemeManager.get_card_color()` with `CardTypeUtils.get_card_color()`
  - Replace `ThemeManager.get_card_handling_display_name()` with direct handling string
  - _Requirements: 1.1, 1.3, 2.1_

- [x] 4. Update deck_management.gd to use direct type names
  - Change filter button text from themed names to direct types ("Attack", "Skill", "Power", "Fortune")
  - Update `_setup_filter_buttons()` to use card types directly
  - Update deck composition display to use card types directly
  - _Requirements: 1.1, 1.3, 2.1_

- [x] 5. Update card_reward.gd to use direct type names
  - Replace `ThemeManager.get_card_display_name()` with direct card type string
  - _Requirements: 1.1, 2.1_

- [x] 6. Update game_constants.gd
  - Remove `get_themed_card_type_name()` function entirely
  - _Requirements: 2.4_

- [x] 7. Checkpoint - Verify all ThemeManager references are removed
  - Run grep to confirm no remaining ThemeManager references in GDScript files
  - Ensure all tests pass, ask the user if questions arise

- [x] 8. Remove ThemeManager autoload
  - Delete `scripts/autoloads/theme_manager.gd`
  - Remove ThemeManager entry from `project.godot` autoloads section
  - _Requirements: 2.4_

- [x] 9. Update documentation
  - [x] 9.1 Update CLAUDE.md to remove theme-agnostic references
    - Remove "Cards use theme-agnostic mechanical categories" line
    - Remove "Keep design theme-agnostic (mechanics over flavor)" line
    - _Requirements: 5.1, 5.2_
  - [x] 9.2 Update .kiro/steering/product.md
    - Remove "theme-agnostic" from Core Identity
    - Remove "Theme-agnostic architecture" from Key Differentiators
    - Rename "Card Categories (Theme-Agnostic)" to "Card Categories"
    - Remove "Theme-agnostic core" from Development Philosophy
    - _Requirements: 5.3_
  - [x] 9.3 Update .kiro/steering/structure.md
    - Remove "Theme-agnostic core data with theme-specific overlays" line
    - _Requirements: 5.3_
  - [x] 9.4 Update .kiro/steering/tech.md
    - Remove ThemeManager from Core Autoloads list
    - _Requirements: 5.3_

- [x] 10. Final checkpoint - Verify complete removal
  - Grep for any remaining "theme-agnostic" or "theme agnostic" references
  - Grep for any remaining "Gold/Grit/Grog/Gamble" references in code
  - Ensure all tests pass, ask the user if questions arise

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The create-then-migrate-then-delete approach ensures no broken references during implementation
- CardTypeUtils is a static class (not an autoload) to reduce global state
