extends CardEffect
class_name DelayedDefense

const EFFECT_NAME := "Delayed Defense"

# Delayed Defense Effect - Gain defense/block next turn
# Theme-agnostic: could be preparation, fortification, anticipation, setup, etc.

@export var defense_amount: int = 6          # How much block to gain next turn
@export var condition: String = ""           # Optional condition for activation
@export var condition_value: int = 0         # Value for condition check

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add delayed defense to results
	if not results.has("delayed_defense"):
		results.delayed_defense = []
	
	results.delayed_defense.append({
		"defense_amount": defense_amount,
		"condition": condition,
		"condition_value": condition_value
	})
	
	print("Applied %s effect from %s (%d block next turn)" % [get_effect_name(), card_data.card_name, defense_amount])

func get_formatted_description() -> String:
	var desc = "Next turn: Gain %d block" % defense_amount
	
	# Add condition text if present
	match condition:
		"if_attacked":
			desc += " (only if attacked this turn)"
		"if_damaged":
			desc += " (only if damaged this turn)"
		"if_no_block":
			desc += " (only if no block remaining)"
		"":
			pass  # No condition
		_:
			desc += " (%s)" % condition
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME