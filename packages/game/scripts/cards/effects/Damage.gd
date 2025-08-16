extends CardEffect
class_name Damage

const EFFECT_NAME := "Damage"

@export var damage_amount: int = 1
@export var ignores_defense: bool = false



func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add damage to results (single hit assumed)
	results.damage += damage_amount
	
	# Set ignore defense flag if this damage ignores defense
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [get_effect_name(), card_data.card_name, damage_amount, defense_text, results.damage])

# Instance-aware API: default to same behavior, but supports logging via CardInstance
func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	results.damage += damage_amount
	if ignores_defense:
		results.ignores_defense = true
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else (card_instance.card_data.card_name if card_instance and "card_data" in card_instance else "Unknown")
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [get_effect_name(), name, damage_amount, defense_text, results.damage])

func get_formatted_description() -> String:
	var base_text: String = "Deal %d damage" % damage_amount
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text

func get_effect_name() -> String:
	return EFFECT_NAME
