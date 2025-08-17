extends Node

const DEBUG_ENABLED: bool = true

signal event_triggered(event_instance: EventInstance)
signal event_choice_made(event_instance: EventInstance, choice_index: int)
signal event_completed(event_instance: EventInstance)
signal event_outcome_applied(outcome: EventOutcome)

var active_event: EventInstance = null
var event_queue: Array[EventInstance] = []
var event_history: Array[EventInstance] = []
var events_encountered: Dictionary = {}
var delayed_outcomes: Array[Dictionary] = []

var event_bus: Node = null
var game_manager: Node = null
var curio_manager: Node = null
var scene_manager: Node = null

var all_events: Array[EventData] = []
var events_by_region: Dictionary = {}
var events_by_rarity: Dictionary = {}

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

func _load_all_events() -> void:
	var event_paths = [
		"res://data/events/common/",
		"res://data/events/rare/",
		"res://data/events/legendary/",
		"res://data/events/story/",
		"res://data/events/region_specific/"
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
			var event = load(event_path) as EventData
			if event:
				all_events.append(event)
				GLog.debug("Loaded event: %s" % event.event_name)
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

func trigger_event(event_data: EventData, force: bool = false) -> EventInstance:
	var game_state = _get_current_game_state()
	
	if not force and not event_data.can_trigger(game_state):
		GLog.debug("Event '%s' cannot trigger - requirements not met" % event_data.event_name)
		return null
	
	var instance = EventInstance.new(event_data)
	instance.increment_encounter_count()
	
	if events_encountered.has(event_data.event_name):
		events_encountered[event_data.event_name] += 1
	else:
		events_encountered[event_data.event_name] = 1
	
	active_event = instance
	event_triggered.emit(instance)
	
	if event_bus:
		event_bus.emit_signal("ui_popup_opened", "event")
	
	GLog.debug("Triggered event: %s" % event_data.event_name)
	return instance

func trigger_random_event(region: String = "", rarity: String = "") -> EventInstance:
	var game_state = _get_current_game_state()
	var eligible_events = []
	
	if region != "" and region in events_by_region:
		eligible_events = events_by_region[region].duplicate()
	elif rarity != "" and rarity in events_by_rarity:
		eligible_events = events_by_rarity[rarity].duplicate()
	else:
		eligible_events = all_events.duplicate()
	
	eligible_events = eligible_events.filter(func(e): return e.can_trigger(game_state))
	
	eligible_events = eligible_events.filter(func(e): 
		if not e.repeatable and events_encountered.has(e.event_name):
			return false
		if e.max_occurrences > 0:
			var count = events_encountered.get(e.event_name, 0)
			if count >= e.max_occurrences:
				return false
		return true
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
		total_weight += weight
		weighted_events.append({"event": event, "weight": weight})
	
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	for entry in weighted_events:
		cumulative_weight += entry.weight
		if random_value <= cumulative_weight:
			return trigger_event(entry.event)
	
	return trigger_event(weighted_events[-1].event)

func make_choice(choice_index: int) -> void:
	if not active_event:
		GLog.error("No active event to make choice for")
		return
	
	var game_state = _get_current_game_state()
	var outcomes = active_event.make_choice(choice_index, game_state)
	
	event_choice_made.emit(active_event, choice_index)
	
	for outcome in outcomes:
		if outcome:
			apply_outcome(outcome)
	
	complete_current_event()

func apply_outcome(outcome: EventOutcome, context: Dictionary = {}) -> void:
	if not outcome:
		return
	
	if outcome.delayed and outcome.delay_turns > 0:
		delayed_outcomes.append({
			"outcome": outcome,
			"turns_remaining": outcome.delay_turns,
			"context": context
		})
		GLog.debug("Delayed outcome '%s' for %d turns" % [outcome.get_outcome_name(), outcome.delay_turns])
		return
	
	var game_state = _get_current_game_state()
	outcome.apply_outcome(self, game_state, context)
	event_outcome_applied.emit(outcome)
	
	if event_bus and outcome.has_method("get_notification_text"):
		event_bus.ui_notification.emit(outcome.get_notification_text(), "info")

func complete_current_event() -> void:
	if not active_event:
		return
	
	active_event.mark_completed()
	event_history.append(active_event)
	event_completed.emit(active_event)
	
	if event_bus:
		event_bus.emit_signal("ui_popup_closed", "event")
	
	GLog.debug("Completed event: %s" % active_event.get_event_name())
	active_event = null
	
	_process_event_queue()

func queue_event(event_data: EventData) -> void:
	var instance = EventInstance.new(event_data)
	event_queue.append(instance)
	GLog.debug("Queued event: %s" % event_data.event_name)

func _process_event_queue() -> void:
	if event_queue.is_empty() or active_event != null:
		return
	
	var next_event = event_queue.pop_front()
	if next_event and next_event.event_data:
		trigger_event(next_event.event_data)

func _get_current_game_state() -> Dictionary:
	var state = {}
	
	if game_manager:
		state["gold"] = game_manager.gold
		state["corruption"] = game_manager.corruption
		state["sanity"] = game_manager.sanity
		state["health"] = game_manager.current_health
		state["max_health"] = game_manager.max_health
		state["max_sanity"] = game_manager.max_sanity
		state["max_corruption"] = game_manager.max_corruption
		state["character_class"] = game_manager.character_class
		state["act"] = game_manager.current_act
		state["region"] = game_manager.current_region
		state["player_name"] = game_manager.player_name
		state["deck"] = game_manager.player_deck if game_manager.has("player_deck") else []
	
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
		apply_outcome(delayed.outcome, delayed.context)

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

func get_event_by_name(event_name: String) -> EventData:
	for event in all_events:
		if event.event_name == event_name:
			return event
	return null

func get_events_for_region(region: String) -> Array[EventData]:
	return events_by_region.get(region, [])

func get_events_by_rarity(rarity: String) -> Array[EventData]:
	return events_by_rarity.get(rarity, [])

func get_save_data() -> Dictionary:
	var save_data = {
		"events_encountered": events_encountered.duplicate(),
		"event_history": [],
		"delayed_outcomes": [],
		"active_event": null
	}
	
	for instance in event_history:
		save_data["event_history"].append(instance.get_save_data())
	
	for delayed in delayed_outcomes:
		save_data["delayed_outcomes"].append({
			"outcome_path": delayed.outcome.resource_path if delayed.outcome.resource_path else "",
			"turns_remaining": delayed.turns_remaining,
			"context": delayed.context
		})
	
	if active_event:
		save_data["active_event"] = active_event.get_save_data()
	
	return save_data

func load_from_data(data: Dictionary) -> void:
	events_encountered = data.get("events_encountered", {}).duplicate()
	
	event_history.clear()
	var history_data = data.get("event_history", [])
	for instance_data in history_data:
		var instance = EventInstance.new()
		instance.load_from_save_data(instance_data)
		event_history.append(instance)
	
	delayed_outcomes.clear()
	var delayed_data = data.get("delayed_outcomes", [])
	for delayed in delayed_data:
		var outcome_path = delayed.get("outcome_path", "")
		if outcome_path != "" and ResourceLoader.exists(outcome_path):
			var outcome = load(outcome_path)
			delayed_outcomes.append({
				"outcome": outcome,
				"turns_remaining": delayed.get("turns_remaining", 0),
				"context": delayed.get("context", {})
			})
	
	var active_data = data.get("active_event")
	if active_data:
		active_event = EventInstance.new()
		active_event.load_from_save_data(active_data)
	else:
		active_event = null
	
	GLog.debug("Loaded event manager state: %d events encountered, %d in history" % [
		events_encountered.size(),
		event_history.size()
	])

func debug_trigger_event(event_name: String) -> void:
	var event = get_event_by_name(event_name)
	if event:
		trigger_event(event, true)
		GLog.debug("Debug: Triggered event '%s'" % event_name)
	else:
		GLog.error("Debug: Event '%s' not found" % event_name)

func debug_list_events() -> void:
	print("\n=== All Events ===")
	for event in all_events:
		print("- %s [%s] (%s)" % [event.event_name, event.rarity, event.event_type])
	print("Total: %d events\n" % all_events.size())