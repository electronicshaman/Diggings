extends CardEffect
class_name FortuneBonus

const EFFECT_NAME := "Fortune Bonus"

# Fortune Bonus Effect - Improves success chances of next fortune card
# Used for Steady Hands and similar setup cards

@export var success_bonus: float = 0.2  # Bonus to success chance (0.2 = +20%)
@export var duration: String = "next_card"  # How long the bonus lasts (next_card, this_turn, combat)
@export var stacks: bool = false  # Whether multiple bonuses stack

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add fortune bonus to results
	if not results.has("fortune_bonus"):
		results.fortune_bonus = []
	
	results.fortune_bonus.append({
		"success_bonus": success_bonus,
		"duration": duration,
		"stacks": stacks
	})
	
	print("Applied %s effect from %s (+%.0f%% fortune success)" % [
		get_effect_name(), 
		card_data.card_name, 
		success_bonus * 100
	])

func get_formatted_description() -> String:
	var percentage: int = int(success_bonus * 100)
	var duration_text: String
	
	match duration:
		"next_card":
			duration_text = "Next Fortune card"
		"this_turn":
			duration_text = "Fortune cards this turn"
		"combat":
			duration_text = "All Fortune cards this combat"
		_:
			duration_text = "Fortune cards"
	
	var desc = "%s has +%d%% success chance" % [duration_text, percentage]
	
	if stacks:
		desc += " (stacks)"
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME