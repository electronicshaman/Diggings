# Refactoring Plan: Quick Duel Rebranding and Codebase Cleanup

## Summary

Refactor the codebase to:

1. Rename "Test Duel" to "Quick Duel" and promote to primary game mode
2. Archive hexmap/encounter systems to separate branch, then remove from main
3. Remove preview mode logic from victory rewards
4. Remove unused autoloads: MapNodeRegistry, HexmapState, EncounterManager

---

## Phase 1: Git Setup for Hexmap Archival

### 1.1 Create archive branch

```bash
git checkout -b archive/hexmap-system
git push origin archive/hexmap-system
git checkout refactor/deck-instances
```

---

## Phase 2: Rename Test Duel to Quick Duel

### 2.1 Move/Rename Files

| From | To |
|------|-----|
| `src/scenes/debug/test_duel_setup.tscn` | `src/scenes/game/quick_duel_setup.tscn` |
| `src/scripts/debug/test_duel_setup.gd` | `src/scripts/ui/quick_duel_setup.gd` |
| `src/scripts/data/test_sequence_state.gd` | `src/scripts/data/duel_sequence_state.gd` |
| `src/scripts/combat/test_sequence_handler.gd` | `src/scripts/combat/duel_sequence_handler.gd` |

**Delete:**

- `src/scenes/debug/test_duel.tscn`
- `src/scripts/debug/test_duel_bootstrap.gd`

### 2.2 Update Class Names

- `TestDuelSetupController` → `QuickDuelSetupController`
- `TestSequenceState` → `DuelSequenceState`
- `TestSequenceHandler` → `DuelSequenceHandler`

### 2.3 Update Main Menu

**File:** `src/scripts/ui/main_menu.gd`

- Rename `test_duel_button` → `quick_duel_button`
- Rename `_on_test_duel_pressed()` → `_on_quick_duel_pressed()`
- Update scene path: `res://scenes/game/quick_duel_setup.tscn`

**File:** `src/scenes/ui/main_menu.tscn`

- Rename node `TestDuelButton` → `QuickDuelButton`
- Update button text: "Quick Duel"

### 2.4 Global Search/Replace

| Find | Replace |
|------|---------|
| `test_sequence_state` | `duel_sequence_state` |
| `TestSequenceState` | `DuelSequenceState` |
| `TestSequenceHandler` | `DuelSequenceHandler` |
| `is_test_duel` | `is_quick_duel` |
| `show_test_rewards` | `show_quick_duel_rewards` |
| `res://scenes/debug/test_duel_setup.tscn` | `res://scenes/game/quick_duel_setup.tscn` |

**Files affected:**

- `src/scripts/autoloads/game_manager.gd`
- `src/scripts/combat/duel_sequence_handler.gd` (after rename)
- `src/scripts/ui/quick_duel_setup.gd` (after rename)
- `src/scripts/ui/victory_reward.gd`
- `src/scripts/core/intents/duel_intent.gd`
- `src/scripts/core/intents/reward_intent.gd`
- `src/scripts/managers/duel_manager.gd`

---

## Phase 3: Remove Preview Mode Logic

### 3.1 Simplify Victory Reward

**File:** `src/scripts/ui/victory_reward.gd`

**Remove:**

- Variable `is_test_sequence_preview: bool`
- Legacy game_data flag checks (`test_sequence_preview`, `continue_test_sequence`)
- Preview mode title modification ("Victory! (Preview - Deck Unchanged)")
- Preview mode checks that skip deck modification in `_add_card_to_deck()`
- Preview mode branches in `_complete_card_reward()` and `_finish_and_return_to_map()`

### 3.2 Simplify RewardIntent

**File:** `src/scripts/core/intents/reward_intent.gd`

**Remove:**

- Variable `is_preview_mode: bool`
- Rename factory: `create_test_preview()` → `create_quick_duel_reward()`

---

## Phase 4: Remove Unused Autoloads

### 4.1 Update project.godot

**File:** `src/project.godot`

**Remove lines:**

```ini
HexmapState="*res://scripts/autoloads/hexmap_state.gd"
MapNodeRegistry="*res://scripts/autoloads/map_node_registry.gd"
EncounterManager="*res://scripts/autoloads/encounter_manager.gd"
```

### 4.2 Delete Autoload Scripts

- `src/scripts/autoloads/hexmap_state.gd`
- `src/scripts/autoloads/map_node_registry.gd`
- `src/scripts/autoloads/encounter_manager.gd`

### 4.3 Update SceneManager

**File:** `src/scripts/autoloads/scene_manager.gd`

**Remove from SCENE_PATHS:**

```gdscript
"map": "res://scenes/hexmap/hexmap.tscn",
"event": "res://scenes/game/event.tscn",
"encounter_outcome": "res://scenes/game/encounter_outcome.tscn",
```

**Add:**

```gdscript
"quick_duel_setup": "res://scenes/game/quick_duel_setup.tscn",
```

### 4.4 Clean Up GameManager

**File:** `src/scripts/autoloads/game_manager.gd`

**Remove HexmapState references** (get_node_or_null calls and conditional blocks)

---

## Phase 5: Delete Archived Files

### 5.1 Hexmap System

```
rm -rf src/scripts/hexmap/
rm -rf src/data/hexmap/
rm -rf src/scenes/hexmap/
```

### 5.2 Encounter System

```
rm -rf src/data/encounters/
rm src/scripts/ui/event.gd
rm src/scripts/ui/encounter_outcome.gd
rm src/scenes/game/event.tscn
rm src/scenes/game/encounter_outcome.tscn
```

### 5.3 Deprecated Debug Files

```
rm src/scenes/debug/test_duel.tscn
rm src/scripts/debug/test_duel_bootstrap.gd
```

---

## Phase 6: Verification

### 6.1 Search for Remaining References

```bash
grep -r "test_duel" src/ --include="*.gd" --include="*.tscn"
grep -r "hexmap" src/ --include="*.gd" --include="*.tscn"
grep -r "HexmapState" src/ --include="*.gd"
grep -r "EncounterManager" src/ --include="*.gd"
grep -r "test_sequence_preview" src/ --include="*.gd"
```

### 6.2 Test Quick Duel Flow

1. Launch game from main menu
2. Click "Quick Duel" button
3. Select character, deck, enemies, curios
4. Start duel, complete battle
5. Verify rewards work (cards ARE added to deck - no preview skip)
6. Test multi-enemy sequence with rewards enabled

### 6.3 Run Godot Editor

- Check for parser errors
- Verify scene loads without missing dependencies

---

## Critical Files

| File | Changes |
|------|---------|
| `src/project.godot` | Remove 3 autoloads |
| `src/scripts/ui/main_menu.gd` | Rename button, update handler |
| `src/scripts/ui/victory_reward.gd` | Remove preview mode, update paths |
| `src/scripts/autoloads/game_manager.gd` | Rename variables, remove HexmapState refs |
| `src/scripts/autoloads/scene_manager.gd` | Update SCENE_PATHS |
| `src/scripts/combat/test_sequence_handler.gd` | Rename to duel_sequence_handler.gd |
| `src/scripts/data/test_sequence_state.gd` | Rename to duel_sequence_state.gd |
| `src/scripts/debug/test_duel_setup.gd` | Move to ui/quick_duel_setup.gd |

---

## Implementation Order

1. Create archive branch (Phase 1)
2. Rename/move files (Phase 2.1)
3. Update class names and references (Phase 2.2-2.4)
4. Remove preview mode logic (Phase 3)
5. Update project.godot autoloads (Phase 4.1)
6. Remove autoload references from code (Phase 4.2-4.4)
7. Delete hexmap and encounter files (Phase 5)
8. Verification (Phase 6)
