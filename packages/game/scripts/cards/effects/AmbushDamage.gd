extends CardEffect
class_name AmbushDamage

@export var first_card_damage: int = 15
@export var normal_damage: int = 6
@export var ignores_defense: bool = false

func _init() -> void:
	effect_name = "Ambush Damage"
	description = "Deal %d damage if first card played, otherwise %d damage" % [first_card_damage, normal_damage]

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_damage = normal_damage
	var is_ambush = false
	
	# Check if this is the first card played this turn
	if duel_manager and duel_manager.has_method("get_cards_played_this_turn"):
		var cards_played = duel_manager.get_cards_played_this_turn()
		
		# If this is the first card, apply ambush damage
		if cards_played == 0:
			total_damage = first_card_damage
			is_ambush = true
			print("AMBUSH! Caught them off guard!")
			
			# Add notification for successful ambush
			if "notifications" in results:
				results.notifications.append("AMBUSH! Maximum damage!")
			else:
				results.notifications = ["AMBUSH! Maximum damage!"]
	else:
		# Fallback if we can't determine turn order
		print("Warning: Cannot determine if first card - using normal damage")
	
	# Add damage to results
	results.damage += total_damage
	
	# Set ignore defense flag if applicable
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	var ambush_text: String = " (AMBUSH!)" if is_ambush else " (too late for ambush)"
	print("Applied %s effect from %s (+%d damage%s%s, total: %d)" % [
		effect_name, card_data.card_name, total_damage, defense_text, ambush_text, results.damage
	])

func get_formatted_description() -> String:
	var base_text: String = "Deal %d damage if first card played this turn, otherwise deal %d damage" % [first_card_damage, normal_damage]
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text