extends EventOutcome
class_name SanityRestore

const OUTCOME_NAME := "SanityRestore"

@export var sanity_amount: int = 10
@export var percentage_based: bool = false
@export var percentage: float = 0.2
@export var full_restore: bool = false

func apply_outcome(event_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var amount = sanity_amount
	var max_sanity = game_state.get("max_sanity", 100)
	
	if full_restore:
		amount = max_sanity - game_state.get("sanity", 100)
	elif percentage_based:
		amount = int(max_sanity * percentage)
	
	var current_sanity = game_state.get("sanity", 100)
	game_state["sanity"] = min(max_sanity, current_sanity + amount)
	
	if event_manager.event_bus:
		event_manager.event_bus.sanity_changed.emit(amount)
	
	if event_manager.game_manager:
		event_manager.game_manager.restore_sanity(amount)
	
	GLog.debug("Applied %s: +%d sanity (sanity: %d/%d)" % [
		get_outcome_name(),
		amount,
		game_state["sanity"],
		max_sanity
	])

func get_formatted_description() -> String:
	if full_restore:
		return "Restore sanity to full"
	elif percentage_based:
		return "Restore %d%% of max sanity" % int(percentage * 100)
	return "Restore %d sanity" % sanity_amount

func get_preview_text() -> String:
	if full_restore:
		return "Full sanity"
	elif percentage_based:
		return "+%d%% sanity" % int(percentage * 100)
	return "+%d sanity" % sanity_amount

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return true

func get_outcome_name() -> String:
	return OUTCOME_NAME