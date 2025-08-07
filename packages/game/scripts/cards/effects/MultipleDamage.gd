extends CardEffect
class_name MultipleDamage

@export var damage_amount: int = 1
@export var number_of_hits: int = 1

func _init() -> void:
	effect_name = "Multiple Damage"
	update_description()

func update_description() -> void:
	if number_of_hits > 1:
		description = "Deal %d damage %d times" % [damage_amount, number_of_hits]
	else:
		description = "Deal %d damage" % damage_amount

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Set multiple damage info (overwrites previous damage settings)
	results.damage = damage_amount
	results.damage_hits = number_of_hits
	print("Applied %s effect from %s (%d damage, %d hits)" % [effect_name, card_data.card_name, damage_amount, number_of_hits])

func get_formatted_description() -> String:
	update_description()
	return description