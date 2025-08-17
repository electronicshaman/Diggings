extends CardEffect
class_name MutualEffect

const EFFECT_NAME := "Mutual Effect"

# Mutual Effect - Apply same effect to both player and enemy
# Theme-agnostic: sharing, contagion, inspiration, leadership, etc.

@export var mutual_healing: int = 0          # Heal both player and enemy
@export var mutual_energy: int = 0           # Give energy to both (if applicable)
@export var mutual_damage: int = 0           # Damage both player and enemy
@export var mutual_defense: int = 0          # Block for both player and enemy
@export var effect_type: String = "healing"  # Main effect type for description

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add mutual effect to results
	if not results.has("mutual_effect"):
		results.mutual_effect = []
	
	results.mutual_effect.append({
		"mutual_healing": mutual_healing,
		"mutual_energy": mutual_energy,
		"mutual_damage": mutual_damage,
		"mutual_defense": mutual_defense,
		"effect_type": effect_type
	})
	
	print("Applied %s effect from %s (%s for both)" % [get_effect_name(), card_data.card_name, effect_type])

func get_formatted_description() -> String:
	var effects: Array[String] = []
	
	if mutual_healing > 0:
		effects.append("heal %d" % mutual_healing)
	if mutual_energy > 0:
		effects.append("gain %d energy" % mutual_energy)
	if mutual_damage > 0:
		effects.append("take %d damage" % mutual_damage)
	if mutual_defense > 0:
		effects.append("gain %d block" % mutual_defense)
	
	if effects.is_empty():
		return "MUTUAL: No effects configured"
	
	var effect_text = ", ".join(effects)
	return "Both you and enemy %s" % effect_text

func get_effect_name() -> String:
	return EFFECT_NAME