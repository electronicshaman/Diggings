extends CardEffect
class_name QuickDrawDamage

const EFFECT_NAME := "Quick Draw Damage"

@export var base_damage: int = 0
@export var quick_draw_bonus: int = 0
@export var ignores_defense: bool = false

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_damage := 0

	# Add base damage only if configured (> 0)
	if base_damage > 0:
		total_damage += base_damage

	# Check if this is the first card played (Quick Draw active)
	if duel_manager and duel_manager.has_method("get_cards_played_this_turn"):
		var cards_played = duel_manager.get_cards_played_this_turn()
		if cards_played == 0 and quick_draw_bonus > 0:
			total_damage += quick_draw_bonus
			print("Quick Draw! Bonus damage applied.")
			if "notifications" in results:
				results.notifications.append("Quick Draw! +%d damage" % quick_draw_bonus)
			else:
				results.notifications = ["Quick Draw! +%d damage" % quick_draw_bonus]

	# Add damage to results (only if any)
	if total_damage > 0:
		results.damage += total_damage

	# Set ignore defense flag if applicable
	if ignores_defense:
		results.ignores_defense = true

	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (+%d damage%s, total: %d)" % [get_effect_name(), card_data.card_name, total_damage, defense_text, results.damage])

func get_formatted_description() -> String:
	var base_text: String
	if base_damage > 0:
		base_text = "Deal %d damage. Quick Draw: +%d damage" % [base_damage, quick_draw_bonus]
	else:
		base_text = "If first card played this turn, deal %d additional damage" % quick_draw_bonus
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text

func get_effect_name() -> String:
	return EFFECT_NAME