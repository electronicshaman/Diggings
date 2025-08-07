extends CardEffect
class_name Draw

@export var cards_to_draw: int = 1


func _init() -> void:
	effect_name = "Draw"
	description = "Draw %d card(s)" % cards_to_draw

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add draw to results
	results.draw += cards_to_draw
	print("Applied %s effect from %s (+%d draw, total: %d)" % [effect_name, card_data.card_name, cards_to_draw, results.draw])

func get_formatted_description() -> String:
	return "Draw %d card(s)" % cards_to_draw