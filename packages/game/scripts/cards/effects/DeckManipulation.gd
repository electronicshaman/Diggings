extends CardEffect
class_name DeckManipulation

# Deck Manipulation - Look at top cards and select which to draw
# "Knowledge of what's coming is power itself"

@export var cards_to_look_at: int = 5    # How many cards to examine
@export var cards_to_select: int = 2     # How many to put in hand
@export var put_rest_on_bottom: bool = true  # Where unselected cards go


func _init() -> void:
	effect_name = "Deck Manipulation"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add deck manipulation to results
	if not results.has("deck_manipulation"):
		results.deck_manipulation = []
	
	results.deck_manipulation.append({
		"cards_to_look_at": cards_to_look_at,
		"cards_to_select": cards_to_select,
		"put_rest_on_bottom": put_rest_on_bottom
	})
	
	print("Applied %s effect from %s (look at %d, select %d)" % [effect_name, card_data.card_name, cards_to_look_at, cards_to_select])

func get_formatted_description() -> String:
	var rest_location: String = "bottom of deck" if put_rest_on_bottom else "top of deck"
	return "Look at top %d cards, put %d in hand, rest on %s" % [cards_to_look_at, cards_to_select, rest_location]