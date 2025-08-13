extends CardEffect
class_name Gambling

const EFFECT_NAME := "Gambling"

# Gambling Effect - Next card: Double all effects OR do nothing (50/50)
# "Fortune favors the bold, but the house always wins eventually"

@export var success_chance: float = 0.5  # 50% by default
@export var effect_multiplier: float = 2.0  # Double effects on success


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add gambling to results
	if not results.has("gambling"):
		results.gambling = []
	
	results.gambling.append({
		"success_chance": success_chance,
		"effect_multiplier": effect_multiplier
	})
	
	print("Applied %s effect from %s (%.0f%% chance for %.1fx multiplier)" % [get_effect_name(), card_data.card_name, success_chance * 100, effect_multiplier])

func get_formatted_description() -> String:
	var percentage: int = int(success_chance * 100)
	if effect_multiplier == 2.0:
		return "Next card: %d%% chance to double all effects OR do nothing" % percentage
	else:
		return "Next card: %d%% chance to multiply effects by %.1fx OR do nothing" % [percentage, effect_multiplier]

func get_effect_name() -> String:
	return EFFECT_NAME