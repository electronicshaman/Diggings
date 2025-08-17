extends CardEffect
class_name MultipleDamage

const EFFECT_NAME := "Multiple Damage"

@export var damage_amount: int = 1
@export var number_of_hits: int = 1

func _init() -> void:
	pass

func _get_base_text() -> String:
	if number_of_hits > 1:
		return "Deal %d damage %d times" % [damage_amount, number_of_hits]
	return "Deal %d damage" % damage_amount

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Set multiple damage info (overwrites previous damage settings)
	results.damage = damage_amount
	results.damage_hits = number_of_hits
	print("Applied %s effect from %s (%d damage, %d hits)" % [get_effect_name(), card_data.card_name, damage_amount, number_of_hits])

func get_formatted_description() -> String:
	return _get_base_text()

func get_effect_name() -> String:
	return EFFECT_NAME