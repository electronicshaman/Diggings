extends EncounterOutcome
class_name CorruptionGain

const OUTCOME_NAME := "CorruptionGain"

@export var corruption_amount: int = 1
@export var random_range: bool = false
@export var min_corruption: int = 1
@export var max_corruption: int = 3

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var amount = corruption_amount
	if random_range:
		amount = randi_range(min_corruption, max_corruption)
	
	var current_corruption = game_state.get("corruption", 0)
	var player_max_corruption = game_state.get("max_corruption", 100)
	game_state["corruption"] = min(player_max_corruption, current_corruption + amount)
	
	if encounter_manager.event_bus:
		encounter_manager.event_bus.corruption_changed.emit(amount)
	
	if encounter_manager.game_manager:
		encounter_manager.game_manager.add_corruption(amount)
	
	GLog.debug("Applied %s: +%d corruption (total: %d/%d)" % [
		get_outcome_name(),
		amount,
		game_state["corruption"],
		player_max_corruption
	])

func get_formatted_description() -> String:
	if random_range:
		return "Gain %d-%d corruption" % [min_corruption, max_corruption]
	return "Gain %d corruption" % corruption_amount

func get_description_text() -> String:
	if random_range:
		return "+%d-%d corruption" % [min_corruption, max_corruption]
	return "+%d corruption" % corruption_amount

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return false

func is_negative() -> bool:
	return true

func get_outcome_name() -> String:
	return OUTCOME_NAME