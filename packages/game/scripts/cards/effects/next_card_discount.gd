extends CardEffect
class_name NextCardDiscount

const EFFECT_NAME := "Next Card Discount"

@export var discount_amount: int = 1


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add next card discount to results
	if not results.has("next_card_discount"):
		results.next_card_discount = 0
	
	results.next_card_discount += discount_amount
	
	print("Applied %s effect from %s (-%d energy cost for next card)" % [get_effect_name(), card_data.card_name, discount_amount])

func get_formatted_description() -> String:
	return "Next card played costs -%d energy" % discount_amount

func get_effect_name() -> String:
	return EFFECT_NAME