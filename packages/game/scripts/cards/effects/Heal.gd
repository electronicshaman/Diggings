extends CardEffect
class_name Heal

const EFFECT_NAME := "Heal"

@export var heal_amount: int = 1


func _init() -> void:
	pass

func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	results.heal += heal_amount
	var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else "Unknown"
	print("Applied %s effect from %s (+%d heal, total: %d)" % [get_effect_name(), name, heal_amount, results.heal])

func get_formatted_description() -> String:
	return "Heal %d" % heal_amount

func get_effect_name() -> String:
	return EFFECT_NAME