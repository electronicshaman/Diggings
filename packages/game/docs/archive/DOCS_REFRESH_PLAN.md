# Documentation Refresh Plan (2025-08-18)

Purpose: Bring project docs up to date with the current codebase and gameplay.

## Priorities

1. High-level overview

- Update `high_level_summary.md` to reflect gameplay loop (hexmap -> encounters -> combat), classes, and seed system.
- Update `project_structure_review.md` to match current directories and autoloads.

1. Content docs alignment

- `docs/content/CARD_DATABASE.md`: Sync with implemented cards and planned structure. Mark implemented vs planned clearly.
- `docs/content/CHARACTER_GENERATION.md`: Align with current generators in `data/character_generation`.
- `docs/content/ENEMY_PATTERNS.md`: Verify against `data/enemies`/AI behavior.

1. Systems architecture

- `docs/architecture/SYSTEM_ARCHITECTURE.md`: Document managers (GameManager, DuelManager, UIController, DebugController), EventBus, SeedManager, Scene flow.
- `docs/architecture/CHARACTER_CARD_RELATIONSHIPS.md`: Cross-link to cards and decks resources.

1. Specifications sanity check

- `docs/specifications/*_class_spec.md`: Ensure class designs match current cards. Flag deltas.

1. Theming/core split

- `theme_agnostic_core.md`: Ensure it reflects the modular layer and what’s theme-specific.

## Concrete Tasks

- Inventory current autoloads and scenes
- Extract source of truth from `data/` and `scripts/` into docs tables
- Add "Last verified" stamps to each doc
- Add a short README in `docs/` with navigation

## Proposed Milestones

- Milestone A (Today): Add plan, update high-level, fix CARD_DATABASE to current and planned sections, add stamps
- Milestone B: Architecture docs pass
- Milestone C: Content/specs reconciliation

## Notes

- Keep debug tooling (Debug HUD, DebugController) documented but clearly marked as debug-only.
- Prefer links to actual resource paths to reduce drift.
