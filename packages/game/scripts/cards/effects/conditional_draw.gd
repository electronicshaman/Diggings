extends CardEffect
class_name ConditionalDraw

const EFFECT_NAME := "Conditional Draw"

# Conditional Draw - Draw cards with bonus based on condition
@export var base_draw: int = 2
@export var bonus_draw: int = 1
@export var bonus_gold: int = 3
@export var condition_type: String = "same_type"  # same_type, fortune_cards, etc.

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add conditional draw to results
	if not results.has("conditional_draw"):
		results.conditional_draw = []
	
	results.conditional_draw.append({
		"base_draw": base_draw,
		"bonus_draw": bonus_draw,
		"bonus_gold": bonus_gold,
		"condition_type": condition_type
	})
	
	print("Applied %s effect from %s (draw %d, conditional bonus)" % [
		get_effect_name(), 
		card_data.card_name, 
		base_draw
	])

func get_formatted_description() -> String:
	var desc = "Draw %d cards" % base_draw
	
	if condition_type == "same_type" and bonus_draw > 0:
		desc += ". If both are same type, draw %d more" % bonus_draw
		if bonus_gold > 0:
			desc += " and gain %d Gold" % bonus_gold
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME