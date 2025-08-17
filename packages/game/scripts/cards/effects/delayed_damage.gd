extends CardEffect
class_name DelayedDamage

const EFFECT_NAME := "Delayed Damage"

@export var damage_amount: int = 2

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add delayed damage to results for turn-end processing
	if not results.has("delayed_damage"):
		results.delayed_damage = 0
	results.delayed_damage += damage_amount
	
	print("Applied %s effect from %s (%d damage at turn end)" % [
		get_effect_name(), card_data.card_name, damage_amount
	])
	
	# Add notification about delayed effect
	if results.has("notifications"):
		results.notifications.append("Will take %d damage at turn end" % damage_amount)
	else:
		results.notifications = ["Will take %d damage at turn end" % damage_amount]

func get_formatted_description() -> String:
	return "Take %d damage at the end of this turn" % damage_amount

func get_effect_name() -> String:
	return EFFECT_NAME