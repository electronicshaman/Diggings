extends CardEffect
class_name Defense

const EFFECT_NAME := "Defense"

@export var defense_amount: int = 1

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add defense to results
	results.defense += defense_amount
	print("Applied %s effect from %s (+%d defense, total: %d)" % [get_effect_name(), card_data.card_name, defense_amount, results.defense])

func get_formatted_description() -> String:
	return "Gain %d defense" % defense_amount

func get_effect_name() -> String:
	return EFFECT_NAME
