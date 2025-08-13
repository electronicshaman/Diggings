extends CardEffect
class_name CostReduction

const EFFECT_NAME := "Cost Reduction"

# Cost Reduction Effect - Reduce energy cost of cards this turn
# "When the stars align, even the impossible becomes affordable"

@export var cost_reduction: int = 1          # How much to reduce costs
@export var minimum_hand_size: int = 0       # Required hand size for effect (Full House = 5)
@export var affects_all_cards: bool = true   # If false, only affects specific card types
@export var card_type_filter: String = ""    # Only affects this card type (if affects_all_cards = false)


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add cost reduction to results
	if not results.has("cost_reduction"):
		results.cost_reduction = []
	
	results.cost_reduction.append({
		"cost_reduction": cost_reduction,
		"minimum_hand_size": minimum_hand_size,
		"affects_all_cards": affects_all_cards,
		"card_type_filter": card_type_filter
	})
	
	print("Applied %s effect from %s (-%d energy cost)" % [get_effect_name(), card_data.card_name, cost_reduction])

func get_formatted_description() -> String:
	var desc: String = "All cards cost -%d energy this turn" % cost_reduction
	
	if not affects_all_cards and card_type_filter != "":
		desc = "%s cards cost -%d energy this turn" % [card_type_filter, cost_reduction]
	
	if minimum_hand_size > 0:
		desc += " (requires %d+ cards in hand)" % minimum_hand_size
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME