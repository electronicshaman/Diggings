extends Node

const DEBUG_ENABLED: bool = true

signal game_started()
signal game_ended(victory: bool)
signal game_paused()
signal game_resumed()

signal scene_transition_started(scene_path: String)
signal scene_transition_completed(scene_path: String)
signal scene_loaded(scene: Node)

signal duel_started(enemy_data: Resource)
signal duel_ended(victory: bool)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal phase_changed(phase: String)

signal card_played(card: Node)
signal card_drawn(card: Node)
signal card_discarded(card: Node)
signal card_exhausted(card: Node)
signal card_upgraded(card: Node)
signal card_created(card: Node)
signal card_destroyed(card: Node)
signal hand_changed(hand: Array)
signal deck_shuffled()

signal damage_dealt(target: Node, amount: int, source: Node)
signal damage_blocked(target: Node, amount: int)
signal healing_received(target: Node, amount: int)
signal status_applied(target: Node, status: String, stacks: int)
signal status_removed(target: Node, status: String)

signal energy_changed(current: int, max: int)
signal gold_changed(amount: int)
signal corruption_changed(amount: int)
signal sanity_changed(amount: int)
signal health_changed(current: int, max: int)

signal enemy_intent_revealed(intent: String)
signal enemy_action_performed(action: String)
signal enemy_defeated(enemy: Node)
signal enemy_spawned(enemy: Node)

signal reward_offered(rewards: Array)
signal reward_selected(reward: Resource)
signal shop_entered()
signal shop_exited()
signal item_purchased(item: Resource, cost: int)

signal curio_acquired(curio: Resource)
signal curio_removed(curio: Resource)
signal curio_triggered(curio: Resource, effect_name: String)
signal curio_stack_changed(curio: Resource, new_count: int)

signal node_selected(node: Node)
signal map_generated()
signal floor_completed(floor: int)
signal act_completed(act: int)

signal save_requested()
signal save_completed()
signal load_requested()
signal load_completed()

signal achievement_unlocked(achievement_id: String)
signal statistics_updated(stat_name: String, value: Variant)

signal ui_notification(message: String, type: String)
signal ui_tooltip_requested(content: String, position: Vector2)
signal ui_popup_opened(popup_type: String)
signal ui_popup_closed(popup_type: String)

signal audio_play_requested(sound_name: String)
signal music_change_requested(track_name: String)

signal debug_command_executed(command: String, args: Array)
signal error_occurred(error_message: String)

signal event_triggered(event_instance: Resource)
signal event_choice_made(event_instance: Resource, choice_index: int)
signal event_completed(event_instance: Resource)
signal event_outcome_applied(outcome: Resource)
signal event_queued(event_data: Resource)

func _ready() -> void:
	GLog.debug("EventBus initialized - The void awaits your signals")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func emit_game_event(event_name: String, args: Array = []) -> void:
	if has_signal(event_name):
		GLog.debug("Emitting event: " + event_name + " with args: " + str(args))
		if args.is_empty():
			emit_signal(event_name)
		else:
			callv("emit_signal", [event_name] + args)
	else:
		GLog.error("Unknown event: " + event_name)

func connect_safe(signal_name: StringName, callable: Callable, flags: int = 0) -> Error:
	if not is_connected(signal_name, callable):
		return connect(signal_name, callable, flags)
	else:
		GLog.warn("Signal already connected: " + str(signal_name))
		return ERR_ALREADY_EXISTS

func disconnect_safe(signal_name: StringName, callable: Callable) -> void:
	if is_connected(signal_name, callable):
		disconnect(signal_name, callable)
	else:
		GLog.warn("Signal not connected: " + str(signal_name))

func emit_damage_dealt(target: Node, amount: int, source: Node) -> void:
	damage_dealt.emit(target, amount, source)
	GLog.debug("Damage dealt: " + str(amount) + " to " + target.name + " from " + source.name)

func emit_card_played(card: Node) -> void:
	card_played.emit(card)
	GLog.debug("Card played: " + card.name)

func emit_phase_changed(new_phase: String) -> void:
	phase_changed.emit(new_phase)
	GLog.debug("Phase changed to: " + new_phase)

func emit_ui_notification(message: String, notification_type: String = "info") -> void:
	ui_notification.emit(message, notification_type)
	GLog.debug("UI notification: [" + notification_type + "] " + message)

func emit_error(error_message: String) -> void:
	error_occurred.emit(error_message)
	GLog.error("Error event: " + error_message)