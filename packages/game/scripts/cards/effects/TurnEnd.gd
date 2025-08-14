extends CardEffect
class_name TurnEnd

const EFFECT_NAME := "Turn End"

# Turn End Effect - Force end the current turn
# Theme-agnostic: rest, conclude, finish, exhaust, etc.

@export var condition: String = ""           # Optional condition for activation
@export var condition_value: int = 0         # Value for condition check

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add turn end to results
	if not results.has("turn_end"):
		results.turn_end = []
	
	results.turn_end.append({
		"condition": condition,
		"condition_value": condition_value
	})
	
	print("Applied %s effect from %s (end turn)" % [get_effect_name(), card_data.card_name])

func get_formatted_description() -> String:
	var desc = "End your turn"
	
	# Add condition text if present
	match condition:
		"if_hand_empty":
			desc += " (only if hand is empty)"
		"if_no_energy":
			desc += " (only if no energy remaining)"
		"if_health_low":
			desc += " (only if health below %d)" % condition_value
		"":
			pass  # No condition - always ends turn
		_:
			desc += " (%s)" % condition
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME