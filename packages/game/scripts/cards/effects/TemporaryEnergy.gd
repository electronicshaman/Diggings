extends CardEffect
class_name TemporaryEnergy

const EFFECT_NAME := "Temporary Energy"

# Temporary Energy Effect - Gain energy for this turn only
# Different from PermanentEnergy which permanently increases max energy

@export var energy_gain: int = 1             # How much energy to gain
@export var condition: String = ""           # Optional condition (e.g., "hand_size_5+")
@export var condition_value: int = 0         # Value for condition check

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add temporary energy to results
	if not results.has("temporary_energy"):
		results.temporary_energy = []
	
	results.temporary_energy.append({
		"energy_gain": energy_gain,
		"condition": condition,
		"condition_value": condition_value
	})
	
	print("Applied %s effect from %s (+%d energy)" % [get_effect_name(), card_data.card_name, energy_gain])

func get_formatted_description() -> String:
	var desc = "Gain %d energy" % energy_gain
	
	# Add condition text if present
	match condition:
		"hand_size_min":
			desc += " (requires %d+ cards in hand)" % condition_value
		"hand_size_max":
			desc += " (requires %d or fewer cards in hand)" % condition_value
		"health_below":
			desc += " (requires health below %d)" % condition_value
		"turn_first":
			desc += " (first turn only)"
		"":
			pass  # No condition
		_:
			desc += " (condition: %s)" % condition
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME