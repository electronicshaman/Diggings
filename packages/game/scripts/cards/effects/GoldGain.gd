extends CardEffect
class_name GoldGain

const EFFECT_NAME := "Gold Gain"

# Gold Gain Effect - Gain gold with optional random chance
# Used for prospector fortune cards like Pan for Gold

@export var min_gold: int = 1  # Minimum gold to gain
@export var max_gold: int = 3  # Maximum gold to gain
@export var success_chance: float = 1.0  # 100% by default, can be less for risk/reward
@export var failure_gold: int = 0  # Gold to gain on failure (if success_chance < 1.0)

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add gold gain to results
	if not results.has("gold_gain"):
		results.gold_gain = []
	
	results.gold_gain.append({
		"min_gold": min_gold,
		"max_gold": max_gold,
		"success_chance": success_chance,
		"failure_gold": failure_gold
	})
	
	print("Applied %s effect from %s (gain %d-%d gold, %.0f%% chance)" % [
		get_effect_name(), 
		card_data.card_name, 
		min_gold,
		max_gold,
		success_chance * 100
	])

func get_formatted_description() -> String:
	if success_chance >= 1.0:
		# Guaranteed gold gain
		if min_gold == max_gold:
			return "Gain %d Gold" % min_gold
		else:
			return "Gain %d-%d Gold" % [min_gold, max_gold]
	else:
		# Chance-based gold gain
		var percentage: int = int(success_chance * 100)
		if min_gold == max_gold:
			if failure_gold > 0:
				return "%d%% chance: Gain %d Gold. Otherwise: Gain %d Gold" % [percentage, min_gold, failure_gold]
			else:
				return "%d%% chance to gain %d Gold" % [percentage, min_gold]
		else:
			if failure_gold > 0:
				return "%d%% chance: Gain %d-%d Gold. Otherwise: Gain %d Gold" % [percentage, min_gold, max_gold, failure_gold]
			else:
				return "%d%% chance to gain %d-%d Gold" % [percentage, min_gold, max_gold]

func get_effect_name() -> String:
	return EFFECT_NAME