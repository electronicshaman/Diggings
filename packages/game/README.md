# Project Status: Early Stage / Green Field
- **Backward Compatibility:** EXPLICITLY FORBIDDEN. Do not use wrappers, adapters, or "legacy" patterns to preserve old APIs.
- **Refactoring Strategy:** If a change requires an API break, perform a "clean sweep" refactor. Update all call sites and dependencies immediately.
- **Code Hygiene:** Prioritize "Clean Code" over speed. Avoid tech debt, temporary hacks, or "TODO" shortcuts.
- **Technology Stack:** Godot 4.5 (GDExtension/GDScript). Use modern features (e.g., Stencil Buffer, Typed Arrays) as the default.

## Active milestone

Deterministic curated three-fight mini-run.

- **New Game flow:** static class selection, three fights, two
  card-or-recovery choices (after fight one and fight two), then a summary.
- **Quick Duel:** single-fight developer sandbox, independent of the curated
  run.
- **Frozen:** Atlas, content-kit, generated narrative, the narrative runtime,
  maps, shops, and saving.
- **Canonical design:**
  `docs/superpowers/specs/2026-07-12-core-game-recovery-design.md` (repo
  root).