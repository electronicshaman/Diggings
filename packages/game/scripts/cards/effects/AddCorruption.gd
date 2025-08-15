extends CardEffect
class_name AddCorruption

const EFFECT_NAME := "Add Corruption"

# Add Corruption Effect - Increases player's corruption
# Used for powerful effects with corruption as a cost

@export var corruption_amount: int = 2  # Amount of corruption to add

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add corruption to results
	if not results.has("corruption"):
		results.corruption = 0
	
	results.corruption += corruption_amount
	
	print("Applied %s effect from %s (+%d corruption)" % [
		get_effect_name(), 
		card_data.card_name, 
		corruption_amount
	])

func get_formatted_description() -> String:
	return "Gain %d Corruption" % corruption_amount

func get_effect_name() -> String:
	return EFFECT_NAME