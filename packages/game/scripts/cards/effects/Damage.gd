extends CardEffect
class_name Damage

@export var damage_amount: int = 1
@export var ignores_defense: bool = false



func _init() -> void:
	effect_name = "Damage"
	description = "Deal %d damage" % damage_amount

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add damage to results (single hit assumed)
	results.damage += damage_amount
	
	# Set ignore defense flag if this damage ignores defense
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [effect_name, card_data.card_name, damage_amount, defense_text, results.damage])

func get_formatted_description() -> String:
	var base_text: String = "Deal %d damage" % damage_amount
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text
