extends CardEffect
class_name FatalDamagePrevention

const EFFECT_NAME := "Fatal Damage Prevention"

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var player_data = duel_manager.duel_state.player_data
	if player_data and player_data.stats:
		player_data.stats.activate_fatal_damage_prevention()
		print("Applied %s effect from %s (player cannot die this turn)" % [
			effect_name, card_data.card_name
		])
		
		# Add notification about fatal damage prevention
		if results.has("notifications"):
			results.notifications.append("Fatal damage will be prevented this turn")
		else:
			results.notifications = ["Fatal damage will be prevented this turn"]

func get_formatted_description() -> String:
	return "Prevent fatal damage this turn (survive with 1 Health)"

func get_effect_name() -> String:
	return EFFECT_NAME