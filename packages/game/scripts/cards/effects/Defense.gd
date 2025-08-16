extends CardEffect
class_name Defense

const EFFECT_NAME := "Defense"

@export var defense_amount: int = 1

func _init() -> void:
	pass

func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	# Add defense to results
	results.defense += defense_amount
	var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else "Unknown"
	print("Applied %s effect from %s (+%d defense, total: %d)" % [get_effect_name(), name, defense_amount, results.defense])

func get_formatted_description() -> String:
	return "Gain %d defense" % defense_amount

func get_effect_name() -> String:
	return EFFECT_NAME
