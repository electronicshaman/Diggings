extends EventOutcome
class_name GoldReward

const OUTCOME_NAME := "GoldReward"

@export var gold_amount: int = 10
@export var random_range: bool = false
@export var min_gold: int = 5
@export var max_gold: int = 15

func apply_outcome(event_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var amount = gold_amount
	if random_range:
		amount = randi_range(min_gold, max_gold)
	
	var current_gold = game_state.get("gold", 0)
	game_state["gold"] = current_gold + amount
	
	if event_manager.event_bus:
		event_manager.event_bus.gold_changed.emit(amount)
	
	if event_manager.game_manager:
		event_manager.game_manager.add_gold(amount)
	
	GLog.debug("Applied %s: +%d gold (total: %d)" % [get_outcome_name(), amount, game_state["gold"]])

func get_formatted_description() -> String:
	if random_range:
		return "Gain %d-%d gold" % [min_gold, max_gold]
	return "Gain %d gold" % gold_amount

func get_preview_text() -> String:
	if random_range:
		return "+%d-%d gold" % [min_gold, max_gold]
	return "+%d gold" % gold_amount

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return true

func get_outcome_name() -> String:
	return OUTCOME_NAME