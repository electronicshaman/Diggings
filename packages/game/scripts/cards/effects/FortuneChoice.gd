extends CardEffect
class_name FortuneChoice

const EFFECT_NAME := "Fortune Choice"

# Fortune Choice Effect - Random chance between different outcomes
# Used for Strike It Rich and similar cards with success/failure outcomes

@export var success_chance: float = 0.6  # 60% chance by default
@export var success_effects: Array[Dictionary] = []  # Effects on success
@export var failure_effects: Array[Dictionary] = []  # Effects on failure

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add fortune choice to results
	if not results.has("fortune_choice"):
		results.fortune_choice = []
	
	results.fortune_choice.append({
		"success_chance": success_chance,
		"success_effects": success_effects,
		"failure_effects": failure_effects
	})
	
	print("Applied %s effect from %s (%.0f%% success chance)" % [
		get_effect_name(), 
		card_data.card_name, 
		success_chance * 100
	])

func get_formatted_description() -> String:
	var percentage: int = int(success_chance * 100)
	var success_text = _format_effects(success_effects)
	var failure_text = _format_effects(failure_effects)
	
	return "%d%% chance: %s. %d%% chance: %s" % [
		percentage, success_text,
		100 - percentage, failure_text
	]

func _format_effects(effects: Array) -> String:
	if effects.is_empty():
		return "No effect"
	
	var parts: Array = []
	for effect in effects:
		if effect.has("type") and effect.has("value"):
			parts.append(_format_single_effect(effect))
	
	if parts.is_empty():
		return "No effect"
	
	return " and ".join(parts)

func _format_single_effect(effect: Dictionary) -> String:
	match effect.type:
		"gold":
			return "Gain %d Gold" % effect.value
		"damage":
			return "Deal %d damage" % effect.value
		"heal":
			return "Heal %d Health" % effect.value
		"draw":
			if effect.value == 1:
				return "Draw 1 card"
			else:
				return "Draw %d cards" % effect.value
		"block":
			return "Gain %d Block" % effect.value
		"lose_health":
			return "Lose %d Health" % effect.value
		"corruption":
			return "Gain %d Corruption" % effect.value
		"sanity":
			return "Restore %d Sanity" % effect.value
		_:
			return "Special effect"

func get_effect_name() -> String:
	return EFFECT_NAME