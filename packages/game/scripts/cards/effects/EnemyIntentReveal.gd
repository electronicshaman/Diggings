extends CardEffect
class_name EnemyIntentReveal

func _init() -> void:
	effect_name = "Enemy Intent Reveal"
	description = "Reveal the enemy's next intent"

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var enemy_data = duel_manager.duel_state.enemy_data
	if enemy_data:
		enemy_data.reveal_intent()
		print("Applied %s effect from %s (revealed enemy intent: %s)" % [
			effect_name, card_data.card_name, enemy_data.get_intent_display()
		])
		
		# Add notification about revealed intent
		if results.has("notifications"):
			results.notifications.append("Revealed enemy intent: %s" % enemy_data.get_intent_display())
		else:
			results.notifications = ["Revealed enemy intent: %s" % enemy_data.get_intent_display()]

func get_formatted_description() -> String:
	return "Reveal the enemy's next intent"