extends CardEffect
class_name NextCardDiscount

@export var discount_amount: int = 1


func _init() -> void:
	effect_name = "Next Card Discount"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add next card discount to results
	if not results.has("next_card_discount"):
		results.next_card_discount = 0
	
	results.next_card_discount += discount_amount
	
	print("Applied %s effect from %s (-%d energy cost for next card)" % [effect_name, card_data.card_name, discount_amount])

func get_formatted_description() -> String:
	return "Next card played costs -%d energy" % discount_amount