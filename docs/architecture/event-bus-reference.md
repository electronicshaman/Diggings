# Event Bus Reference

Last verified: 2025-08-18

This document lists the EventBus signals and helper APIs, sourced from `scripts/autoloads/event_bus.gd`.

## Signals

### Game

- game_started()
- game_ended(victory: bool)
- game_paused()
- game_resumed()

### Scene

- scene_transition_started(scene_path: String)
- scene_transition_completed(scene_path: String)
- scene_loaded(scene: Node)

### Duel

- duel_started(enemy_data: Resource)
- duel_ended(victory: bool)
- turn_started(turn_number: int)
- turn_ended(turn_number: int)
- phase_changed(phase: String)

### Cards

- card_played(card: Node)
- card_drawn(card: Node)
- card_discarded(card: Node)
- card_exhausted(card: Node)
- card_upgraded(card: Node)
- card_created(card: Node)
- card_destroyed(card: Node)
- hand_changed(hand: Array)
- deck_shuffled()

### Combat Effects

- damage_dealt(target: Node, amount: int, source: Node)
- damage_blocked(target: Node, amount: int)
- healing_received(target: Node, amount: int)
- status_applied(target: Node, status: String, stacks: int)
- status_removed(target: Node, status: String)

### Resources

- energy_changed(current: int, max: int)
- gold_changed(amount: int)
- corruption_changed(amount: int)
- sanity_changed(amount: int)
- health_changed(current: int, max: int)

### Enemies

- enemy_intent_revealed(intent: String)
- enemy_action_performed(action: String)
- enemy_defeated(enemy: Node)
- enemy_spawned(enemy: Node)

### Rewards/Shop

- reward_offered(rewards: Array)
- reward_selected(reward: Resource)
- shop_entered()
- shop_exited()
- item_purchased(item: Resource, cost: int)

### Curios

- curio_acquired(curio: Resource)
- curio_removed(curio: Resource)
- curio_triggered(curio: Resource, effect_name: String)
- curio_stack_changed(curio: Resource, new_count: int)

### Map/Run

- node_selected(node: Node)
- map_generated()
- floor_completed(floor: int)
- act_completed(act: int)

### Save/Load

- save_requested()
- save_completed()
- load_requested()
- load_completed()

### Achievements/Stats

- achievement_unlocked(achievement_id: String)
- statistics_updated(stat_name: String, value: Variant)

### UI

- ui_notification(message: String, type: String)
- ui_tooltip_requested(content: String, position: Vector2)
- ui_popup_opened(popup_type: String)
- ui_popup_closed(popup_type: String)

### Audio

- audio_play_requested(sound_name: String)
- music_change_requested(track_name: String)

### Debug

- debug_command_executed(command: String, args: Array)
- error_occurred(error_message: String)

### Encounters

- encounter_triggered(encounter_instance: Resource)
- encounter_choice_made(encounter_instance: Resource, choice_index: int)
- encounter_completed(encounter_instance: Resource)
- encounter_outcome_applied(outcome: Resource)
- encounter_queued(encounter_data: Resource)

### Modals

- modal_requested(modal_type: String, data: Dictionary)
- modal_opened(modal_type: String)
- modal_closed(modal_type: String, result: Variant)

## Helper APIs

```gdscript
func emit_game_event(event_name: String, args: Array = []) -> void
func connect_safe(signal_name: StringName, callable: Callable, flags: int = 0) -> Error
func disconnect_safe(signal_name: StringName, callable: Callable) -> void

# Convenience emitters
func emit_damage_dealt(target: Node, amount: int, source: Node) -> void
func emit_card_played(card: Node) -> void
func emit_phase_changed(new_phase: String) -> void
func emit_ui_notification(message: String, notification_type: String = "info") -> void
func emit_error(error_message: String) -> void
```

Notes:

- DEBUG output is enabled by `DEBUG_ENABLED: bool = true` in EventBus.
- EventBus is set to `Node.PROCESS_MODE_ALWAYS` to receive and emit signals regardless of scene state.
