extends CardEffect
class_name ForcedDiscard

@export var cards_to_discard: int = 1

var effect_name: String = ""
var description: String = ""

func _init() -> void:
	effect_name = "Forced Discard"
	description = "Must discard %d card(s)" % cards_to_discard

func apply_effect(_duel_manager: DuelManager, card_data: CardData, results: Dictionary) -> void:
	# Add forced discard to results
	if not results.has("forced_discard"):
		results.forced_discard = 0
	
	results.forced_discard += cards_to_discard
	
	print("Applied %s effect from %s (discard %d cards)" % [effect_name, card_data.card_name, cards_to_discard])

func get_formatted_description() -> String:
	return "Must discard %d card(s)" % cards_to_discard