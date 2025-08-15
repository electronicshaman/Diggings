extends CardEffect
class_name FortuneScaling

const EFFECT_NAME := "Fortune Scaling"

# Fortune Scaling - Effects that scale with fortune cards played
@export var base_amount: int = 4
@export var per_fortune_bonus: int = 2
@export var effect_type: String = "block"  # block, damage, gold, heal

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add fortune scaling to results
	if not results.has("fortune_scaling"):
		results.fortune_scaling = []
	
	results.fortune_scaling.append({
		"base_amount": base_amount,
		"per_fortune_bonus": per_fortune_bonus,
		"effect_type": effect_type
	})
	
	print("Applied %s effect from %s (base %d, +%d per fortune)" % [
		get_effect_name(), 
		card_data.card_name, 
		base_amount,
		per_fortune_bonus
	])

func get_formatted_description() -> String:
	var effect_text: String
	
	match effect_type:
		"block":
			effect_text = "Gain %d Block" % base_amount
		"damage":
			effect_text = "Deal %d damage" % base_amount
		"gold":
			effect_text = "Gain %d Gold" % base_amount
		"heal":
			effect_text = "Heal %d Health" % base_amount
		_:
			effect_text = "Gain %d effect" % base_amount
	
	effect_text += ". Gain +%d for each Fortune card played this combat" % per_fortune_bonus
	
	return effect_text

func get_effect_name() -> String:
	return EFFECT_NAME