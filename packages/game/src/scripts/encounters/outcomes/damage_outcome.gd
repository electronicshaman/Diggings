extends EncounterOutcome
class_name DamageOutcome

const OUTCOME_NAME := "DamageOutcome"

@export var damage_amount: int = 5
@export var damage_type: String = "physical"
@export var percentage_based: bool = false
@export var percentage: float = 0.1

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	var amount = damage_amount
	
	if percentage_based:
		var max_health = game_state.get("max_health", 100)
		amount = int(max_health * percentage)
	
	var current_health = game_state.get("health", 50)
	game_state["health"] = max(0, current_health - amount)
	
	if encounter_manager.event_bus:
		encounter_manager.event_bus.health_changed.emit(game_state["health"], game_state.get("max_health", 100))
		encounter_manager.event_bus.damage_dealt.emit(null, amount, null)
	
	# Apply to actual PlayerData when available (avoid calling non-existent GameManager methods)
	if encounter_manager and encounter_manager.game_manager:
		var gm = encounter_manager.game_manager
		var player_data = null
		if game_state.has("player_data") and game_state.player_data:
			player_data = game_state.player_data
		elif gm.has_method("get_player_data"):
			player_data = gm.get_player_data()
		if player_data and player_data.has_method("take_damage"):
			player_data.take_damage(amount)
	
	GLog.debug("Applied %s: %d damage (health: %d/%d)" % [
		get_outcome_name(),
		amount,
		game_state["health"],
		game_state.get("max_health", 100)
	])

func get_formatted_description() -> String:
	if percentage_based:
		return "Take %d%% of max health as damage" % int(percentage * 100)
	return "Take %d damage" % damage_amount

func get_description_text() -> String:
	if percentage_based:
		return "-%d%% HP" % int(percentage * 100)
	return "-%d HP" % damage_amount

func get_notification_text() -> String:
	return get_formatted_description()

func is_positive() -> bool:
	return false

func is_negative() -> bool:
	return true

func get_outcome_name() -> String:
	return OUTCOME_NAME
