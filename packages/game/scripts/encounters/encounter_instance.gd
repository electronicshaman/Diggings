extends Resource
class_name EncounterInstance

const DEBUG_ENABLED: bool = true

@export var encounter_data: EncounterData
@export var instance_id: String = ""
@export var times_encountered: int = 0
@export var last_choice_index: int = -1
@export var choices_made: Array[int] = []
@export var outcomes_applied: Array[String] = []
@export var is_active: bool = false
@export var completion_time: float = 0.0

var _dynamic_description: String = ""
var _game_state_snapshot: Dictionary = {}

func _init(data: EncounterData = null) -> void:
	if data:
		encounter_data = data
		instance_id = _generate_instance_id()
		GLog.debug("Created EncounterInstance for '%s' with ID: %s" % [encounter_data.encounter_name, instance_id])

func _generate_instance_id() -> String:
	var base_name = encounter_data.resource_path.get_file().get_basename() if encounter_data else "unknown"
	return "%s_%d_%d" % [base_name, Time.get_unix_time_from_system(), randi()]

func get_encounter_name() -> String:
	return encounter_data.encounter_name if encounter_data else "Unknown Encounter"

func get_description(game_state: Dictionary = {}) -> String:
	if _dynamic_description != "":
		return _dynamic_description
	
	if not encounter_data:
		return "Unknown encounter"
	
	return encounter_data.get_formatted_description(game_state)

func get_available_choices(game_state: Dictionary) -> Array[EncounterChoice]:
	if not encounter_data:
		return []
	
	_game_state_snapshot = game_state.duplicate(true)
	
	var available = []
	for i in range(encounter_data.choices.size()):
		var choice = encounter_data.choices[i]
		if choice:
			if not choice.one_time_only or not i in choices_made:
				available.append(choice)
	
	return available

func make_choice(choice_index: int, game_state: Dictionary) -> Array[Resource]:
	if not encounter_data or choice_index < 0 or choice_index >= encounter_data.choices.size():
		GLog.error("Invalid choice index: %d" % choice_index)
		return []
	
	var choice = encounter_data.choices[choice_index]
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
    
	for effect in outcomes:
		if effect:
			var effect_name := ""
			var type_val = effect.get("effect_type")
			if type_val != null and str(type_val) != "":
				effect_name = str(type_val)
			else:
				effect_name = effect.get_class()
			outcomes_applied.append(effect_name)
			GLog.debug("Applied effect: %s" % effect_name)
    
	return outcomes

func increment_encounter_count() -> void:
	times_encountered += 1
	GLog.debug("Encounter '%s' encountered %d times" % [get_encounter_name(), times_encountered])

func mark_completed() -> void:
	is_active = false
	completion_time = Time.get_unix_time_from_system()
	GLog.debug("Event '%s' completed at %f" % [get_encounter_name(), completion_time])

func can_repeat() -> bool:
	if not encounter_data:
		return false
	
	if not encounter_data.repeatable:
		return false
	
	if encounter_data.max_occurrences > 0 and times_encountered >= encounter_data.max_occurrences:
		return false
	
	return true

func has_been_completed() -> bool:
	return completion_time > 0

func get_choice_history() -> Array[String]:
	var history = []
	for choice_index in choices_made:
		if choice_index >= 0 and choice_index < encounter_data.choices.size():
			var choice = encounter_data.choices[choice_index]
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
		"encounter_path": encounter_data.resource_path if encounter_data else "",
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
	var encounter_path = data.get("encounter_path", "")
	if encounter_path != "":
		encounter_data = load(encounter_path) as EncounterData
	
	instance_id = data.get("instance_id", _generate_instance_id())
	times_encountered = data.get("times_encountered", 0)
	last_choice_index = data.get("last_choice_index", -1)
	choices_made = data.get("choices_made", [])
	outcomes_applied = data.get("outcomes_applied", [])
	is_active = data.get("is_active", false)
	completion_time = data.get("completion_time", 0.0)
	_dynamic_description = data.get("dynamic_description", "")

func duplicate_instance() -> EncounterInstance:
	var new_instance = EncounterInstance.new(encounter_data)
	new_instance.times_encountered = times_encountered
	new_instance.last_choice_index = last_choice_index
	new_instance.choices_made = choices_made.duplicate()
	new_instance.outcomes_applied = outcomes_applied.duplicate()
	new_instance.is_active = is_active
	new_instance.completion_time = completion_time
	new_instance._dynamic_description = _dynamic_description
	return new_instance

func equals(other: EncounterInstance) -> bool:
	if not other:
		return false
	return instance_id == other.instance_id

func _to_string() -> String:
	return "EncounterInstance[%s, encountered:%d, active:%s, id:%s]" % [
		get_encounter_name(), 
		times_encountered, 
		str(is_active), 
		instance_id
	]