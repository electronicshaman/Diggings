# Encounter Flow

Last verified: 2025-08-18

This document describes how encounters are loaded, selected, triggered, and completed. Source: `scripts/autoloads/encounter_manager.gd` and `data/encounters/*`.

## Data Loading

- Directories scanned:
  - `res://data/encounters/common/`
  - `res://data/encounters/rare/`
  - `res://data/encounters/legendary/`
  - `res://data/encounters/story/`
  - `res://data/encounters/region_specific/`
- Files loaded: all `.tres` EncounterData resources in those folders.
- Categorization:
  - `events_by_rarity[rarity]` built from `EncounterData.rarity`.
  - `events_by_region[region]` built from `EncounterData.regional_weights[region] > 0`.

## Trigger Paths

- Direct trigger: `trigger_encounter(encounter_data, force = false)`
- Random trigger: `trigger_random_event(region = "", rarity = "")`
- Tile-based trigger: `trigger_tile_encounter(tile)` then `trigger_encounter`
- Context-based trigger: `trigger_from_context(encounter_context)` that routes to tile or direct

## Eligibility Rules

- Uses `_get_current_game_state()` from GameManager and PlayerData.
- `EncounterData.can_trigger(game_state)` must return true unless `force` is used.
- Repeat limits:
  - `event.repeatable` allows multiple triggers
  - `event.max_occurrences` enforces a hard cap
  - `events_encountered[name]` tracked per run
- Regional weighting: multiplies base `event.weight` by `event.get_weight_for_region(region)`
- Karma modifier: multiplies by `PlayerData.get_karma_modifier_for_encounter_type(event.encounter_type)` if available

## Lifecycle

1. Trigger event: `active_event = EncounterInstance.new(encounter_data)` and increment counters
2. Emit signals:
   - Local: `event_triggered(instance)`
   - Global: `EventBus.ui_popup_opened("event")`
3. Player makes choice: `make_choice(index)` → `EncounterInstance.make_choice`
4. Outcomes:
   - Apply immediately via `apply_outcome(outcome)`
   - Or queue delayed outcomes `{ outcome, turns_remaining, context }`
5. Completion:
   - Mark instance complete, append to history, emit `event_completed`
   - Close UI: `EventBus.ui_popup_closed("event")`
   - Optionally show reward summary via `ModalManager`
6. Process queued events: `_process_event_queue()` triggers next pending encounter

## Signals

- EncounterManager emits:
  - `event_triggered(EncounterInstance)`
  - `event_choice_made(EncounterInstance, int)`
  - `event_completed(EncounterInstance)`
  - `event_outcome_applied(EncounterOutcome)`
- EventBus used for UI integration:
  - `ui_popup_opened("event")`
  - `ui_popup_closed("event")`

## Save/Load

- Saves:
  - `events_encountered`
  - `event_history[]` (serialized instance data)
  - `delayed_outcomes[]` (outcome path, turns, context)
  - `active_event` (if any)
- Loads the same and rehydrates instances/outcomes when resources exist.

## Debug Utilities

- `debug_trigger_encounter(encounter_name: String)`
- `debug_list_events()` prints name, rarity, and type; shows total count.

## Integration Points

- Hex map: `_on_node_selected(node)` triggers random event when `node_type == "event"`.
- Story flow: `_on_act_completed(act)` queues Story events with `min_act == act`.
- ModalManager: `show_reward_summary(reward_data)` if rewards are meaningful.
