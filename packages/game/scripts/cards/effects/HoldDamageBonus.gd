extends CardEffect
class_name HoldDamageBonus

@export var bonus_damage: int = 1
@export var card_type_filter: String = ""  # If set, only affects this card type


func _init() -> void:
	effect_name = "Hold Damage Bonus"
	description = "HOLD: Increases damage"

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add hold damage bonus to results
	if not results.has("hold_damage_bonus"):
		results.hold_damage_bonus = []
	
	results.hold_damage_bonus.append({
		"bonus_damage": bonus_damage,
		"card_type_filter": card_type_filter
	})
	
	print("Applied %s effect from %s (+%d damage to %s cards)" % [effect_name, card_data.card_name, bonus_damage, card_type_filter if card_type_filter != "" else "all"])

func get_formatted_description() -> String:
	if card_type_filter != "":
		return "HOLD: %s cards +%d damage" % [card_type_filter, bonus_damage]
	else:
		return "HOLD: All cards +%d damage" % bonus_damage