extends CardEffect
class_name OnKill

const EFFECT_NAME := "On Kill"

# On Kill Effect - Container that triggers other effects when this card kills an enemy

@export var contained_effects: Array[CardEffect] = []

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add on kill effects to results
	if not contained_effects.is_empty():
		if not results.has("on_kill"):
			results.on_kill = []
		
		results.on_kill.append({
			"contained_effects": contained_effects
		})
		
		print("Applied %s effect from %s (%d contained effects)" % [get_effect_name(), card_data.card_name, contained_effects.size()])

func get_formatted_description() -> String:
	if contained_effects.is_empty():
		return "On kill: (no effects)"
	
	var descriptions: Array[String] = []
	for effect in contained_effects:
		descriptions.append(effect.get_formatted_description())
	
	return "On kill: " + ", ".join(descriptions)

func get_effect_name() -> String:
	return EFFECT_NAME