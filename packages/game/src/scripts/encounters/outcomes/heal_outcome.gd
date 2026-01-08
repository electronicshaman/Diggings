extends EncounterOutcome
class_name HealOutcome

const OUTCOME_NAME := "HealOutcome"

@export var heal_amount: int = 10
@export var percentage_based: bool = false
@export var percentage: float = 0.2
@export var full_heal: bool = false

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var amount = heal_amount
	var max_health = game_state.get("max_health", 100)
	
	if full_heal:
		amount = max_health - game_state.get("health", 50)
	elif percentage_based:
		amount = int(max_health * percentage)
	
	var current_health = game_state.get("health", 50)
	game_state["health"] = min(max_health, current_health + amount)
	
	if encounter_manager.event_bus:
		encounter_manager.event_bus.health_changed.emit(game_state["health"], max_health)
		encounter_manager.event_bus.healing_received.emit(null, amount)
	
	# Apply to actual PlayerData when available
	if encounter_manager and encounter_manager.game_manager:
		var gm = encounter_manager.game_manager
		var player_data = null
		if game_state.has("player_data") and game_state.player_data:
			player_data = game_state.player_data
		elif gm.has_method("get_player_data"):
			player_data = gm.get_player_data()
		if player_data and player_data.has_method("heal"):
			player_data.heal(amount)
	
	GLog.debug("Applied %s: +%d health (health: %d/%d)" % [
		get_outcome_name(),
		amount,
		game_state["health"],
		max_health
	])

func get_formatted_description() -> String:
	if full_heal:
		return "Restore to full health"
	elif percentage_based:
		return "Heal %d%% of max health" % int(percentage * 100)
	return "Heal %d health" % heal_amount

func get_description_text() -> String:
	if full_heal:
		return "Full heal"
	elif percentage_based:
		return "+%d%% HP" % int(percentage * 100)
	return "+%d HP" % heal_amount

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return true

func get_outcome_name() -> String:
	return OUTCOME_NAME