extends CardEffect
class_name Heal

const EFFECT_NAME := "Heal"

@export var heal_amount: int = 1


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, _card_data: Resource, _results: Dictionary) -> void:
	pass

func get_formatted_description() -> String:
	return "Heal %d" % heal_amount

func get_effect_name() -> String:
	return EFFECT_NAME