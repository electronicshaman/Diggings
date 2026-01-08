extends Resource
class_name EncounterOutcome

const DEBUG_ENABLED: bool = true

@export var description: String = "Base outcome description"
@export var delayed: bool = false
@export var delay_turns: int = 0

func apply_outcome(_encounter_manager: Node, _game_state: Dictionary, _context: Dictionary = {}) -> void:
	GLog.warn("EncounterOutcome.apply_outcome() called but not overridden!")
	GLog.warn("Outcome: %s" % get_outcome_name())

func can_apply(_game_state: Dictionary) -> bool:
	return true

func get_formatted_description() -> String:
	return description

func get_outcome_name() -> String:
	var s = get_script()
	if s and s.has_method("get_path"):
		var p = s.get_path()
		if typeof(p) == TYPE_STRING and p != "":
			return p.get_file().get_basename()
	return get_class()

func get_description_text() -> String:
	return description

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return true

func is_negative() -> bool:
	return false

func get_outcome_color() -> Color:
	if is_negative():
		return Color.RED
	elif is_positive():
		return Color.GREEN
	else:
		return Color.WHITE