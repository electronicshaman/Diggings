# Copilot Instructions

## Project Snapshot
- Godot 4.5 roguelite card battler blending Australian gold rush + Lovecraft; combat scenes live under `scenes/game/` while data lives in `data/` and logic in `scripts/`.
- Read `CLAUDE.md` and `docs/high_level_summary.md` for current pillars before touching systems with narrative impact.

## Architecture & Autoloads
- Core MVC split: `scripts/combat/MainGameController.gd` orchestrates duel nodes, `scripts/managers/game_controller.gd` wraps DuelState, `scripts/managers/ui_controller.gd` drives UI binding, and `scripts/managers/input_controller.gd` owns inputs—respect those boundaries.
- Autoload order in `project.godot` matters (GameSettings → EventBus → SaveSystem ... → CurioManager → CharacterGenerator); never reorder without confirming dependencies listed in `CLAUDE.md`.
- `EventBus` is the sanctioned communication layer; use `connect_safe` helpers and emit wrappers documented in `CLAUDE.md` instead of ad-hoc signals.

## Effects & Data-Driven Content
- All gameplay content is Resource-based: cards (`data/cards/**`), characters (`data/characters`), encounters (`data/encounters`), curios (`data/curios`). When adding new content, copy folder templates to keep inspector exports consistent.
- Ongoing migration to a unified GameEffect system (`GENERIC_EFFECT_SYSTEM.md`, `docs/GAMEEFFECT_REFACTOR.md`): new work should prefer `scripts/effects/core/*` patterns (GameEffect + EffectContext + EffectResult) and wrappers over legacy card/curio-specific effect scripts.
- Card mechanical categories (Attack/Skill/Power/Fortune + Status/Curse) stay theme-agnostic; tie theme flavor via upcoming ThemeManager (`docs/theme_agnostic_core.md`). Avoid hardcoding theme colors/symbols in logic.

## Systems to Know
- Map/hex exploration: start with `scripts/hexmap/MapController.gd`, `scripts/hexmap/hex_system/HexGrid.gd`, and docs in `docs/ENCOUNTER_PLAN.md` for wildlife + hazard flow. Keep Poisson sampling + Delaunay triangulation assumptions intact when altering layout code.
- Curios: follow `data/curios/README.md` + `docs/CURIOS_INTEGRATION_PLAN.md`; stack behavior, trigger events, and class synergy fields must be populated so `CurioManager` can broadcast via EventBus.
- Logging: every script defines `const DEBUG_ENABLED`; route output through `GLog` API (`docs/GLOG_USAGE_GUIDE.md`). Never `print()` from runtime scripts—tests rely on log filtering.

## Workflows & Debugging
- Preferred tooling is the GDAI MCP plugin (`addons/gdai-mcp-plugin-godot/README.md`); typical commands: `mcp__godot-mcp__open_scene`, `mcp__godot-mcp__play_scene`, `mcp__godot-mcp__get_godot_errors`, and `mcp__godot-mcp__view_script`. Use these instead of manual editor descriptions in reviews.
- Seeded runs: toggle `GameSettings.show_seed_in_ui` and use SeedManager for reproducible repros; mention seed + path when filing issues.
- Testing is scene-driven (see `scenes/debug/**`); no automated test runner yet, so document manual reproduction steps in PRs.

## Contribution Tips
- Before editing major controllers, scan `PROJECT_IMPROVEMENTS.md` and `docs/project_structure_review.md` to align with planned refactors (e.g., splitting MainGameController responsibilities, resource pooling goals).
- When wiring new features that span systems, define EventBus signals + payload first, then update autoload subscribers; this avoids circular dependencies and keeps the GLog traces readable.
- Cite relevant docs (`docs/Card_design_structure.md`, `docs/CURIOS_INTEGRATION_PLAN.md`, etc.) in commit/PR notes so future contributors can trace design intent.
