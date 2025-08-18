# Project Structure Review & Godot 4.4 Best Practices

Last verified: 2025-08-18

## Current Structure Analysis

### ✅ Strengths

1. Resource-Based Architecture: Excellent use of Godot Resources for data (CardData, PlayerData, DuelState, etc.)
2. Separation of Concerns: Clear separation between scripts, scenes, and resources
3. Modular Card Effects: Well-designed effect system with inheritance
4. Custom Logging System: Professional GLog implementation with per-file debugging
5. Theme-Agnostic Design: Forward-thinking architecture for multiple themes
6. Comprehensive Documentation: Excellent docs structure with templates and guides

### ⚠️ Areas Needing Improvement

1. Project Structure Reorganization

Current Issues:

- Mixed organizational patterns (some by feature, some by type)
- Inconsistent naming conventions
- Missing standard Godot directory structure
- Autoload registration order needs optimization

Recommended Structure:

```text
res://
├── project.godot
├── icon.svg
├── README.md
├── addons/                          # Third-party plugins (keep as-is)
├── assets/                          # NEW: Raw assets before import
│   ├── textures/
│   ├── audio/
│   └── fonts/
├── data/                            # Resources and data assets
│   ├── cards/
│   │   ├── attack/
│   │   ├── skill/
│   │   ├── power/
│   │   └── fortune/
│   ├── enemies/
│   ├── characters/
│   └── themes/
├── scenes/
│   ├── ui/
│   ├── game/
│   └── cards/
├── scripts/
│   ├── autoloads/
│   ├── components/
│   ├── managers/
│   └── systems/
└── docs/
```

## 2. Autoload System (Current)

Current Autoloads (from project.godot):

GameSettings, EventBus, SaveSystem, ResourceManager, ThemeManager, SeedManager, HexmapState, GLog, GameManager, ModalManager, SceneManager, GDAIMCPRuntime, MapNodeRegistry, CurioManager, EncounterManager, CharacterGenerator, RunHistoryManager, DebugHUD (scene)

Notes:

- Load order looks reasonable (settings/logging before managers)
- DebugHUD is a scene autoload; controller hides panel by default
- SeedManager + GameSettings control seed visibility in UI

## 3. Scene Architecture Improvements

Current Issues:

- MainGameController has too many responsibilities
- No clear MVC/MVP pattern
- UI components tightly coupled to game logic
- Missing scene transitions system

Recommended Changes:

1. Split MainGameController into:
     - GameController (game state)
     - UIController (UI updates)
     - InputController (input handling)
2. Create Scene Hierarchy:

```text
MainGame (Node2D)
├── GameWorld (Node2D) - Game logic container
│   ├── DuelManager (Node)
│   └── CardManager (Node)
├── UILayer (CanvasLayer) - UI container
│   ├── HUD (Control)
│   ├── HandArea (Control)
│   └── DebugPanel (Control)
└── AudioManager (Node) - Audio handling
```

## 4. Resource Management Improvements

Current Issues:

- Hardcoded resource paths
- No resource pooling for cards
- Missing resource validation
- No resource preloading strategy

Recommendations:

1. Create ResourceManager autoload
2. Implement card pooling system
3. Add resource validation
4. Create preloader for game assets

## 5. Code Quality Improvements

Current Issues:

- Some magic numbers in code
- Inconsistent error handling
- Missing input validation
- Array type warnings in some files

Recommendations:

1. Constants file for game balance
2. Consistent error handling patterns
3. Input validation for all public methods
4. Fix remaining type warnings

## 6. Performance Optimizations

Current Issues:

- Potential memory leaks in card instantiation
- No object pooling
- String concatenation in loops
- Missing signal disconnections

Recommendations:

1. Object pooling for frequently created/destroyed objects
2. Proper cleanup in _exit_tree
3. Use StringBuilder for string operations
4. Implement proper signal management

## 7. Godot 4.4 Best Practices Implementation

Missing Features:

- No use of @tool scripts where beneficial
- Limited use of typed arrays
- No custom resource types for complex data
- Missing @export_group for better inspector organization

Recommendations:

1. Add @tool to appropriate scripts
2. Use typed arrays consistently: Array[CardData]
3. Create custom resource types
4. Add @export_group for better organization
5. Use @export_range and @export_enum where appropriate

## 8. Testing & Debugging Infrastructure

Current Strengths:

- Excellent GLog system
- Good debug panel

Areas for Improvement:

1. Add unit testing framework
2. Create integration test scenes
3. Add performance profiling tools
4. Implement automated testing pipeline

## Implementation Priority (Forward Plan)

### Phase 1 (Critical - Core Functionality)

- Fix autoload organization
- Split MainGameController responsibilities
- Create ResourceManager
- Fix remaining type warnings

### Phase 2 (Structure - Developer Experience)

- Reorganize directory structure
- Implement scene hierarchy improvements
- Add constants file for game balance
- Create proper cleanup patterns

### Phase 3 (Polish - Performance & Quality)

- Add object pooling
- Implement testing framework
- Add performance profiling
- Create deployment pipeline

This reorganization will create a more maintainable, scalable, and performance-optimized project structure that follows Godot 4.4 best practices while preserving the excellent architectural decisions already in place.