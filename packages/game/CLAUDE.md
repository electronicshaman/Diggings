# CLAUDE.md

This file provides package-specific guidance to AI coding assistants working in `packages/game`.

## Project overview

Godot 4.6 card battler prototype with Australian gold rush and Lovecraftian horror themes.

- Godot project root: `src/`
- Main scene: `res://scenes/ui/main_menu.tscn`
- Renderer: `mobile`
- Tests: GdUnit4 under `res://test/unit/`

## Canonical sources

- `src/project.godot` - engine version, autoloads, renderer, input map
- `docs/testing_strategy.md` - GdUnit conventions and test layout
- `docs/GLOG_USAGE_GUIDE.md` - logging conventions

## Current autoloads

These should match `src/project.godot`:

```text
GameSettings
EventBus
SaveSystem
ResourceManager
SeedManager
GLog
GameManager
DeckManager
SceneManager
CurioManager
RunHistoryManager
DebugHUD
HandlerRegistry
```

The `gdai-mcp-plugin-godot` addon exists under `src/addons/`, but `GDAIMCPRuntime` is not currently configured as an autoload.

## Working conventions

- Use `EventBus` for cross-system communication and prefer `connect_safe` for idempotent wiring.
- Use `GLog` instead of `print`.
- Prefer `.tres` Resources for gameplay data.
- Route effect execution through `HandlerRegistry` and the handlers under `scripts/handlers/`.
- Keep package guidance short and verify operational facts against `src/project.godot` before repeating them elsewhere.

## Live directory layout

```text
src/
  addons/
  assets/
  data/
    cards/
      player/
      enemy/
      curse/
    character_generation/
    characters/
    curios/
    decks/
    enemies/
    status_effects/
  scenes/
    cards/
    debug/
    game/
    ui/
  scripts/
    autoloads/
    cards/
    characters/
    combat/
    config/
    core/
    curios/
    data/
    debug/
    handlers/
    managers/
    tools/
    ui/
  test/
    unit/
```

## Running and testing

Run from `packages/game/src`:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/ --ignoreHeadlessMode
```

Useful MCP-style actions, when available, are opening `res://scenes/ui/main_menu.tscn`, running the main scene, checking Godot errors, and capturing editor/runtime screenshots.
