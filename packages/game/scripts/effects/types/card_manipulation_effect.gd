extends "res://scripts/effects/core/game_effect.gd"
class_name CardManipulationEffect

@export var action: String = "draw" # draw, discard, shuffle, etc.
@export var amount: int = 1
@export var card_filter: String = "" # optional filter expression/tag

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	if not context:
		result.success = false
		result.prevented_by = "no_context"
		return result
	
	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)
	
	# Delegate to DeckManager if available
	if action == "draw" and DeckManager and DeckManager.has_method("draw_cards"):
		DeckManager.draw_cards(final_amount)
		result.values_applied["drawn"] = final_amount
		result.success = true
	elif action == "discard" and DeckManager and DeckManager.has_method("force_discard"):
		DeckManager.force_discard(final_amount, card_filter)
		result.values_applied["discarded"] = final_amount
		result.success = true
	else:
		result.success = false
		result.prevented_by = "unsupported_action"
	return result

func get_preview_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	
	match action:
		"draw":
			if final_amount == 1:
				return "Draw 1 card"
			else:
				return "Draw %d cards" % final_amount
		"discard":
			if final_amount == 1:
				return "Discard 1 card"
			else:
				return "Discard %d cards" % final_amount
		"shuffle":
			return "Shuffle deck"
		_:
			return "%s %d cards" % [action.capitalize(), final_amount]
