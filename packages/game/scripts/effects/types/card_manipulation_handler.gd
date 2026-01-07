extends "res://scripts/effects/core/effect_handler.gd"
class_name CardManipulationHandler

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

	# NOTE: Like DamageHandler, we do NOT directly perform actions during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual operations.
	match action:
		"draw":
			result.values_applied["drawn"] = final_amount
			result.success = true
		"discard":
			result.values_applied["discard_random"] = final_amount
			if card_filter != "":
				result.values_applied["discard_filter"] = card_filter
			result.success = true
		"shuffle":
			result.values_applied["shuffle_deck"] = true
			result.success = true
		"exhaust":
			result.values_applied["exhaust_random"] = final_amount
			if card_filter != "":
				result.values_applied["exhaust_filter"] = card_filter
			result.success = true
		_:
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
		"exhaust":
			if final_amount == 1:
				return "Exhaust 1 card"
			else:
				return "Exhaust %d cards" % final_amount
		_:
			return "%s %d cards" % [action.capitalize(), final_amount]
