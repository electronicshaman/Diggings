# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A **roguelite card battler prototype** built in **Godot 4.4.1** featuring Australian gold rush meets Lovecraftian horror. Core gameplay involves 1v1 card duels, procedural map exploration, and resource management with a unique day/night cycle system.

## Core Architecture

### MVC Pattern with Singleton Autoloads

The game follows strict MVC separation with specific responsibilities:

- **MainGameController** (`scripts/combat/MainGameController.gd`) - Orchestrates all systems
- **GameController** (`scripts/managers/game_controller.gd`) - Model layer (game state)
- **UIController** (`scripts/managers/ui_controller.gd`) - View layer (UI updates)
- **InputController** (`scripts/managers/input_controller.gd`) - Controller (input handling)
- **DuelManager** (`scripts/managers/duel_manager.gd`) - Combat mechanics

### Critical Autoload Order

Order matters due to dependencies:

```gdscript
GameSettings    # Configuration
EventBus        # Inter-system communication
SaveSystem      # Persistence
ResourceManager # Asset management
ThemeManager    # Theme loading
SeedManager     # Procedural generation seeds
GLog           # Debug logging
GameManager    # Game state
SceneManager   # Scene transitions
MapNodeRegistry # Map node type registration
```

### Event-Driven Communication

All systems communicate via EventBus signals:

```gdscript
EventBus.card_played.emit(card_data)
EventBus.damage_dealt.connect(_on_damage_dealt)
```

## Development Commands

### Running & Testing

```gdscript
# Play current scene (F6 in editor)
mcp__godot-mcp__play_scene(scene_type: "current")

# Play main menu (F5 in editor)
mcp__godot-mcp__play_scene(scene_type: "main")

# Check for errors
mcp__godot-mcp__get_godot_errors()

# Clear output logs
mcp__godot-mcp__clear_output_logs()
```

### Debugging

- **GLog System**: Every file has `const DEBUG_ENABLED: bool` to control logging
- **Debug Mode**: Map system has DEBUG mode for layout visualization (`scripts/debug/MapTest.gd`)
- **Screenshot Tools**: Use `mcp__godot-mcp__get_editor_screenshot()` or `get_running_scene_screenshot()`

## Key Systems

### Card System

- **CardData** resources in `data/cards/` organized by type (attack/skill/power/fortune)
- **Modular effects** in `scripts/cards/effects/` - each effect is a separate class
- **CardEffects** resolver (`scripts/systems/card_effects.gd`) processes all effects
- Cards use theme-agnostic mechanical categories

### Map Generation

Recent implementation uses **Poisson Disk Sampling** for reliable layouts:

- **MapGenerator** (`scripts/map/MapGenerator.gd`) - Main generation logic
- **PoissonDiskLayout** (`scripts/map/PoissonDiskLayout.gd`) - Node placement algorithm
- **MapLayoutConfig** (`data/map_layout_config.tres`) - Generation parameters
- **MapNodeRegistry** autoload - Registers all node types dynamically

### Character Classes

Four implemented classes with unique mechanics:

- **Bushranger**: Attack specialist, 55 HP, Ammo system
- **Prospector**: Fortune/risk specialist, 45 HP, Luck mechanics  
- **Tracker**: Skill specialist, 50 HP, Setup/counter gameplay
- **Publican**: Power specialist, 50 HP, Brew token system

## File Organization

```
data/
  cards/         # Card resources by type
  characters/    # Character class definitions
  enemies/       # Enemy configurations
  map_nodes/     # Map node types (cities, camps, etc.)
  maps/          # Regional map configurations

scripts/
  autoloads/     # Singleton services
  cards/         # Card system and effects
  combat/        # Combat controllers
  map/           # Map generation system
  managers/      # MVC controllers
  ui/            # UI scene scripts

scenes/
  game/          # Gameplay scenes (duel, map, etc.)
  ui/            # UI scenes (menus, settings)
  map/           # Map-related scenes
```

## Current Development Focus

### Map System (Active Branch: 2025-08-10-poisson-disk-sampling)

- Replaced force-directed physics with Poisson Disk Sampling for reliable layouts
- Debug mode available via `scenes/debug/map_test.tscn`
- Procedural generation with configurable parameters in `MapLayoutConfig`

### Known Issues

- Some UI node paths in MainGameController may need updating
- Unused signals in EventBus (reserved for future features)
- Map visibility system being refined

## Code Conventions

### GDScript Style

- Use `const DEBUG_ENABLED: bool` in every file for logging control
- Prefer Resources (.tres) for data definitions
- Use EventBus for all inter-system communication
- Follow theme-agnostic design (mechanical categories, not theme-specific)

### Testing Approach

- No formal test framework - use debug scenes and in-game debug panel
- Test scenes in `scenes/debug/` for isolated system testing
- Use GLog.debug() extensively with per-file DEBUG toggles

## Important Patterns

### Resource-Based Design

All content as Godot Resources for hot-reloading:
- Cards, characters, enemies as .tres files
- Map configurations as resources
- Theme definitions loadable at runtime

### State Machine Combat

- Clear phases: PLAYER_TURN → RESOLVE_EFFECTS → ENEMY_TURN
- Effects as data descriptions, not behavior
- Centralized effect resolution in CardEffects system

### Node Type Registration

Map nodes self-register via MapNodeRegistry:
- Each node type in `data/map_nodes/` categorized by folder
- Dynamic loading based on folder structure
- Extensible without code changes