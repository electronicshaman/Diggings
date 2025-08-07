extends CardEffect
class_name Heal

@export var heal_amount: int = 1


func _init() -> void:
	effect_name = "Heal"
	description = "Heal %d" % heal_amount

func apply_effect(_duel_manager: Node, _card_data: Resource, _results: Dictionary) -> void:
	pass

func get_formatted_description() -> String:
	return "Heal %d" % heal_amount