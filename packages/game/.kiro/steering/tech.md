# Technology Stack

## Engine & Framework
- **Godot 4.5** - Primary game engine
- **GDScript** - Main scripting language
- **Mobile rendering** - Optimized for performance

## Project Configuration
- **Target platforms**: Mobile-first design
- **Viewport**: 1920x1080 with canvas_items stretch mode
- **Rendering method**: Mobile renderer for performance

## Key Libraries & Addons
- **gdai-mcp-plugin-godot** - AI/MCP integration plugin for development assistance

## Architecture Patterns
- **Autoload system** - Singleton managers for global state
- **Event Bus pattern** - Decoupled communication via EventBus autoload
- **Resource-based data** - All game data stored as Godot Resources (.tres files)
- **MVC separation** - Clear separation between game logic, UI, and input handling

## Core Autoloads (Load Order)
1. **GameSettings** - Configuration and settings
2. **EventBus** - Global event communication
3. **SaveSystem** - Save/load functionality
4. **ResourceManager** - Asset loading and caching
5. **ThemeManager** - Dynamic theme switching
6. **SeedManager** - Deterministic run seeding
7. **GLog** - Centralized logging system
8. **GameManager** - High-level game state
9. **SceneManager** - Scene transitions
10. **DeckManager** - Card deck management
11. **CurioManager** - Curio/relic system
12. **EncounterManager** - Encounter system
13. **CharacterGenerator** - Character creation

## Development Tools
- **GLog system** - Professional logging with per-file debug toggles
- **DebugHUD** - In-game debug panel (toggle with HUD key)
- **Seed visibility** - Deterministic runs for testing
- **Error handling** - Graceful degradation and recovery systems

## Common Commands

### Running the Game
```bash
# Launch from Godot editor or export and run
# Main scene: res://scenes/ui/main_menu.tscn
```

### Debug Controls
- **HUD key** (F12) - Toggle debug panel
- **Seed display** - Enable via GameSettings.show_seed_in_ui
- **Per-file logging** - Use GLog.set_file_debug(filename, enabled)

### Development Workflow
- **Hot reload** - All Resources (.tres) reload automatically
- **Scene testing** - Individual scenes can be run directly
- **Debug logging** - Use GLog.debug(), GLog.warn(), GLog.error()

## Code Quality Standards
- **Typed GDScript** - Use type hints: `var cards: Array[CardData]`
- **Resource validation** - Validate all inputs in public methods
- **Error handling** - Use GLog for consistent error reporting
- **Signal management** - Use EventBus.connect_safe() for leak prevention
- **Constants** - Define magic numbers in game_constants.gd

## Performance Considerations
- **Object pooling** - Reuse frequently created objects (cards, effects)
- **Resource caching** - Cache loaded resources in ResourceManager
- **Signal optimization** - Disconnect signals in _exit_tree()
- **Mobile optimization** - Use mobile renderer and optimize for lower-end devices

## File Organization
- **Scripts**: Organized by system (autoloads/, cards/, combat/, etc.)
- **Scenes**: Organized by function (ui/, game/, cards/, debug/)
- **Data**: All Resources in data/ with clear categorization
- **Assets**: Raw assets in assets/, imported assets handled by Godot