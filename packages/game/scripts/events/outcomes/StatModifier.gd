extends EventOutcome
class_name StatModifier

const OUTCOME_NAME := "StatModifier"

@export var stat_name: String = "max_health"
@export var modifier_amount: int = 5
@export var is_permanent: bool = true
@export var is_percentage: bool = false

func apply_outcome(event_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var current_value = game_state.get(stat_name, 0)
	var new_value = current_value
	
	if is_percentage:
		new_value = int(current_value * (1.0 + modifier_amount / 100.0))
	else:
		new_value = current_value + modifier_amount
	
	game_state[stat_name] = new_value
	
	if event_manager.game_manager and event_manager.game_manager.has_method("modify_stat"):
		event_manager.game_manager.modify_stat(stat_name, modifier_amount, is_permanent)
	
	if event_manager.event_bus:
		event_manager.event_bus.statistics_updated.emit(stat_name, new_value)
	
	GLog.debug("Applied %s: %s %s by %d (new value: %d)" % [
		get_outcome_name(),
		"Permanently" if is_permanent else "Temporarily",
		stat_name,
		modifier_amount,
		new_value
	])

func get_formatted_description() -> String:
	var sign = "+" if modifier_amount > 0 else ""
	var permanent_text = "Permanently " if is_permanent else "Temporarily "
	
	if is_percentage:
		return "%s%s %s by %s%d%%" % [permanent_text, _get_stat_verb(), _format_stat_name(), sign, modifier_amount]
	else:
		return "%s%s %s%d %s" % [permanent_text, _get_stat_verb(), sign, modifier_amount, _format_stat_name()]

func get_preview_text() -> String:
	var sign = "+" if modifier_amount > 0 else ""
	if is_percentage:
		return "%s%d%% %s" % [sign, modifier_amount, _format_stat_name()]
	else:
		return "%s%d %s" % [sign, modifier_amount, _format_stat_name()]

func _get_stat_verb() -> String:
	if modifier_amount > 0:
		return "increase"
	else:
		return "decrease"

func _format_stat_name() -> String:
	match stat_name:
		"max_health":
			return "Max Health"
		"max_sanity":
			return "Max Sanity"
		"max_corruption":
			return "Corruption Limit"
		"energy_per_turn":
			return "Energy per Turn"
		"card_draw":
			return "Card Draw"
		"hand_size":
			return "Hand Size"
		_:
			return stat_name.replace("_", " ").capitalize()

func is_positive() -> bool:
	match stat_name:
		"max_health", "max_sanity", "energy_per_turn", "card_draw", "hand_size":
			return modifier_amount > 0
		"max_corruption":
			return modifier_amount < 0
		_:
			return modifier_amount > 0

func is_negative() -> bool:
	return not is_positive()

func get_outcome_name() -> String:
	return OUTCOME_NAME