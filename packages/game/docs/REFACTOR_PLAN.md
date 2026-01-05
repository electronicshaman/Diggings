# Major Refactor: Core Gameplay Focus + SOLID Principles

## Summary

Strip back to core duel gameplay by disabling hexmap/encounter systems, then apply SOLID principles to tighten the codebase.

**Approach:** Disable & Stub (preserve files for future use)
**New Game Flow:** Test Duel Menu as primary entry point

---

## Phase 1: Disable Hexmap/Encounter Systems

### 1.1 Remove/Disable Autoloads

**File:** `project.godot`

- Remove `MapNodeRegistry` (already a stub)
- Comment out `HexmapState`
- Comment out `EncounterManager`

### 1.2 Stub GameManager References

**File:** `scripts/autoloads/game_manager.gd`

- Guard HexmapState calls at lines 170, 470-472 with `Engine.has_singleton()` checks
- Modify `select_map()` to redirect to test duel menu
- Update `start_new_run()` to go to test duel scene instead of map_selection

### 1.3 Update SceneManager Paths

**File:** `scripts/autoloads/scene_manager.gd`

- Comment out: `map`, `map_selection`, `event`, `encounter_outcome`
- Add: `test_duel_menu` pointing to existing test duel setup scene

**Risk:** LOW - Easy rollback, no logic changes

---

## Phase 2: Promote Test Duel Menu

### 2.1 Update Main Menu

**Files:**

- `scripts/ui/main_menu.gd`
- `scenes/ui/main_menu.tscn`

**Changes:**

- Rename "Test Duel" to "Play Duel" (primary button)
- Redirect "New Game" to test duel setup
- Consider hiding "Continue" (no persistent runs)

### 2.2 Optional: Enhance Test Duel Setup

**File:** `scripts/debug/test_duel_setup.gd` (492 lines - already well-implemented)

- Add quick-start presets
- Save/load favorite configurations

**Risk:** LOW - UI only, reuses tested code

---

## Phase 3: SOLID Refactor - DuelManager (SRP)

**Current:** 966 lines mixing flow control + effect application + AI

### 3.1 Extract DuelFlowController

**New file:** `scripts/combat/duel_flow_controller.gd`

- Turn state management
- Phase transitions
- Win/loss condition checking

### 3.2 Extract EnemyAIController

**New file:** `scripts/combat/enemy_ai_controller.gd`

- AI type selection (aggressive, defensive, balanced, cunning)
- Card selection algorithms
- Extract from DuelManager lines 181-294

### 3.3 Slim Down DuelManager

**File:** `scripts/managers/duel_manager.gd`

- Inject DuelFlowController and EnemyAIController
- Keep: card validation, cost payment, result application
- Delegate: flow control, AI decisions

**Risk:** MEDIUM - Core system, requires careful interface design

---

## Phase 4: SOLID Refactor - EffectProcessor (OCP/SRP)

**Current:** 2,873 line monolith handling all effect types

### 4.1 Create Effect Handler Interface

**New file:** `scripts/effects/handlers/effect_handler.gd`

```gdscript
class_name EffectHandler

func can_handle(effect: GameEffect) -> bool:
    return false

func process(effect: GameEffect, context: EffectContext) -> EffectResult:
    push_error("Must be overridden")
    return null
```

### 4.2 Create Concrete Handlers

**New files in `scripts/effects/handlers/`:**

- `damage_effect_handler.gd`
- `defense_effect_handler.gd`
- `status_effect_handler.gd`
- `card_manipulation_handler.gd`
- `resource_effect_handler.gd`
- `health_effect_handler.gd`

### 4.3 Create Handler Registry

**New file:** `scripts/effects/handlers/effect_handler_registry.gd`

- Registers handlers at startup
- Dispatches effects to appropriate handler

### 4.4 Slim Down EffectProcessor

**File:** `scripts/systems/effect_processor.gd`

- Context creation
- Handler dispatch via registry
- Result aggregation

**Risk:** HIGH - Core system, consider feature flag for old/new paths

---

## Phase 5: SOLID Refactor - CurioManager/CardInstance (DIP)

**Current:** CardInstance directly queries CurioManager autoload (lines 60-67)

### 5.1 Create Modifier Interface

**New file:** `scripts/cards/card_modifier_calculator.gd`

```gdscript
class_name CardModifierCalculator

func calculate_modifications(card_data: CardData, is_player_card: bool) -> Dictionary:
    return {"damage": 0, "defense": 0, "cost": 0, "draw": 0}
```

### 5.2 Create Curio Implementation

**New file:** `scripts/cards/curio_modifier_calculator.gd`

- Wraps CurioManager.calculate_card_modifications()

### 5.3 Inject into CardInstance

**File:** `scripts/cards/card_instance.gd`

- Add `modifier_calculator: CardModifierCalculator` parameter to constructor
- Default to CurioModifierCalculator if not provided
- Update `get_display_energy_cost()` to use injected calculator

**Risk:** MEDIUM - Constructor change may affect instantiation sites

---

## Phase 6: SOLID Refactor - CharacterGenerator (OCP)

**Current:** Hardcoded backstory compatibility logic (lines 285-343)

### 6.1 Create Backstory Rule Resource

**New file:** `data/character_generation/backstory_rule.gd`

- backstory_id, culture_key, name_pool_override, curio_weight_modifiers

### 6.2 Create Rule Data Files

**New directory:** `data/character_generation/backstory_rules/*.tres`

- One file per backstory element with rules

### 6.3 Update CharacterGenerator

**File:** `scripts/autoloads/character_generator.gd`

- Load rules from data files
- Replace hardcoded switch with rule lookup

**Risk:** LOW - Additive change, old logic as fallback

---

## Implementation Order

```
Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4
                              │
                              └──► Phase 5 (can run parallel)
                                        │
                                        └──► Phase 6
```

---

## Critical Files Summary

| Phase | File | Lines | Change Type |
|-------|------|-------|-------------|
| 1 | `project.godot` | - | Config |
| 1 | `scripts/autoloads/game_manager.gd` | 170, 467-475 | Stub |
| 1 | `scripts/autoloads/scene_manager.gd` | 15-33 | Config |
| 2 | `scripts/ui/main_menu.gd` | - | UI |
| 3 | `scripts/managers/duel_manager.gd` | 966 total | Extract |
| 4 | `scripts/systems/effect_processor.gd` | 2,873 total | Extract |
| 5 | `scripts/cards/card_instance.gd` | 60-67 | DIP |
| 6 | `scripts/autoloads/character_generator.gd` | 285-343 | OCP |

---

## Rollback Strategy

- **Phase 1-2:** Git revert
- **Phase 3-4:** Feature flags (`USE_NEW_DUEL_FLOW`, `USE_EFFECT_HANDLERS`)
- **Phase 5:** Default parameter maintains compatibility
- **Phase 6:** Fallback to hardcoded logic if no rules found

---

## Testing Checkpoints

After each phase:

1. Run test duel setup with various configurations
2. Complete a full duel (player win and loss)
3. Check GLog for errors/warnings
4. Verify curio effects trigger correctly

---

## Systems Being Disabled (Not Deleted)

### Files preserved for future use:

**Hexmap System (~40 files):**
- `scripts/hexmap/` - All hexmap scripts
- `data/hexmap/` - Terrain types, settings, player scripts
- `scenes/hexmap/` - Hexmap scene

**Encounter System:**
- `scripts/autoloads/encounter_manager.gd` (610 lines)
- `scripts/autoloads/hexmap_state.gd` (53 lines)
- `data/encounters/` - All encounter resources
- `scenes/game/event.tscn`, `encounter_outcome.tscn`

These can be re-enabled by:
1. Uncommenting autoloads in `project.godot`
2. Restoring scene paths in SceneManager
3. Removing guards in GameManager
