# Copilot Instructions

## Project Snapshot
Godot 4.5 roguelite card battler: Australian gold rush meets Lovecraftian horror. 1v1 card duels with dual health/sanity failure states. **Early-stage/greenfield** — prioritize clean code over backward compatibility; refactor freely.

Key docs: `CLAUDE.md` (primary reference), `docs/high_level_summary.md`, `docs/architecture/SYSTEM_ARCHITECTURE.md`.

## Architecture

### MVC with Autoloads
Controllers live in `scripts/managers/`: `GameController` (model), `UIController` (view), `InputController` (input routing), `DuelManager` (duel rules/state machine). Combat orchestration is in `scripts/combat/duel_scene_controller.gd`.

### Autoload Order Matters
Defined in `project.godot` — dependencies flow downward:
```
GameSettings → EventBus → SaveSystem → ResourceManager → SeedManager → GLog → GameManager → DeckManager → SceneManager → CurioManager → CharacterGenerator → RunHistoryManager → DebugHUD → HandlerRegistry
```

### EventBus Communication
All cross-system communication via `EventBus` autoload. Use safe helpers:
```gdscript
EventBus.connect_safe("damage_dealt", _on_damage_dealt)  # Idempotent connect
EventBus.emit_duel_started(enemy_data)                   # Use emit wrappers
EventBus.card_played.emit(card)                          # Or emit signals directly
```
Signals are documented in `docs/architecture/EVENT_BUS_REFERENCE.md`.

## Data-Driven Design

### Resources Structure
All content as `.tres` Resources for hot-reloading:
```
data/cards/player/{attack,skill,power,fortune}/  # Player cards by type
data/cards/enemy/                                 # Enemy cards
data/cards/curse/                                 # Curse/status cards
data/curios/{common,rare,legendary,corrupted}/   # Curios by rarity
data/characters/                                  # Character class definitions
data/character_generation/                        # Procedural generation pools
```

### Card Types (Theme-Agnostic)
- **Attack**: Direct damage + secondary effects
- **Skill**: Utility (defense, buffs, draw) — no direct damage
- **Power**: Persistent combat-long upgrades
- **Fortune**: Randomized risk/reward effects
- **Status/Curse**: Deck pollution (Status clears end-of-combat; Curse persists)

### Character Classes
| Class      | Resource | Max | Playstyle               |
|------------|----------|-----|-------------------------|
| Bushranger | Ammo     | 6   | Tactical gunfighter     |
| Prospector | Fever    | 10  | Gold madness/corruption |
| Tracker    | Scent    | 5   | Primal hunting          |
| Publican   | Brew     | 8   | Hospitality/support     |
| Preacher   | Faith    | 10  | Religious fervor        |

### Handler System
Effect processing via `HandlerRegistry` autoload (`scripts/handlers/`):
```gdscript
var handler = HandlerRegistry.new_by_type("damage")  # Types: health, damage, stat, sanity, resource, defense, card, karma, status
```

## Logging
Every script must define `const DEBUG_ENABLED: bool`. Use `GLog` API — never `print()`:
```gdscript
const DEBUG_ENABLED: bool = true
GLog.debug("Message")  # Automatically respects DEBUG_ENABLED
GLog.warn("Warning")
GLog.error("Error")
```
Control logging via `GLog.set_min_level()` or `GLog.set_file_debug("ClassName", false)`.

## Workflows

### MCP Plugin (Preferred for AI Agents)
Use GDAI MCP commands for editor control:
```
mcp__godot-mcp__play_scene(scene_type: "main")
mcp__godot-mcp__get_godot_errors()
mcp__godot-mcp__get_scene_tree()
mcp__godot-mcp__view_script(file_path: "res://scripts/managers/game_controller.gd")
mcp__godot-mcp__get_editor_screenshot()
```

### Testing
Scene-driven testing in `scenes/debug/` — no automated test runner. Debug HUD toggled via "HUD" input action. Seeded runs via `SeedManager` for reproducible repros.

## Adding Content

### New Curio
1. Copy `data/curios/template_curio.tres` to rarity folder
2. Set trigger events: `"combat_start"`, `"turn_start"`, `"card_played"`, `"damage_dealt"`, etc.
3. Configure class synergy scores (0.5-2.0) and gold costs by rarity

### New Card
1. Create `.tres` in appropriate `data/cards/player/{type}/` folder
2. Define effects as data arrays — `CardResolver` processes them
3. Use `HandlerRegistry` types for effect implementation

### Cross-System Features
1. Define EventBus signal + payload first
2. Update autoload subscribers
3. Use `connect_safe` to avoid duplicate connections
