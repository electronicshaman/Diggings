extends CardEffect
class_name RandomCard

# Random Card Effect - Add random cards to hand

@export var cards_to_generate: int = 1
@export var include_basic_cards: bool = true
@export var include_class_cards: bool = true


func _init() -> void:
	effect_name = "Random Card"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add random card to results
	if not results.has("random_card"):
		results.random_card = []
	
	results.random_card.append({
		"cards_to_generate": cards_to_generate,
		"include_basic_cards": include_basic_cards,
		"include_class_cards": include_class_cards
	})
	
	print("Applied %s effect from %s (%d cards)" % [effect_name, card_data.card_name, cards_to_generate])

func get_formatted_description() -> String:
	var card_text: String = "card" if cards_to_generate == 1 else "%d cards" % cards_to_generate
	var pool_text: String = ""
	
	if include_basic_cards and include_class_cards:
		pool_text = "basic or class"
	elif include_class_cards:
		pool_text = "class"
	elif include_basic_cards:
		pool_text = "basic"
	else:
		pool_text = "unknown"
	
	return "Add random %s %s to hand" % [pool_text, card_text]