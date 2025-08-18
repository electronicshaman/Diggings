extends Node

const DEBUG_ENABLED: bool = true
const EffectContext = preload("res://scripts/effects/core/effect_context.gd")
const EncounterOutcomeScript = preload("res://scripts/data/encounter_outcome.gd")

signal event_triggered(event_instance: EncounterInstance)
signal event_choice_made(event_instance: EncounterInstance, choice_index: int)
signal event_completed(event_instance: EncounterInstance)
signal event_outcome_applied(effect)

var active_event: EncounterInstance = null
var event_queue: Array[EncounterInstance] = []
var event_history: Array[EncounterInstance] = []
var events_encountered: Dictionary = {}
var encountered_ids: Dictionary = {}
var delayed_outcomes: Array[Dictionary] = []

var event_bus: Node = null
var game_manager: Node = null
var curio_manager: Node = null
var scene_manager: Node = null

var all_events: Array[EncounterData] = []
var events_by_region: Dictionary = {}
var events_by_rarity: Dictionary = {}

# Note: Karma system moved to PlayerData for proper run-specific storage

func _ready() -> void:
	GLog.debug("EventManager initialized - The fates conspire...")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	event_bus = get_node("/root/EventBus") if has_node("/root/EventBus") else null
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	curio_manager = get_node("/root/CurioManager") if has_node("/root/CurioManager") else null
	scene_manager = get_node("/root/SceneManager") if has_node("/root/SceneManager") else null
	
	_load_all_events()
	_categorize_events()
	
	if event_bus:
		setup_event_connections()

func setup_event_connections() -> void:
	event_bus.connect_safe("turn_started", _on_turn_started)
	event_bus.connect_safe("node_selected", _on_node_selected)
	event_bus.connect_safe("act_completed", _on_act_completed)
	event_bus.connect_safe("game_started", _on_game_started)

func _load_all_events() -> void:
	var event_paths = [
		"res://data/encounters/common/",
		"res://data/encounters/rare/",
		"res://data/encounters/legendary/",
		"res://data/encounters/story/",
		"res://data/encounters/region_specific/"
	]
	
	for base_path in event_paths:
		_load_events_from_directory(base_path)
	
	GLog.debug("Loaded %d total events" % all_events.size())

func _load_events_from_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var event_path = dir_path + file_name
			var event = load(event_path) as EncounterData
			if event:
				all_events.append(event)
				GLog.debug("Loaded event: %s" % event.encounter_name)
		file_name = dir.get_next()

func _categorize_events() -> void:
	events_by_region.clear()
	events_by_rarity.clear()
	
	for event in all_events:
		if not event.rarity in events_by_rarity:
			events_by_rarity[event.rarity] = []
		events_by_rarity[event.rarity].append(event)
		
		for region in event.regional_weights:
			if not region in events_by_region:
				events_by_region[region] = []
			if event.regional_weights[region] > 0:
				events_by_region[region].append(event)

func trigger_encounter(encounter_data: EncounterData, force: bool = false) -> EncounterInstance:
	var game_state = _get_current_game_state()

	# Prevent duplicates within a run based on encounter_id unless forced
	var _eid: String = ""
	if encounter_data:
		_eid = str(encounter_data.get_encounter_id())
	if not force and _eid != "" and encountered_ids.has(_eid):
		GLog.debug("Event '%s' with id '%s' already encountered this run" % [encounter_data.encounter_name, _eid])
		return null
    
	if not force and not encounter_data.can_trigger(game_state):
		GLog.debug("Event '%s' cannot trigger - requirements not met" % encounter_data.encounter_name)
		return null
    
	var instance = EncounterInstance.new(encounter_data)
	instance.increment_encounter_count()
    
	if events_encountered.has(encounter_data.encounter_name):
		events_encountered[encounter_data.encounter_name] += 1
	else:
		events_encountered[encounter_data.encounter_name] = 1

	if _eid != "":
		encountered_ids[_eid] = encountered_ids.get(_eid, 0) + 1
    
	active_event = instance
	event_triggered.emit(instance)
    
	if event_bus:
		event_bus.emit_signal("ui_popup_opened", "event")
    
	GLog.debug("Triggered event: %s" % encounter_data.encounter_name)
	return instance

func trigger_random_event(region: String = "", rarity: String = "") -> EncounterInstance:
	var game_state = _get_current_game_state()
	var eligible_events = []
	
	if region != "" and region in events_by_region:
		eligible_events = events_by_region[region].duplicate()
	elif rarity != "" and rarity in events_by_rarity:
		eligible_events = events_by_rarity[rarity].duplicate()
	else:
		eligible_events = all_events.duplicate()
	
	eligible_events = eligible_events.filter(func(e): return e.can_trigger(game_state))

	# Filter by run-scoped encountered IDs to avoid repeats
	eligible_events = eligible_events.filter(func(e):
		var eid: String = str(e.get_encounter_id())
		if eid == "":
			return true
		return not encountered_ids.has(eid)
	)
	
	if eligible_events.is_empty():
		GLog.debug("No eligible events found for region: %s, rarity: %s" % [region, rarity])
		return null
	
	var weighted_events = []
	var total_weight = 0.0
	
	for event in eligible_events:
		var weight = event.weight
		if region != "":
			weight *= event.get_weight_for_region(region)
		# Apply karma-based weight modifier from PlayerData
		weight *= _get_karma_modifier_for_encounter(event)
		total_weight += weight
		weighted_events.append({"event": event, "weight": weight})
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for entry in weighted_events:
		cumulative_weight += entry.weight
		if random_value <= cumulative_weight:
			return trigger_encounter(entry.event)
	
	return trigger_encounter(weighted_events[-1].event)

func make_choice(choice_index: int) -> void:
	if not active_event:
		GLog.error("No active event to make choice for")
		return
	
	var game_state = _get_current_game_state()
	var outcomes = active_event.make_choice(choice_index, game_state)
	
	event_choice_made.emit(active_event, choice_index)
	
	# Track rewards from outcomes for summary
	var reward_data = {
		"gold": 0,
		"karma_changes": {},
		"total_karma": 0,
		"corruption": 0,
		"cards": [],
		"curios": [],
		"custom_rewards": []
	}
	
	for effect in outcomes:
		if effect:
			_track_effect_rewards(effect, reward_data)
			apply_effect(effect)
	
	complete_current_event(reward_data)

func apply_effect(effect: Resource, extra_context: Dictionary = {}) -> void:
	if not effect:
		return
	# Basic delayed support if present on the effect
	var _delayed_val = effect.get("delayed")
	var is_delayed = (_delayed_val if _delayed_val != null else false)
	var _delay_val = effect.get("delay_turns")
	var delay_turns = int(_delay_val if _delay_val != null else 0)
	if is_delayed and delay_turns > 0:
		delayed_outcomes.append({
			"effect": effect,
			"turns_remaining": delay_turns,
			"context": extra_context
		})
		GLog.debug("Delayed effect for %d turns" % delay_turns)
		return

	# Legacy compatibility: support EncounterOutcome during migration
	if effect is EncounterOutcomeScript:
		var game_state = _get_current_game_state()
		effect.apply_outcome(self, game_state, extra_context)
		event_outcome_applied.emit(effect)
		if event_bus and effect.has_method("get_notification_text"):
			event_bus.ui_notification.emit(effect.get_notification_text(), "info")
		return

	# Build EffectContext for GameEffect
	var ctx = EffectContext.new()
	ctx.source_type = "encounter"
	ctx.source_object = active_event.encounter_data if active_event and active_event.encounter_data else null
	ctx.game_manager = game_manager
	ctx.player_data = _get_player_data()
	ctx.trigger_event = "encounter_choice"
	ctx.trigger_data = extra_context

	if effect.has_method("apply_effect"):
		var result = effect.apply_effect(ctx)
		event_outcome_applied.emit(effect)
		if event_bus and result and result.ui_feedback and result.ui_feedback.has("message"):
			event_bus.ui_notification.emit(str(result.ui_feedback.message), "info")

func complete_current_event(reward_data: Dictionary = {}) -> void:
	if not active_event:
		return
	
	active_event.mark_completed()
	event_history.append(active_event)
	event_completed.emit(active_event)
	
	if event_bus:
		event_bus.emit_signal("ui_popup_closed", "event")
	
	GLog.debug("Completed event: %s" % active_event.get_encounter_name())
	
	# Show reward summary if there are meaningful rewards
	if _has_meaningful_rewards(reward_data):
		var modal_manager = get_node_or_null("/root/ModalManager")
		if modal_manager:
			GLog.debug("Showing reward summary modal")
			modal_manager.show_reward_summary(reward_data)
		else:
			GLog.warn("ModalManager not found, skipping reward summary")
	
	active_event = null
	_process_event_queue()

func queue_event(encounter_data: EncounterData) -> void:
	# Skip if already seen in this run by ID
	var eid: String = str(encounter_data.get_encounter_id()) if encounter_data else ""
	if eid != "" and encountered_ids.has(eid):
		GLog.debug("Skipping queue for already-seen encounter '%s' (id %s)" % [encounter_data.encounter_name, eid])
		return
	var instance = EncounterInstance.new(encounter_data)
	event_queue.append(instance)
	GLog.debug("Queued event: %s" % encounter_data.encounter_name)

func _process_event_queue() -> void:
	if event_queue.is_empty() or active_event != null:
		return
	
	var next_event = event_queue.pop_front()
	if next_event and next_event.encounter_data:
		trigger_encounter(next_event.encounter_data)

func _get_current_game_state() -> Dictionary:
	var state = {}
	
	if game_manager:
		# Access values from game_manager.game_data dictionary
		state["gold"] = game_manager.game_data.get("gold", 0)
		state["corruption"] = game_manager.game_data.get("corruption", 0)
		state["current_act"] = game_manager.game_data.get("current_act", 1)
		state["current_floor"] = game_manager.game_data.get("current_floor", 0)
		state["character_class"] = game_manager.current_character_class
		state["deck"] = game_manager.game_data.get("deck", [])
		
		# Add player data if available
		if game_manager.game_data.has("player") and game_manager.game_data.player:
			var player_data = game_manager.game_data.player
			state["player_data"] = player_data
			# Provide health fields for outcomes that reference raw values
			if player_data and player_data.stats:
				state["health"] = player_data.stats.current_health
				state["max_health"] = player_data.stats.max_health
	
	if curio_manager:
		state["curios"] = []
		for curio in curio_manager.get_active_curios():
			state["curios"].append(curio.curio_name)
	
	return state

func _on_turn_started(_turn_number: int) -> void:
	var outcomes_to_apply = []
	var i = delayed_outcomes.size() - 1
	
	while i >= 0:
		delayed_outcomes[i].turns_remaining -= 1
		if delayed_outcomes[i].turns_remaining <= 0:
			outcomes_to_apply.append(delayed_outcomes[i])
			delayed_outcomes.remove_at(i)
		i -= 1
	
	for delayed in outcomes_to_apply:
		apply_effect(delayed.effect, delayed.context)

func _on_node_selected(node: Node) -> void:
	if not node:
		return
	
	var node_type = node.get("node_type") if node.has("node_type") else ""
	if node_type == "event":
		var region = game_manager.current_region if game_manager else ""
		trigger_random_event(region)

func _on_act_completed(_act: int) -> void:
	var story_events = events_by_rarity.get("Story", [])
	for event in story_events:
		if event.min_act == _act:
			queue_event(event)

func get_event_by_name(encounter_name: String) -> EncounterData:
	for event in all_events:
		if event.encounter_name == encounter_name:
			return event
	return null

func get_events_for_region(region: String) -> Array[EncounterData]:
	return events_by_region.get(region, [])

func get_events_by_rarity(rarity: String) -> Array[EncounterData]:
	return events_by_rarity.get(rarity, [])

func get_save_data() -> Dictionary:
	var save_data = {
		"events_encountered": events_encountered.duplicate(),
	"encountered_ids": encountered_ids.duplicate(),
		"event_history": [],
		"delayed_outcomes": [],
		"active_event": null
		# Note: Karma data now saved in PlayerData
	}
	
	for instance in event_history:
		save_data["event_history"].append(instance.get_save_data())
	
	for delayed in delayed_outcomes:
		var effect_path := ""
		if delayed.has("effect") and delayed.effect and typeof(delayed.effect) == TYPE_OBJECT and delayed.effect is Resource:
			effect_path = delayed.effect.resource_path if delayed.effect.resource_path else ""
		save_data["delayed_outcomes"].append({
			"effect_path": effect_path,
			"turns_remaining": delayed.turns_remaining,
			"context": delayed.context
		})
	
	if active_event:
		save_data["active_event"] = active_event.get_save_data()
	
	return save_data

func load_from_data(data: Dictionary) -> void:
	events_encountered = data.get("events_encountered", {}).duplicate()
	encountered_ids = data.get("encountered_ids", {}).duplicate()
	# Note: Karma data now loaded from PlayerData
	
	event_history.clear()
	var history_data = data.get("event_history", [])
	for instance_data in history_data:
		var instance = EncounterInstance.new()
		instance.load_from_save_data(instance_data)
		event_history.append(instance)
	
	delayed_outcomes.clear()
	var delayed_data = data.get("delayed_outcomes", [])
	for delayed in delayed_data:
		var effect_path = delayed.get("effect_path", "")
		var effect_res = null
		if effect_path != "" and ResourceLoader.exists(effect_path):
			effect_res = load(effect_path)
		if effect_res:
			delayed_outcomes.append({
				"effect": effect_res,
				"turns_remaining": delayed.get("turns_remaining", 0),
				"context": delayed.get("context", {})
			})
	
	var active_data = data.get("active_event")
	if active_data:
		active_event = EncounterInstance.new()
		active_event.load_from_save_data(active_data)
	else:
		active_event = null

	# Backwards compatibility: rebuild encountered_ids from history if not present
	if encountered_ids.is_empty() and not event_history.is_empty():
		for inst in event_history:
			if inst and inst.encounter_data:
				var rebuilt_id: String = str(inst.encounter_data.get_encounter_id())
				if rebuilt_id != "":
					encountered_ids[rebuilt_id] = encountered_ids.get(rebuilt_id, 0) + 1
	
	GLog.debug("Loaded event manager state: %d events encountered, %d in history" % [
		events_encountered.size(),
		event_history.size()
	])

func debug_trigger_encounter(encounter_name: String) -> void:
	var event = get_event_by_name(encounter_name)
	if event:
		trigger_encounter(event, true)
		GLog.debug("Debug: Triggered event '%s'" % encounter_name)
	else:
		GLog.error("Debug: Event '%s' not found" % encounter_name)

func debug_list_events() -> void:
	print("\n=== All Events ===")
	for event in all_events:
		print("- %s [%s] (%s)" % [event.encounter_name, event.rarity, event.encounter_type])
	print("Total: %d events\n" % all_events.size())

func reset_for_new_run() -> void:
	# Clear run-scoped encounter tracking and state
	encountered_ids.clear()
	events_encountered.clear()
	event_queue.clear()
	event_history.clear()
	delayed_outcomes.clear()
	active_event = null
	GLog.debug("EncounterManager reset for new run")

func _on_game_started() -> void:
	reset_for_new_run()

# ============================================================================
# KARMA HELPER FUNCTIONS (Karma data stored in PlayerData)
# ============================================================================

func _get_player_data():
	"""Get current PlayerData instance via GameManager"""
	if game_manager and game_manager.has_method("get_player_data"):
		return game_manager.get_player_data()
	return null

func _get_karma_modifier_for_encounter(encounter_data: EncounterData) -> float:
	"""Get karma-based weight modifier for encounter selection from PlayerData"""
	var player_data = _get_player_data()
	if not player_data:
		return 1.0
	
	# Use PlayerData's karma modifier method
	if player_data.has_method("get_karma_modifier_for_encounter_type"):
		return player_data.get_karma_modifier_for_encounter_type(encounter_data.encounter_type)
	
	return 1.0

# TILE ENCOUNTER SUPPORT
# ============================================================================

func trigger_tile_encounter(tile: Object) -> EncounterInstance:
	"""Trigger an encounter from tile data, creating EncounterInstance"""
	if not tile or not tile.has_method("get") or not tile.get("encounter_data"):
		GLog.error("Invalid tile or missing encounter data")
		return null
	
	var encounter_dict = tile.encounter_data
	var encounter_data: EncounterData = null
	
	# If tile has a direct EncounterData resource reference
	if encounter_dict.has("resource") and encounter_dict.resource is EncounterData:
		encounter_data = encounter_dict.resource
	# If tile has encounter data by name, look it up
	elif encounter_dict.has("encounter_name"):
		encounter_data = get_event_by_name(encounter_dict.encounter_name)
	else:
		GLog.error("Tile encounter data has no resource or encounter_name")
		return null
	
	if not encounter_data:
		GLog.error("Could not resolve encounter data from tile")
		return null
	
	# Create and trigger the encounter using existing system
	return trigger_encounter(encounter_data)

func trigger_from_context(encounter_context: Dictionary) -> EncounterInstance:
	"""Trigger encounter from any context (tile or EncounterManager)"""
	# If context already has an encounter instance (from EncounterManager)
	if encounter_context.has("encounter_instance") and encounter_context.encounter_instance:
		return encounter_context.encounter_instance
	
	# If context has tile data, process as tile encounter
	if encounter_context.has("tile") and encounter_context.tile:
		return trigger_tile_encounter(encounter_context.tile)
	
	# If context has raw encounter data, try to resolve it
	if encounter_context.has("encounter_data"):
		var encounter_dict = encounter_context.encounter_data
		
		if encounter_dict.has("resource") and encounter_dict.resource is EncounterData:
			return trigger_encounter(encounter_dict.resource)
		elif encounter_dict.has("encounter_name"):
			var encounter_data = get_event_by_name(encounter_dict.encounter_name)
			if encounter_data:
				return trigger_encounter(encounter_data)
	
	GLog.error("Could not resolve encounter from context: %s" % str(encounter_context.keys()))
	return null

# REWARD TRACKING FUNCTIONS
# ============================================================================

func _track_effect_rewards(_effect, _reward_data: Dictionary) -> void:
	# Placeholder: reward aggregation can be handled via EffectResult in apply_effect if desired
	pass

func _has_meaningful_rewards(reward_data: Dictionary) -> bool:
	"""Check if the reward data contains any meaningful rewards to display"""
	if reward_data.gold != 0:
		return true
	if reward_data.total_karma != 0:
		return true
	if reward_data.corruption != 0:
		return true
	if not reward_data.cards.is_empty():
		return true
	if not reward_data.curios.is_empty():
		return true
	if not reward_data.custom_rewards.is_empty():
		return true
	
	return false
