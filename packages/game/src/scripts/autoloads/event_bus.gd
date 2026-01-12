extends Node

const DEBUG_ENABLED: bool = true
const VERBOSE_EVENTS: bool = false # Set to true to see high-frequency event logs

signal game_started()
signal game_ended(victory: bool)
signal game_paused()
signal game_resumed()

signal scene_transition_started(scene_path: String)
signal scene_transition_completed(scene_path: String)
signal scene_loaded(scene: Node)

signal duel_started(enemy_data: Resource)
signal duel_ended(victory: bool)
signal turn_started(turn_number: int, is_player_turn: bool)
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
signal damage_taken(target: Object, amount: int)
signal damage_blocked(target: Node, amount: int)
signal healing_received(target: Node, amount: int)
signal status_applied(target: Object, status: String, stacks: int)
signal status_removed(target: Object, status: String)
signal status_triggered(target: Object, effect_id: String, value: float)
signal status_stacks_changed(target: Object, effect_id: String, old_stacks: int, new_stacks: int)

signal energy_changed(current: int, max: int)
signal gold_changed(amount: int)
signal corruption_changed(amount: int)
signal sanity_changed(amount: int)
signal health_changed(current: int, max: int)
# Generic class resource signals (Ammo, Faith, Fever, Scent, Brew, etc.)
signal resource_gained(player: Object, resource_type: GameEnums.CustomResourceType, amount: int)
signal resource_spent(player: Object, resource_type: GameEnums.CustomResourceType, amount: int)
signal resource_changed(player: Object, resource_type: GameEnums.CustomResourceType, current: int, max_val: int)
signal gambling_modifier_query(player_data: Object, context: Dictionary)

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

signal encounter_triggered(encounter_instance: Resource)
signal encounter_choice_made(encounter_instance: Resource, choice_index: int)
signal encounter_completed(encounter_instance: Resource)
signal encounter_outcome_applied(outcome: Resource)
signal encounter_queued(encounter_data: Resource)

signal modal_requested(modal_type: String, data: Dictionary)
signal modal_opened(modal_type: String)
signal modal_closed(modal_type: String, result: Variant)

func _ready() -> void:
	GLog.debug("EventBus initialized - The void awaits your signals")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)

func emit_game_event(event_name: String, args: Array = []) -> void:
	if has_signal(event_name):
		if VERBOSE_EVENTS:
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

func emit_game_started() -> void:
	game_started.emit()
	GLog.info("Game started")

func emit_game_ended(victory: bool) -> void:
	game_ended.emit(victory)
	GLog.info("Game ended. Victory: " + str(victory))

func emit_game_paused() -> void:
	game_paused.emit()
	GLog.info("Game paused")

func emit_game_resumed() -> void:
	game_resumed.emit()
	GLog.info("Game resumed")

func emit_scene_transition_started(scene_path: String) -> void:
	scene_transition_started.emit(scene_path)
	GLog.info("Scene transition started to: " + scene_path)

func emit_scene_transition_completed(scene_path: String) -> void:
	scene_transition_completed.emit(scene_path)
	GLog.info("Scene transition completed to: " + scene_path)

func emit_scene_loaded(scene: Node) -> void:
	scene_loaded.emit(scene)
	GLog.info("Scene loaded: " + str(scene))

func emit_duel_started(enemy_data: Resource) -> void:
	duel_started.emit(enemy_data)
	GLog.info("Duel started against: " + (enemy_data.resource_path if enemy_data else "Unknown"))

func emit_duel_ended(victory: bool) -> void:
	duel_ended.emit(victory)
	GLog.info("Duel ended. Victory: " + str(victory))

func emit_turn_started(turn_number: int, is_player_turn: bool) -> void:
	turn_started.emit(turn_number, is_player_turn)
	if VERBOSE_EVENTS:
		GLog.debug("Turn " + str(turn_number) + " started. Player turn: " + str(is_player_turn))

func emit_turn_ended(turn_number: int) -> void:
	turn_ended.emit(turn_number)
	if VERBOSE_EVENTS:
		GLog.debug("Turn " + str(turn_number) + " ended")

func emit_card_played(card: Node) -> void:
	card_played.emit(card)
	GLog.info("Card played: " + card.name) # Keeping this as info/visible as it's a key action

func emit_card_drawn(card: Node) -> void:
	card_drawn.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card drawn: " + card.name)

func emit_card_discarded(card: Node) -> void:
	card_discarded.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card discarded: " + card.name)

func emit_card_exhausted(card: Node) -> void:
	card_exhausted.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card exhausted: " + card.name)

func emit_card_upgraded(card: Node) -> void:
	card_upgraded.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card upgraded: " + card.name)

func emit_card_created(card: Node) -> void:
	card_created.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card created: " + card.name)

func emit_card_destroyed(card: Node) -> void:
	card_destroyed.emit(card)
	if VERBOSE_EVENTS:
		GLog.debug("Card destroyed: " + card.name)

func emit_hand_changed(hand: Array) -> void:
	hand_changed.emit(hand)
	# Verbose logging avoided for frequent updates
	# if VERBOSE_EVENTS: GLog.debug("Hand changed. Size: " + str(hand.size()))

func emit_deck_shuffled() -> void:
	deck_shuffled.emit()
	GLog.info("Deck shuffled")

func emit_damage_dealt(target: Node, amount: int, source: Node) -> void:
	damage_dealt.emit(target, amount, source)
	if VERBOSE_EVENTS:
		GLog.debug("Damage dealt: " + str(amount) + " to " + target.name + " from " + (source.name if source else "Unknown"))

func emit_damage_taken(target: Object, amount: int) -> void:
	damage_taken.emit(target, amount)
	if VERBOSE_EVENTS:
		GLog.debug("Damage taken: " + str(amount) + " by " + (target.name if "name" in target else str(target)))

func emit_damage_blocked(target: Node, amount: int) -> void:
	damage_blocked.emit(target, amount)
	if VERBOSE_EVENTS:
		GLog.debug("Damage blocked: " + str(amount) + " by " + target.name)

func emit_healing_received(target: Node, amount: int) -> void:
	healing_received.emit(target, amount)
	if VERBOSE_EVENTS:
		GLog.debug("Healing received: " + str(amount) + " by " + target.name)

func emit_status_applied(target: Object, status: String, stacks: int) -> void:
	status_applied.emit(target, status, stacks)
	if VERBOSE_EVENTS:
		var target_name := _get_target_name(target)
		GLog.debug("Status applied: " + status + " (" + str(stacks) + ") to " + target_name)


func emit_status_removed(target: Object, status: String) -> void:
	status_removed.emit(target, status)
	if VERBOSE_EVENTS:
		var target_name := _get_target_name(target)
		GLog.debug("Status removed: " + status + " from " + target_name)


func emit_status_triggered(target: Object, effect_id: String, value: float) -> void:
	status_triggered.emit(target, effect_id, value)
	if VERBOSE_EVENTS:
		var target_name := _get_target_name(target)
		GLog.debug("Status triggered: " + effect_id + " (" + str(value) + ") on " + target_name)


func emit_status_stacks_changed(target: Object, effect_id: String, old_stacks: int, new_stacks: int) -> void:
	status_stacks_changed.emit(target, effect_id, old_stacks, new_stacks)
	if VERBOSE_EVENTS:
		var target_name := _get_target_name(target)
		GLog.debug("Status stacks changed: " + effect_id + " " + str(old_stacks) + " -> " + str(new_stacks) + " on " + target_name)


func _get_target_name(target: Object) -> String:
	"""Helper to get a display name for any target (Node or Resource)"""
	if target == null:
		return "Unknown"
	if target is Node:
		return target.name
	if "enemy_name" in target and target.enemy_name:
		return target.enemy_name
	if "character_class_name" in target and target.character_class_name:
		return target.character_class_name
	return "Entity"

func emit_phase_changed(new_phase: String) -> void:
	phase_changed.emit(new_phase)
	if VERBOSE_EVENTS:
		GLog.debug("Phase changed to: " + new_phase)

func emit_energy_changed(current: int, max_val: int) -> void:
	energy_changed.emit(current, max_val)
	# if VERBOSE_EVENTS: GLog.debug("Energy changed: " + str(current) + "/" + str(max_val))

func emit_gold_changed(amount: int) -> void:
	gold_changed.emit(amount)
	if VERBOSE_EVENTS:
		GLog.debug("Gold changed: " + str(amount))

func emit_corruption_changed(amount: int) -> void:
	corruption_changed.emit(amount)
	if VERBOSE_EVENTS:
		GLog.debug("Corruption changed: " + str(amount))

func emit_sanity_changed(amount: int) -> void:
	sanity_changed.emit(amount)
	if VERBOSE_EVENTS:
		GLog.debug("Sanity changed: " + str(amount))

func emit_health_changed(current: int, max_val: int) -> void:
	health_changed.emit(current, max_val)
	# if VERBOSE_EVENTS: GLog.debug("Health changed: " + str(current) + "/" + str(max_val))

func emit_resource_gained(player: Object, resource_type: GameEnums.CustomResourceType, amount: int) -> void:
	resource_gained.emit(player, resource_type, amount)
	if VERBOSE_EVENTS:
		GLog.debug("Resource gained: " + str(resource_type) + " (" + str(amount) + ")")

func emit_resource_spent(player: Object, resource_type: GameEnums.CustomResourceType, amount: int) -> void:
	resource_spent.emit(player, resource_type, amount)
	if VERBOSE_EVENTS:
		GLog.debug("Resource spent: " + str(resource_type) + " (" + str(amount) + ")")

func emit_resource_changed(player: Object, resource_type: GameEnums.CustomResourceType, current: int, max_val: int) -> void:
	resource_changed.emit(player, resource_type, current, max_val)
	# if VERBOSE_EVENTS: GLog.debug("Resource changed: " + str(resource_type) + " " + str(current) + "/" + str(max_val))

func emit_gambling_modifier_query(player_data: Object, context: Dictionary) -> void:
	gambling_modifier_query.emit(player_data, context)

func emit_enemy_intent_revealed(intent: String) -> void:
	enemy_intent_revealed.emit(intent)
	if VERBOSE_EVENTS:
		GLog.debug("Enemy intent revealed: " + intent)

func emit_enemy_action_performed(action: String) -> void:
	enemy_action_performed.emit(action)
	if VERBOSE_EVENTS:
		GLog.debug("Enemy action performed: " + action)

func emit_enemy_defeated(enemy: Node) -> void:
	enemy_defeated.emit(enemy)
	GLog.info("Enemy defeated: " + enemy.name)

func emit_enemy_spawned(enemy: Node) -> void:
	enemy_spawned.emit(enemy)
	GLog.info("Enemy spawned: " + enemy.name)

func emit_reward_offered(rewards: Array) -> void:
	reward_offered.emit(rewards)
	GLog.debug("Rewards offered: " + str(rewards.size()))

func emit_reward_selected(reward: Resource) -> void:
	reward_selected.emit(reward)
	GLog.info("Reward selected: " + str(reward))

func emit_shop_entered() -> void:
	shop_entered.emit()
	GLog.debug("Shop entered")

func emit_shop_exited() -> void:
	shop_exited.emit()
	GLog.debug("Shop exited")

func emit_item_purchased(item: Resource, cost: int) -> void:
	item_purchased.emit(item, cost)
	GLog.info("Item purchased: " + str(item) + " for " + str(cost))

func emit_curio_acquired(curio: Resource) -> void:
	curio_acquired.emit(curio)
	GLog.info("Curio acquired: " + (curio.resource_path if curio else "Unknown"))

func emit_curio_removed(curio: Resource) -> void:
	curio_removed.emit(curio)
	GLog.info("Curio removed: " + (curio.resource_path if curio else "Unknown"))

func emit_curio_triggered(curio: Resource, effect_name: String) -> void:
	curio_triggered.emit(curio, effect_name)
	if VERBOSE_EVENTS:
		GLog.debug("Curio triggered: " + (curio.resource_path if curio else "Unknown") + " - " + effect_name)

func emit_curio_stack_changed(curio: Resource, new_count: int) -> void:
	curio_stack_changed.emit(curio, new_count)
	if VERBOSE_EVENTS:
		GLog.debug("Curio stack changed: " + (curio.resource_path if curio else "Unknown") + " to " + str(new_count))

func emit_node_selected(node: Node) -> void:
	node_selected.emit(node)
	if VERBOSE_EVENTS:
		GLog.debug("Node selected: " + node.name)

func emit_map_generated() -> void:
	map_generated.emit()
	GLog.info("Map generated")

func emit_floor_completed(floor_num: int) -> void:
	floor_completed.emit(floor_num)
	GLog.info("Floor completed: " + str(floor_num))

func emit_act_completed(act_num: int) -> void:
	act_completed.emit(act_num)
	GLog.info("Act completed: " + str(act_num))

func emit_save_requested() -> void:
	save_requested.emit()
	GLog.info("Save requested")

func emit_save_completed() -> void:
	save_completed.emit()
	GLog.info("Save completed")

func emit_load_requested() -> void:
	load_requested.emit()
	GLog.info("Load requested")

func emit_load_completed() -> void:
	load_completed.emit()
	GLog.info("Load completed")

func emit_achievement_unlocked(achievement_id: String) -> void:
	achievement_unlocked.emit(achievement_id)
	GLog.info("Achievement unlocked: " + achievement_id)

func emit_statistics_updated(stat_name: String, value: Variant) -> void:
	statistics_updated.emit(stat_name, value)
	# if VERBOSE_EVENTS: GLog.debug("Stat updated: " + stat_name + " = " + str(value))

func emit_ui_notification(message: String, notification_type: String = "info") -> void:
	ui_notification.emit(message, notification_type)
	if VERBOSE_EVENTS:
		GLog.debug("UI notification: [" + notification_type + "] " + message)

func emit_ui_tooltip_requested(content: String, position: Vector2) -> void:
	ui_tooltip_requested.emit(content, position)

func emit_ui_popup_opened(popup_type: String) -> void:
	ui_popup_opened.emit(popup_type)
	if VERBOSE_EVENTS:
		GLog.debug("Popup opened: " + popup_type)

func emit_ui_popup_closed(popup_type: String) -> void:
	ui_popup_closed.emit(popup_type)
	if VERBOSE_EVENTS:
		GLog.debug("Popup closed: " + popup_type)

func emit_audio_play_requested(sound_name: String) -> void:
	audio_play_requested.emit(sound_name)

func emit_music_change_requested(track_name: String) -> void:
	music_change_requested.emit(track_name)
	GLog.debug("Music change requested: " + track_name)

func emit_debug_command_executed(command: String, args: Array) -> void:
	debug_command_executed.emit(command, args)
	GLog.info("Debug command: " + command + " " + str(args))

func emit_error(error_message: String) -> void:
	error_occurred.emit(error_message)
	GLog.error("Error event: " + error_message)

func emit_encounter_triggered(encounter_instance: Resource) -> void:
	encounter_triggered.emit(encounter_instance)
	GLog.info("Encounter triggered")

func emit_encounter_choice_made(encounter_instance: Resource, choice_index: int) -> void:
	encounter_choice_made.emit(encounter_instance, choice_index)
	GLog.info("Encounter choice made: " + str(choice_index))

func emit_encounter_completed(encounter_instance: Resource) -> void:
	encounter_completed.emit(encounter_instance)
	GLog.info("Encounter completed")

func emit_encounter_outcome_applied(outcome: Resource) -> void:
	encounter_outcome_applied.emit(outcome)
	if VERBOSE_EVENTS:
		GLog.debug("Encounter outcome applied")

func emit_encounter_queued(encounter_data: Resource) -> void:
	encounter_queued.emit(encounter_data)
	if VERBOSE_EVENTS:
		GLog.debug("Encounter queued")

func emit_modal_requested(modal_type: String, data: Dictionary) -> void:
	modal_requested.emit(modal_type, data)
	GLog.debug("Modal requested: " + modal_type)

func emit_modal_opened(modal_type: String) -> void:
	modal_opened.emit(modal_type)
	GLog.debug("Modal opened: " + modal_type)

func emit_modal_closed(modal_type: String, result: Variant) -> void:
	modal_closed.emit(modal_type, result)
	GLog.debug("Modal closed: " + modal_type)
