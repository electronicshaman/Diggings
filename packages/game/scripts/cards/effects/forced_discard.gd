extends CardEffect
class_name ForcedDiscard

const EFFECT_NAME := "Forced Discard"

@export var cards_to_discard: int = 1


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add forced discard to results
	if not results.has("forced_discard"):
		results.forced_discard = 0
	
	results.forced_discard += cards_to_discard
	
	print("Applied %s effect from %s (discard %d cards)" % [get_effect_name(), card_data.card_name, cards_to_discard])

func get_formatted_description() -> String:
	return "Must discard %d card(s)" % cards_to_discard

func get_effect_name() -> String:
	return EFFECT_NAME