extends CardEffect
class_name Draw

const EFFECT_NAME := "Draw"

@export var cards_to_draw: int = 1


func _init() -> void:
	pass

func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	# Add draw to results
	results.draw += cards_to_draw
	var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else "Unknown"
	print("Applied %s effect from %s (+%d draw, total: %d)" % [get_effect_name(), name, cards_to_draw, results.draw])

func get_formatted_description() -> String:
	return "Draw %d card(s)" % cards_to_draw

func get_effect_name() -> String:
	return EFFECT_NAME