# System Architecture

Last verified: 2025-08-18

## Autoloads (from `project.godot`)

These are loaded at startup and available as singletons:

- GameSettings — `res://scripts/autoloads/game_settings.gd`
- EventBus — `res://scripts/autoloads/event_bus.gd`
- SaveSystem — `res://scripts/autoloads/save_system.gd`
- ResourceManager — `res://scripts/autoloads/resource_manager.gd`
- ThemeManager — `res://scripts/autoloads/theme_manager.gd`
- SeedManager — `res://scripts/autoloads/seed_manager.gd`
- HexmapState — `res://scripts/autoloads/hexmap_state.gd`
- GLog — `res://scripts/autoloads/glog.gd`
- GameManager — `res://scripts/autoloads/game_manager.gd`
- ModalManager — `res://scripts/autoloads/modal_manager.gd`
- SceneManager — `res://scripts/autoloads/scene_manager.gd`
- GDAIMCPRuntime — `res://addons/gdai-mcp-plugin-godot/gdai_mcp_runtime.gd`
- MapNodeRegistry — `res://scripts/autoloads/map_node_registry.gd`
- CurioManager — `res://scripts/autoloads/curio_manager.gd`
- EncounterManager — `res://scripts/autoloads/encounter_manager.gd`
- CharacterGenerator — `res://scripts/autoloads/character_generator.gd`
- RunHistoryManager — `res://scripts/autoloads/run_history_manager.gd`
- DebugHUD (scene) — `res://scenes/debug/debug_hud.tscn`

## Core Managers (scenes/managers)

Located in `scripts/managers/`:

- GameController — orchestrates duel lifecycle, connects to EventBus
- DuelManager — duel rules/state machine and card execution
- UIController — wires in UI to game state and events
- InputController — translates inputs to game actions and debug toggles
- DebugController — debug commands, HUD toggles and test hooks
- ErrorManager — aggregates errors and records context
- AnimationController — handles combat UI/FX sequencing
- UIReferenceManager — centralized lookups for UI nodes

## EventBus signals (selected)

Event-driven architecture. Key signals include:

- Game: game_started, game_ended, game_paused, game_resumed
- Scene: scene_transition_started/completed, scene_loaded
- Duel: duel_started, duel_ended, turn_started/ended, phase_changed
- Cards: card_played/drawn/discarded/exhausted/upgraded/created/destroyed, hand_changed, deck_shuffled
- Combat effects: damage_dealt, damage_blocked, healing_received, status_applied/removed
- Resources: energy_changed, gold_changed, corruption_changed, sanity_changed, health_changed
- Enemies: enemy_intent_revealed, enemy_action_performed, enemy_defeated, enemy_spawned
- Rewards/Shop: reward_offered/selected, shop_entered/exited, item_purchased
- Curios: curio_acquired/removed/triggered, curio_stack_changed
- Map/Run: node_selected, map_generated, floor_completed, act_completed
- Save/Load: save_requested/completed, load_requested/completed
- UI: ui_notification, ui_tooltip_requested, ui_popup_opened/closed
- Audio: audio_play_requested, music_change_requested
- Debug: debug_command_executed, error_occurred
- Encounters: encounter_triggered/choice_made/completed/outcome_applied/queued
- Modals: modal_requested/opened/closed

## Scene flow

- Main menu: `res://scenes/ui/main_menu.tscn` (run/main_scene)
- Class selection → Map selection → City/Hexmap → Encounter/Combat scenes
- During combat: `scripts/combat/main_game_controller.gd` references `$DuelManager`
- Global state transitions via `GameManager` and `SceneManager` with EventBus notifications

## Notes

- DebugHUD is a CanvasLayer scene autoload; visibility is managed by its controller script.
- Prefer EventBus.connect_safe for idempotent signal wiring.

## Architecture Overview

## Overview

The card battler prototype uses a **clean MVC architecture** with Godot 4.4 autoloads providing singleton services. The system prioritizes **separation of concerns**, **data-driven design**, and **theme-agnostic core mechanics**.

## Architectural Patterns

### Model-View-Controller (MVC)

```text
GameController (Model)     - Game state and logic
UIController (View)        - User interface updates
InputController (Controller) - User input handling
```

**Benefits:**

- Clear separation of responsibilities
- Testable components  
- Maintainable codebase
- Easy to modify individual layers

### Event Bus Pattern

All inter-system communication flows through `EventBus` autoload:

```gdscript
# Systems emit events without knowing who listens
EventBus.card_played.emit(card_data)
EventBus.damage_dealt.emit(target, amount, source)
EventBus.duel_ended.emit(victory)

# Other systems can listen for relevant events  
EventBus.damage_dealt.connect(_on_damage_dealt)
```

## Autoload System

### Load Order (Critical Dependencies)

```ini
[autoload]
GameSettings="*res://scripts/autoloads/game_settings.gd"    # 1. Configuration first
EventBus="*res://scripts/autoloads/event_bus.gd"            # 2. Communication layer
SaveSystem="*res://scripts/autoloads/save_system.gd"        # 3. Persistence
ResourceManager="*res://scripts/autoloads/resource_manager.gd" # 4. Asset loading
ThemeManager="*res://scripts/autoloads/theme_manager.gd"     # 5. Content theming
GLog="*res://scripts/autoloads/glog.gd"                     # 6. Logging system  
GameManager="*res://scripts/autoloads/game_manager.gd"      # 7. Game state
SceneManager="*res://scripts/autoloads/scene_manager.gd"    # 8. Scene transitions
```

### Autoload Responsibilities

#### GameSettings

- Audio, video, gameplay configuration
- Settings persistence and loading
- Configuration change notifications

#### EventBus  

- Decoupled event communication
- Signal definitions for all game events
- Safe connection management

#### SaveSystem

- Encrypted save/load with versioning
- Autosave functionality  
- Save file validation and recovery

#### ResourceManager

- Asset loading and caching
- Object pooling for performance
- Resource preloading strategies

#### ThemeManager  

- Dynamic theme loading and switching
- Asset path resolution per theme
- Theme-specific UI and audio

#### GLog

- Centralized logging with levels
- Per-file debug toggles
- Formatted output with source tracking

#### GameManager

- High-level game state management
- Scene transitions and flow control
- Global game settings and flags

#### SceneManager

- Scene loading with transitions
- Scene state persistence
- Loading screens and progress

## Core Systems Architecture

### Combat System

```text
MainGameController
    GameController      # Game state and logic
    UIController        # Display updates  
    InputController     # Player input
    DuelManager         # Combat mechanics
```

**Data Flow:**
 
1. `InputController` receives player input
2. `GameController` updates game state  
3. `UIController` refreshes display
4. `DuelManager` resolves combat effects

### Card System

```text
CardData (Resource)     # Card definitions and stats
    CardEffect[]          # Array of effect components
    card_type: String     # Theme-specific type (e.g., "Gold")  
    mechanical_category   # Theme-agnostic category (Attack/Skill/Power/Fortune)
    card_handling         # Behavioral flags (discard rules, etc.)

Card (Node)             # Visual representation and interaction
    CardData reference
    Visual components (sprites, labels)
    Interaction handling (click, drag)
```

**Effect Resolution:**
 
```gdscript
# Effects are resolved through centralized system
for effect in card_data.effects:
    CardEffects.resolve_effect(effect, context)
```

```text
PlayerData (Resource)
    Stats               # Health, Sanity, Energy, Gold
    deck: Array[CardData]
    hand: Array[CardData]  
    discard_pile: Array[CardData]
    corruption_level: int

EnemyData (Resource)  
    Stats               # Health, Defense
    attack_patterns: Array[EnemyPattern]
    current_intent: EnemyIntent
    behavior_modifiers: Dictionary
```

## Theme Architecture

### Theme-Agnostic Core

The core systems operate on **mechanical categories** independent of theme:

```gdscript
# Mechanical categories (never change)
enum MechanicalCategory { ATTACK, SKILL, POWER, FORTUNE }

# Theme-specific types (loaded dynamically)
var theme_types = ["Gold", "Grit", "Grog", "Gamble"]  # Australian theme
# Could be ["Steel", "Steam", "Gear", "Spark"]        # Steampunk theme
```

### Theme Loading System

```gdscript
# ThemeManager handles dynamic content loading
func load_theme(theme_name: String):
    var config = load("res://themes/" + theme_name + "/theme_config.tres")
    current_theme = config
    
    # Load theme-specific assets
    load_card_types(config.card_types)
    load_characters(config.characters_path)  
    load_enemies(config.enemies_path)
    
    # Update UI theming
    apply_ui_theme(config.ui_theme)
    EventBus.theme_changed.emit(theme_name)
```

## Data Flow Patterns

### Command Pattern for Actions

```gdscript
# All game actions are commands that can be:
# - Executed immediately
# - Queued for later  
# - Undone/replayed
# - Validated before execution

class PlayCardCommand:
    var card_data: CardData
    var target: Node
    
    func execute():
        # Validate action legality
        # Apply card effects
        # Update game state
        # Trigger events
```

### Observer Pattern for State Changes

```gdscript
# Game state changes broadcast through EventBus
# UI components observe and update accordingly

func _ready():
    EventBus.health_changed.connect(_update_health_display)
    EventBus.energy_changed.connect(_update_energy_display)
    EventBus.card_drawn.connect(_add_card_to_hand_display)
```

### Factory Pattern for Content Creation

```gdscript
# CardFactory creates cards based on theme data
class CardFactory:
    static func create_card(card_id: String) -> CardData:
        var template = ThemeManager.get_card_template(card_id)  
        var card = CardData.new()
        card.setup_from_template(template)
        return card
```

## Performance Architecture

### Object Pooling

```gdscript
# ResourceManager maintains pools for frequently created objects
var card_pools: Dictionary = {}

func get_card_instance(card_type: String) -> Card:
    if not card_pools.has(card_type):
        card_pools[card_type] = []
    
    var pool = card_pools[card_type]
    if pool.available.is_empty():
        return create_new_card_instance(card_type)
    else:
        return pool.available.pop_back()
```

### Lazy Loading

```gdscript
# Assets loaded on-demand rather than at startup
func get_enemy_data(enemy_id: String) -> EnemyData:
    if not enemy_cache.has(enemy_id):
        enemy_cache[enemy_id] = load("res://data/enemies/" + enemy_id + ".tres")
    return enemy_cache[enemy_id]
```

### Signal Optimization  

```gdscript
# EventBus uses safe connections to prevent memory leaks
func connect_safe(signal_name: String, callable: Callable):
    if not is_connected(signal_name, callable):
        connect(signal_name, callable)
        
func disconnect_safe(signal_name: String, callable: Callable):  
    if is_connected(signal_name, callable):
        disconnect(signal_name, callable)
```

## Error Handling Architecture

### Defensive Programming

```gdscript
# All public methods validate inputs
func play_card(card_data: CardData) -> bool:
    if not card_data:
        GLog.error("Attempted to play null card")
        return false
        
    if not can_afford_card(card_data):
        GLog.warn("Cannot afford card: " + card_data.card_name)  
        return false
        
    # Proceed with card play
    return true
```

### Graceful Degradation

```gdscript
# System continues functioning even if non-critical components fail
func load_theme_assets():
    if not load_ui_theme():
        GLog.warn("Failed to load UI theme, using default")
        use_default_ui_theme()
        
    if not load_audio_theme():
        GLog.warn("Failed to load audio theme, continuing without theme audio")
        # Game still playable without themed audio
```

### Recovery Systems

```gdscript
# SaveSystem includes recovery mechanisms
func load_game() -> bool:
    var save_data = load_primary_save()
    if not save_data or not validate_save_data(save_data):
        GLog.warn("Primary save corrupted, attempting backup recovery")
        save_data = load_backup_save()
        
    if not save_data:
        GLog.warn("All saves corrupted, starting new game")
        start_new_game()
        return false
        
    return apply_save_data(save_data)
```

## Extensibility Architecture

### Plugin System Ready

The architecture supports future plugin systems:

```gdscript
# Modular effect system allows custom effects
class_name CardEffect extends Resource

# Theme system supports user-created themes
class_name ThemeConfig extends Resource  

# Event system allows mod hooks
EventBus.mod_event_registered.connect(_on_mod_event)
```

### API Boundaries

Clear interfaces between systems enable safe modification:

```gdscript
# Public APIs are stable contracts
class GameController:
    # Public API - stable interface
    func play_card(card_data: CardData) -> bool
    func end_turn() -> void
    func get_game_state() -> Dictionary
    
    # Private implementation - can change
    func _resolve_card_effects(effects: Array) -> void
```

This architecture provides a solid foundation for the card battler while maintaining flexibility for future expansion and theme creation.

## Related documentation

- Event Bus Reference: `docs/architecture/EVENT_BUS_REFERENCE.md`
- Encounter Flow: `docs/architecture/ENCOUNTER_FLOW.md`
