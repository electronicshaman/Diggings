# CLAUDE.md

This file provides guidance to AI coding assistants when working with code in this repository.

## Project Overview

A roguelite card battler prototype built in Godot 4.5.x featuring Australian gold rush meets Lovecraftian horror. Core gameplay involves 1v1 card duels and resource management.

## Core Architecture

### MVC pattern with singleton autoloads

The game follows strict MVC separation with specific responsibilities:

- DuelSceneController (`scripts/combat/duel_scene_controller.gd`) – orchestrates combat scene controllers
- GameController (`scripts/managers/game_controller.gd`) – model/game state façade over DuelManager/DuelState
- UIController (`scripts/managers/ui_controller.gd`) – view updates and UI wiring
- InputController (`scripts/managers/input_controller.gd`) – input routing
- DuelManager (`scripts/managers/duel_manager.gd`) – duel flow and mechanics

### Autoloads (order from `project.godot`)

Order matters due to dependencies; current autoloads are:

```text
GameSettings        # Configuration
EventBus            # Inter-system communication (signals + helpers)
SaveSystem          # Persistence
ResourceManager     # Asset management
SeedManager         # Procedural generation seeds
GLog                # Logging system
GameManager         # High-level game state and stats
DeckManager         # Deck management and manipulation
SceneManager        # Scene transitions and preloading
GDAIMCPRuntime      # MCP runtime for Godot editor control (dev only)
CurioManager        # Curio acquisition, stacks, and signals
CharacterGenerator  # Procedural character generation
RunHistoryManager   # Run history and metrics
DebugHUD            # Debug panel overlay (scene autoload)
HandlerRegistry     # Effect handler registration and dispatch
```

### Event-driven communication

All systems communicate via the `EventBus` autoload (signals + helper methods). Use safe connect helpers and wrappers:

```gdscript
# Emitting via helper wrappers
EventBus.emit_ui_notification("Game Ready", "success")
EventBus.emit_game_event("turn_started", [1])  # emits if signal exists

# Emitting signals directly
EventBus.card_played.emit(card_node)

# Safe connect to avoid duplicate connections
EventBus.connect_safe("damage_dealt", Callable(self, "_on_damage_dealt"))
```

## Development Commands

### Running & testing (MCP plugin)

Requires the GDAI MCP Godot plugin enabled in this project. Useful commands:

```text
mcp__godot-mcp__open_scene(path: "res://scenes/ui/main_menu.tscn")
mcp__godot-mcp__play_scene(scene_type: "main" | "current")
mcp__godot-mcp__stop_running_scene()
mcp__godot-mcp__get_godot_errors()
mcp__godot-mcp__clear_output_logs()
mcp__godot-mcp__get_scene_tree()
mcp__godot-mcp__view_script(path: "res://scripts/managers/game_controller.gd")
mcp__godot-mcp__get_running_scene_screenshot()
```

### Debugging

- GLog system: use GLog, not print (see `docs/GLOG_USAGE_GUIDE.md`)
- Screenshots: `mcp__godot-mcp__get_editor_screenshot()` and `mcp__godot-mcp__get_running_scene_screenshot()`

## Key Systems

### Card system

- CardData resources in `data/cards/` organized by type (attack/skill/power/fortune)
- Effects stored as data arrays in CardData resources (data-driven design)
- CardResolver (`scripts/combat/card_resolver.gd`) – processes card effects
- HandlerRegistry system (`scripts/handlers/`) – modular effect handlers for damage, status, resources, etc.
- CardCost system (`scripts/combat/costs/`) – unified card cost handling (energy, sanity, resources)

## File Organization

```
src/
  addons/          # Godot plugins (e.g. godot-mcp)
  assets/          # Art, audio, and other binary assets
  data/            # Game data resources (cards, enemies, etc.)
    cards/         # Card resources by type (player/, enemy/, curse/)
    characters/    # Character class definitions
    curios/        # Curio resources by rarity
    decks/         # Deck configurations
    enemies/       # Enemy configurations

  scripts/         # GDScript source code
    autoloads/     # Singleton systems
    cards/         # Card system logic
    combat/        # Combat controllers and card resolution
    handlers/      # Effect handler system (HandlerRegistry)
    managers/      # MVC controllers
    ui/            # UI components

  scenes/          # Scene files (.tscn)
    game/          # Gameplay scenes
    ui/            # UI screens
    debug/         # Test scenes

  test/            # Unit/integration tests
```

## Current Development Focus

### Current development focus

- Combat system refinement and balancing
- Card effect system via HandlerRegistry
- Curio system integration
- Character class mechanics and resources

### Known issues

- EventBus declares extra signals by design; unused ones are for upcoming features

## Code Conventions

### GDScript style

- Add `const DEBUG_ENABLED: bool` per script; GLog respects per-file constants
- Prefer Resources (.tres) for data definitions
- Use EventBus for cross-system communication (with connect_safe)

### Testing approach

- No formal test framework; rely on debug scenes and in-game debug panel
- Test scenes in `scenes/debug/` for isolated system testing
- Use GLog extensively with per-file DEBUG toggles and min log level controls

## Important Patterns

### Resource-based design

All content as Godot Resources for hot-reloading:

- Cards, characters, enemies, curios as .tres files
- Deck configurations as resources
- Theme definitions loadable at runtime

### State machine combat

- Clear phases: PLAYER_TURN → RESOLVE_EFFECTS → ENEMY_TURN
- Effects as data descriptions, not behavior
- Centralized effect resolution via CardResolver and HandlerRegistry

## Quick links

- Logging: `docs/GLOG_USAGE_GUIDE.md`
- High-level summary: `docs/high_level_summary.md`
