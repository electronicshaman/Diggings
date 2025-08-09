extends CardEffect
class_name QuickDrawDamage

@export var base_damage: int = 8
@export var quick_draw_bonus: int = 2
@export var ignores_defense: bool = false

func _init() -> void:
	effect_name = "Quick Draw Damage"
	description = "Deal %d damage. Quick Draw: +%d damage" % [base_damage, quick_draw_bonus]

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_damage = base_damage
	
	# Check if this is the first card played (Quick Draw active)
	if duel_manager and duel_manager.has_method("get_cards_played_this_turn"):
		var cards_played = duel_manager.get_cards_played_this_turn()
		
		# If this is the first card (Quick Draw is active)
		if cards_played <= 1:
			total_damage += quick_draw_bonus
			print("Quick Draw! Bonus damage applied.")
			
			# Add notification for Quick Draw bonus
			if "notifications" in results:
				results.notifications.append("Quick Draw! +%d damage" % quick_draw_bonus)
			else:
				results.notifications = ["Quick Draw! +%d damage" % quick_draw_bonus]
	
	# Add damage to results
	results.damage += total_damage
	
	# Set ignore defense flag if applicable
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [effect_name, card_data.card_name, total_damage, defense_text, results.damage])

func get_formatted_description() -> String:
	var base_text: String = "Deal %d damage. Quick Draw: +%d damage" % [base_damage, quick_draw_bonus]
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text