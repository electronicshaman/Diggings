extends CardEffect
class_name HealingBonus

const EFFECT_NAME := "Healing Bonus"

# Healing Bonus Effect - HOLD card that increases all healing
# "The Lord's blessing flows through every act of mercy"

@export var healing_bonus: int = 1    # Amount to add to all healing effects

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add healing bonus to results
	if not results.has("healing_bonus"):
		results.healing_bonus = []
	
	results.healing_bonus.append({
		"bonus": healing_bonus
	})
	
	print("Applied %s effect from %s (+%d to all healing)" % [get_effect_name(), card_data.card_name, healing_bonus])

func get_formatted_description() -> String:
	return "HOLD: All healing effects +%d" % healing_bonus

func get_effect_name() -> String:
	return EFFECT_NAME