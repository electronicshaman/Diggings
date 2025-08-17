extends CardEffect
class_name GoldScaling

const EFFECT_NAME := "Gold Scaling"

# Gold Scaling Effect - Effects that scale based on gold amounts
# Used for Claim Jumping and other gold-based scaling cards

@export var scaling_type: String = "enemy_missing_health"  # What to scale with
@export var success_chance: float = 0.65  # Success chance (65% default)
@export var gold_multiplier: float = 1.0  # Multiplier for gold gain
@export var failure_effect: Dictionary = {"type": "enemy_buff", "value": 1}  # Effect on failure

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add gold scaling to results
	if not results.has("gold_scaling"):
		results.gold_scaling = []
	
	results.gold_scaling.append({
		"scaling_type": scaling_type,
		"success_chance": success_chance,
		"gold_multiplier": gold_multiplier,
		"failure_effect": failure_effect
	})
	
	print("Applied %s effect from %s (%.0f%% chance, scales with %s)" % [
		get_effect_name(), 
		card_data.card_name, 
		success_chance * 100,
		scaling_type
	])

func get_formatted_description() -> String:
	var percentage: int = int(success_chance * 100)
	var success_text: String
	var failure_text: String = _format_failure_effect(failure_effect)
	
	match scaling_type:
		"enemy_missing_health":
			success_text = "Gain Gold equal to enemy's missing Health"
		"player_gold":
			success_text = "Gain Gold equal to your current Gold"
		"cards_played":
			success_text = "Gain Gold equal to cards played this turn"
		"fortune_streak":
			success_text = "Gain Gold equal to Fortune cards played x5"
		_:
			success_text = "Gain Gold (scaling)"
	
	if gold_multiplier != 1.0:
		success_text += " x%.1f" % gold_multiplier
	
	return "%d%% chance: %s. %d%% chance: %s" % [
		percentage, success_text,
		100 - percentage, failure_text
	]

func _format_failure_effect(effect: Dictionary) -> String:
	if effect.is_empty():
		return "No effect"
	
	if not effect.has("type") or not effect.has("value"):
		return "No effect"
	
	match effect.type:
		"enemy_buff":
			return "Enemy gains %d Strength" % effect.value
		"self_damage":
			return "Take %d damage" % effect.value
		"lose_gold":
			return "Lose %d Gold" % effect.value
		"corruption":
			return "Gain %d Corruption" % effect.value
		_:
			return "Negative effect"

func get_effect_name() -> String:
	return EFFECT_NAME