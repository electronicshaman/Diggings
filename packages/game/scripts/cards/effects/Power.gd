extends CardEffect
class_name Power

const EFFECT_NAME := "Power"

# Power Effect - Persistent effects that last for the entire combat
# Theme-agnostic: ongoing abilities, persistent bonuses, auras, etc.

@export var power_type: String = "defense"    # Type of power effect
@export var power_value: int = 3              # Amount of power effect per trigger
@export var trigger: String = "turn_start"    # When power triggers
@export var stacks: bool = true               # Whether multiple copies stack

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add power to results
	if not results.has("power_effects"):
		results.power_effects = []
	
	results.power_effects.append({
		"power_type": power_type,
		"power_value": power_value,
		"trigger": trigger,
		"stacks": stacks
	})
	
	print("Applied %s effect from %s (%s %d at %s)" % [get_effect_name(), card_data.card_name, power_type, power_value, trigger])

func get_formatted_description() -> String:
	var trigger_text = ""
	match trigger:
		"turn_start":
			trigger_text = "At start of turn"
		"turn_end":
			trigger_text = "At end of turn"
		"damage_taken":
			trigger_text = "When damaged"
		"card_played":
			trigger_text = "When playing cards"
		_:
			trigger_text = "On %s" % trigger
	
	var effect_text = ""
	match power_type:
		"defense":
			effect_text = "gain %d block" % power_value
		"damage":
			effect_text = "deal %d damage" % power_value
		"healing":
			effect_text = "heal %d health" % power_value
		"energy":
			effect_text = "gain %d energy" % power_value
		_:
			effect_text = "%s %d" % [power_type, power_value]
	
	return "%s: %s (Power)" % [trigger_text, effect_text]

func get_effect_name() -> String:
	return EFFECT_NAME