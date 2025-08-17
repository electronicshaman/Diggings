extends Resource
class_name EventInstance

const DEBUG_ENABLED: bool = true

@export var event_data: EventData
@export var instance_id: String = ""
@export var times_encountered: int = 0
@export var last_choice_index: int = -1
@export var choices_made: Array[int] = []
@export var outcomes_applied: Array[String] = []
@export var is_active: bool = false
@export var completion_time: float = 0.0

var _dynamic_description: String = ""
var _game_state_snapshot: Dictionary = {}

func _init(data: EventData = null) -> void:
	if data:
		event_data = data
		instance_id = _generate_instance_id()
		GLog.debug("Created EventInstance for '%s' with ID: %s" % [event_data.event_name, instance_id])

func _generate_instance_id() -> String:
	var base_name = event_data.resource_path.get_file().get_basename() if event_data else "unknown"
	return "%s_%d_%d" % [base_name, Time.get_unix_time_from_system(), randi()]

func get_event_name() -> String:
	return event_data.event_name if event_data else "Unknown Event"

func get_description(game_state: Dictionary = {}) -> String:
	if _dynamic_description != "":
		return _dynamic_description
	
	if not event_data:
		return "Unknown event"
	
	return event_data.get_formatted_description(game_state)

func get_available_choices(game_state: Dictionary) -> Array[EventChoice]:
	if not event_data:
		return []
	
	_game_state_snapshot = game_state.duplicate(true)
	
	var available = []
	for i in range(event_data.choices.size()):
		var choice = event_data.choices[i]
		if choice:
			if not choice.one_time_only or not i in choices_made:
				available.append(choice)
	
	return available

func make_choice(choice_index: int, game_state: Dictionary) -> Array[EventOutcome]:
	if not event_data or choice_index < 0 or choice_index >= event_data.choices.size():
		GLog.error("Invalid choice index: %d" % choice_index)
		return []
	
	var choice = event_data.choices[choice_index]
	if not choice:
		GLog.error("Choice at index %d is null" % choice_index)
		return []
	
	if not choice.can_select(game_state):
		GLog.error("Cannot select choice: requirements not met")
		return []
	
	last_choice_index = choice_index
	choices_made.append(choice_index)
	
	choice.apply_costs(game_state)
	
	var rng_result = randf()
	var outcomes = choice.get_outcomes_to_apply(rng_result)
	
	for outcome in outcomes:
		if outcome:
			var outcome_name = outcome.get_outcome_name()
			outcomes_applied.append(outcome_name)
			GLog.debug("Applied outcome: %s" % outcome_name)
	
	return outcomes

func increment_encounter_count() -> void:
	times_encountered += 1
	GLog.debug("Event '%s' encountered %d times" % [get_event_name(), times_encountered])

func mark_completed() -> void:
	is_active = false
	completion_time = Time.get_unix_time_from_system()
	GLog.debug("Event '%s' completed at %f" % [get_event_name(), completion_time])

func can_repeat() -> bool:
	if not event_data:
		return false
	
	if not event_data.repeatable:
		return false
	
	if event_data.max_occurrences > 0 and times_encountered >= event_data.max_occurrences:
		return false
	
	return true

func has_been_completed() -> bool:
	return completion_time > 0

func get_choice_history() -> Array[String]:
	var history = []
	for choice_index in choices_made:
		if choice_index >= 0 and choice_index < event_data.choices.size():
			var choice = event_data.choices[choice_index]
			if choice:
				history.append(choice.choice_text)
	return history

func get_outcome_history() -> Array[String]:
	return outcomes_applied.duplicate()

func set_dynamic_description(desc: String) -> void:
	_dynamic_description = desc

func clear_dynamic_properties() -> void:
	_dynamic_description = ""
	_game_state_snapshot.clear()

func get_save_data() -> Dictionary:
	return {
		"event_path": event_data.resource_path if event_data else "",
		"instance_id": instance_id,
		"times_encountered": times_encountered,
		"last_choice_index": last_choice_index,
		"choices_made": choices_made,
		"outcomes_applied": outcomes_applied,
		"is_active": is_active,
		"completion_time": completion_time,
		"dynamic_description": _dynamic_description
	}

func load_from_save_data(data: Dictionary) -> void:
	var event_path = data.get("event_path", "")
	if event_path != "":
		event_data = load(event_path) as EventData
	
	instance_id = data.get("instance_id", _generate_instance_id())
	times_encountered = data.get("times_encountered", 0)
	last_choice_index = data.get("last_choice_index", -1)
	choices_made = data.get("choices_made", [])
	outcomes_applied = data.get("outcomes_applied", [])
	is_active = data.get("is_active", false)
	completion_time = data.get("completion_time", 0.0)
	_dynamic_description = data.get("dynamic_description", "")

func duplicate_instance() -> EventInstance:
	var new_instance = EventInstance.new(event_data)
	new_instance.times_encountered = times_encountered
	new_instance.last_choice_index = last_choice_index
	new_instance.choices_made = choices_made.duplicate()
	new_instance.outcomes_applied = outcomes_applied.duplicate()
	new_instance.is_active = is_active
	new_instance.completion_time = completion_time
	new_instance._dynamic_description = _dynamic_description
	return new_instance

func equals(other: EventInstance) -> bool:
	if not other:
		return false
	return instance_id == other.instance_id

func _to_string() -> String:
	return "EventInstance[%s, encountered:%d, active:%s, id:%s]" % [
		get_event_name(), 
		times_encountered, 
		str(is_active), 
		instance_id
	]