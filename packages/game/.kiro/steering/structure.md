# Project Structure

## Directory Organization

### Root Level
```
res://
├── project.godot          # Godot project configuration
├── icon.svg              # Project icon
├── README.md             # Project documentation
├── addons/               # Third-party plugins
├── assets/               # Raw assets (textures, audio, fonts)
├── data/                 # Game data resources (.tres files)
├── scenes/               # Scene files (.tscn)
├── scripts/              # GDScript files (.gd)
└── docs/                 # Documentation and guides
```

### Scripts Organization
```
scripts/
├── autoloads/            # Singleton managers
├── cards/                # Card system scripts
├── characters/           # Character class definitions
├── combat/               # Combat and duel logic
├── config/               # Configuration and constants
├── curios/               # Curio/relic system
├── data/                 # Data structure classes
├── debug/                # Debug and testing utilities
├── effects/              # Card effect implementations
├── encounters/           # Encounter system
├── hexmap/               # Hex-based map system
├── managers/             # Scene-specific managers
├── systems/              # Core game systems
├── theme/                # Theme management
├── tools/                # Development tools
└── ui/                   # UI controllers and components
```

### Data Organization
```
data/
├── cards/                # Card definitions by type
│   ├── attack/           # Attack cards
│   ├── skill/            # Skill cards
│   ├── power/            # Power cards
│   └── fortune/          # Fortune cards
├── characters/           # Character class data
├── curios/               # Curio definitions by rarity
├── decks/                # Deck configurations
├── enemies/              # Enemy definitions
├── encounters/           # Encounter data
├── effects/              # Reusable effect resources
├── hexmap/               # Map generation data
└── themes/               # Theme-specific content
```

### Scenes Organization
```
scenes/
├── ui/                   # User interface scenes
│   ├── main_menu.tscn    # Main entry point
│   ├── modals/           # Modal dialogs
│   └── ...
├── game/                 # Core gameplay scenes
│   ├── duel.tscn         # Combat scene
│   ├── map_selection.tscn # Map navigation
│   └── ...
├── cards/                # Card visual components
├── debug/                # Debug and testing scenes
└── hexmap/               # Hex map components
```

## Naming Conventions

### Files and Directories
- **snake_case** for all file and directory names
- **Descriptive names** - `card_data.gd` not `cd.gd`
- **Consistent suffixes** - `_manager.gd`, `_controller.gd`, `_data.gd`

### GDScript Classes
- **PascalCase** for class names - `CardData`, `DuelManager`
- **snake_case** for variables and functions - `card_name`, `play_card()`
- **SCREAMING_SNAKE_CASE** for constants - `MAX_HAND_SIZE`, `DEBUG_ENABLED`

### Resources
- **snake_case** for resource files - `prospector_class.tres`
- **Descriptive prefixes** - `attack_`, `skill_`, `power_`, `fortune_`
- **Organized by category** - group similar resources in subdirectories

### Signals (EventBus)
- **snake_case** with descriptive names - `card_played`, `damage_dealt`
- **Past tense** for completed actions - `duel_ended`, `card_discarded`
- **Present tense** for state changes - `health_changed`, `energy_changed`

## Architecture Patterns

### Autoload Dependencies
Follow the established load order in project.godot:
1. Configuration (GameSettings)
2. Communication (EventBus)
3. Core systems (SaveSystem, ResourceManager)
4. Game managers (GameManager, DeckManager, etc.)

### Resource-Based Data
- All game data stored as Godot Resources (.tres files)
- Hot-reloadable during development
- Version-controlled and easily modifiable
- Theme-agnostic core data with theme-specific overlays

### Event-Driven Communication
- Use EventBus for all inter-system communication
- Prefer EventBus.connect_safe() to prevent duplicate connections
- Emit events for state changes, not direct method calls
- Keep event handlers lightweight and focused

### Scene Hierarchy
```
Main Scene
├── GameWorld (Node2D)     # Game logic container
├── UILayer (CanvasLayer)  # UI overlay
└── AudioManager (Node)    # Audio handling
```

## Code Organization Principles

### Separation of Concerns
- **Data classes** - Pure data structures (CardData, PlayerData)
- **Manager classes** - System coordination (DeckManager, GameManager)
- **Controller classes** - Scene-specific logic (DuelSceneController)
- **UI classes** - Interface handling (CardUI, MainMenu)

### Theme-Agnostic Design
- Core mechanics independent of theme content
- Theme-specific data loaded dynamically via ThemeManager
- Mechanical categories (Attack/Skill/Power/Fortune) vs theme types (Gold/Grit/Grog/Gamble)

### Error Handling
- Use GLog for all logging and error reporting
- Validate inputs in all public methods
- Graceful degradation when non-critical systems fail
- Clear error messages with context

### Performance Patterns
- Object pooling for frequently created objects
- Resource caching in ResourceManager
- Proper signal cleanup in _exit_tree()
- Lazy loading of non-essential assets

## Development Workflow

### Adding New Features
1. Create data structures in `data/` directory
2. Implement core logic in appropriate `scripts/` subdirectory
3. Add UI components in `scenes/ui/`
4. Wire together with EventBus signals
5. Add debug/testing support

### Debugging
- Use GLog.debug() for development logging
- Toggle DebugHUD with HUD key (F12)
- Enable per-file debugging with GLog.set_file_debug()
- Use seeded runs for reproducible testing

### Resource Management
- Store all game data as .tres Resources
- Use ResourceManager for caching and pooling
- Validate resource integrity on load
- Support hot-reloading during development