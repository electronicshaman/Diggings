# CLAUDE.md

This file provides guidance to AI coding assistants when working with code in this repository.

## Project Overview

A roguelite card battler prototype built in Godot 4.5.x featuring Australian gold rush meets Lovecraftian horror. Core gameplay involves 1v1 card duels, procedural map exploration, and resource management.

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
ThemeManager        # Theme loading
SeedManager         # Procedural generation seeds (map RNG etc.)
HexmapState         # Persistent map state across scenes
GLog                # Logging system
GameManager         # High-level game state and stats
DeckManager         # Deck management and manipulation
ModalManager        # Modal dialog queue and management
SceneManager        # Scene transitions and preloading
GDAIMCPRuntime      # MCP runtime for Godot editor control (dev only)
MapNodeRegistry     # Legacy stub (disabled - old map system removed)
CurioManager        # Curio acquisition, stacks, and signals
EncounterManager    # Encounter/event system management
CharacterGenerator  # Procedural character generation
RunHistoryManager   # Run history and metrics
DebugHUD            # Debug panel overlay (scene autoload)
EffectRegistry      # Effect type registration and management
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
- Centralized effect resolver at `scripts/systems/card_effects.gd`
- Generic effect system in `scripts/effects/` (used by curios, encounters, etc.)
- Cards use theme-agnostic mechanical categories

### Map generation

Hexmap-based exploration system:

- MapController (`scripts/hexmap/map_controller.gd`) – hexmap scene controller
- HexGrid (`scripts/hexmap/hex_system/hex_grid.gd`) – hex grid logic and pathfinding
- HexRenderer (`scripts/hexmap/hex_system/hex_renderer.gd`) – hex rendering
- TerrainGenerator (`scripts/hexmap/terrain_generation/terrain_generator.gd`) – procedural terrain
- HexmapState autoload – persistent map state across scenes

## File Organization

```
data/
  cards/           # Card resources by type
  characters/      # Character class definitions
  enemies/         # Enemy configurations
  map_nodes/       # Map node resources (cities, camps, etc.)
  maps/            # Regional map configurations
  game_state/      # DuelState, PlayerData, EnemyData resources

scripts/
  autoloads/       # Singletons (EventBus, GLog, SceneManager, etc.)
  cards/           # Card system, CardData, effects
  combat/          # Controllers for duel scenes (e.g., DuelSceneController)
  hexmap/          # Hexmap system (grid, rendering, terrain generation)
  managers/        # MVC controllers (game/ui/input/duel)
  systems/         # Cross-cutting systems (e.g., card_effects.gd)
  ui/              # UI helpers/components

scenes/
  game/            # Gameplay scenes (duel, map, city hub, etc.)
  ui/              # UI scenes (menus, settings, game over)
  map/             # Map-related scenes and visualizers
  debug/           # Debug/testing scenes (e.g., map_test.tscn)
```

## Current Development Focus

### Current development focus

- Hexmap exploration system with procedural terrain generation
- Movement points and turn-based exploration mechanics
- Resource discovery and encounter system
- Persistent map state via HexmapState autoload
- Terrain types with movement costs and special properties

### Known issues

- EventBus declares extra signals by design; unused ones are for upcoming features

## Code Conventions

### GDScript style

- Add `const DEBUG_ENABLED: bool` per script; GLog respects per-file constants
- Prefer Resources (.tres) for data definitions
- Use EventBus for cross-system communication (with connect_safe)
- Keep design theme-agnostic (mechanics over flavor)

### Testing approach

- No formal test framework; rely on debug scenes and in-game debug panel
- Test scenes in `scenes/debug/` for isolated system testing
- Use GLog extensively with per-file DEBUG toggles and min log level controls

## Important Patterns

### Resource-based design

All content as Godot Resources for hot-reloading:

- Cards, characters, enemies as .tres files
- Map configurations as resources
- Theme definitions loadable at runtime

### State machine combat

- Clear phases: PLAYER_TURN → RESOLVE_EFFECTS → ENEMY_TURN
- Effects as data descriptions, not behavior
- Centralized effect resolution in CardEffects system

### Legacy map system

Note: The old MapNodeRegistry-based map system has been removed and replaced with the hexmap exploration system. MapNodeRegistry remains in the codebase as a disabled stub to prevent parser errors in legacy code.

## Quick links

- Logging: `docs/GLOG_USAGE_GUIDE.md`
- Map config: `docs/MAP_CONFIG_GUIDE.md`
- High-level summary: `docs/high_level_summary.md`
