extends CardEffect
class_name RandomDamage

@export var min_damage: int = 1
@export var max_damage: int = 1
@export var ignores_defense: bool = false

func _init() -> void:
	effect_name = "Random Damage"
	update_description()

func update_description() -> void:
	if min_damage == max_damage:
		description = "Deal %d damage" % min_damage
	else:
		description = "Deal %d-%d damage randomly" % [min_damage, max_damage]

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Generate random damage within the specified range
	var damage_dealt: int = randi_range(min_damage, max_damage)
	results.damage += damage_dealt
	
	# Set ignore defense flag if this damage ignores defense
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [effect_name, card_data.card_name, damage_dealt, defense_text, results.damage])

func get_formatted_description() -> String:
	update_description()
	var base_text: String = description
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text
