extends CardEffect
class_name Stun

const EFFECT_NAME := "Stun"

# Stun Effect - Causes enemy to skip their next turn(s)
# "The shock of authority renders the lawless speechless"

@export var stun_turns: int = 1


func _init() -> void:
	pass

func apply_effect_with_instance(_duel_manager: Node, card_instance, results: Dictionary) -> void:
	# Add stun to results
	if stun_turns > 0:
		results.stun = stun_turns
		var name = card_instance.get_card_name() if card_instance and "get_card_name" in card_instance else "Unknown"
		print("Applied %s effect from %s (enemy skips %d turn(s))" % [get_effect_name(), name, stun_turns])

func get_formatted_description() -> String:
	if stun_turns == 1:
		return "Enemy skips next turn"
	else:
		return "Enemy skips next %d turns" % stun_turns

func get_effect_name() -> String:
	return EFFECT_NAME