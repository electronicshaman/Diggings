extends CardEffect
class_name ConditionalHeal

const EFFECT_NAME := "Conditional Heal"

@export var base_heal: int = 6
@export var bonus_heal: int = 6
@export var health_threshold: float = 0.25  # 25% health threshold

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_heal = base_heal
	var is_desperate = false
	
	# Get player health percentage
	if duel_manager and duel_manager.duel_state and duel_manager.duel_state.player_data:
		var player = duel_manager.duel_state.player_data
		var health_percentage = player.get_health_percentage()
		
		# Apply bonus healing if below threshold
		if health_percentage <= health_threshold:
			total_heal += bonus_heal
			is_desperate = true
			print("Desperate healing! Player at %.1f%% health" % (health_percentage * 100))
	
	# Add healing to results
	if not results.has("heal"):
		results.heal = 0
	results.heal += total_heal
	
	var bonus_text = " (+%d desperate bonus)" % bonus_heal if is_desperate else ""
	print("Applied %s effect from %s (+%d heal%s, total: %d)" % [
		get_effect_name(), card_data.card_name, total_heal, bonus_text, results.heal
	])

func get_formatted_description() -> String:
	return "Heal %d. If health below %d%%, heal +%d more" % [base_heal, int(health_threshold * 100), bonus_heal]

func get_effect_name() -> String:
	return EFFECT_NAME