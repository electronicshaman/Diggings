extends CardEffect
class_name Stun

# Stun Effect - Causes enemy to skip their next turn(s)
# "The shock of authority renders the lawless speechless"

@export var stun_turns: int = 1


func _init() -> void:
	effect_name = "Stun"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add stun to results
	if stun_turns > 0:
		results.stun = stun_turns
		print("Applied %s effect from %s (enemy skips %d turn(s))" % [effect_name, card_data.card_name, stun_turns])

func get_formatted_description() -> String:
	if stun_turns == 1:
		return "Enemy skips next turn"
	else:
		return "Enemy skips next %d turns" % stun_turns