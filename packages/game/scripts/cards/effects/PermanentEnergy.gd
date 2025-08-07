extends CardEffect
class_name PermanentEnergy

# Permanent Energy Effect - ONESHOT that permanently increases max energy

@export var energy_increase: int = 1    # How much to increase max energy


func _init() -> void:
	effect_name = "Permanent Energy"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add permanent energy to results
	if not results.has("permanent_energy"):
		results.permanent_energy = []
	
	results.permanent_energy.append({
		"increase": energy_increase
	})
	
	print("Applied %s effect from %s (+%d max energy)" % [effect_name, card_data.card_name, energy_increase])

func get_formatted_description() -> String:
	return "ONESHOT: Permanently gain +%d max energy" % energy_increase