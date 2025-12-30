extends CardEffect
class_name RandomDamage

const EFFECT_NAME := "Random Damage"

@export var min_damage: int = 1
@export var max_damage: int = 1
@export var ignores_defense: bool = false

func _init() -> void:
	pass

func _get_base_text() -> String:
	if min_damage == max_damage:
		return "Deal %d damage" % min_damage
	return "Deal %d-%d damage randomly" % [min_damage, max_damage]

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Generate random damage within the specified range
	var damage_dealt: int = randi_range(min_damage, max_damage)
	results.damage += damage_dealt

	# Set ignore defense flag if this damage ignores defense
	if ignores_defense:
		results.ignores_defense = true

	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [get_effect_name(), card_data.card_name, damage_dealt, defense_text, results.damage])

# Instance-aware API: delegates to apply_effect
func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	var damage_dealt: int = randi_range(min_damage, max_damage)
	results.damage += damage_dealt
	if ignores_defense:
		results.ignores_defense = true
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else (card_instance.card_data.card_name if card_instance and "card_data" in card_instance else "Unknown")
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [get_effect_name(), name, damage_dealt, defense_text, results.damage])

func get_formatted_description() -> String:
	var base_text: String = _get_base_text()
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text

func get_effect_name() -> String:
	return EFFECT_NAME
