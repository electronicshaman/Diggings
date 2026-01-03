extends "res://scripts/effects/core/game_effect.gd"
class_name FaithEffect

const DEBUG_ENABLED: bool = true

@export var amount: int = 1  # Positive = gain, negative = spend

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	if not context:
		result.success = false
		result.prevented_by = "no_context"
		return result

	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)

	# NOTE: Like other effects, we do NOT directly mutate targets during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual mutations.
	# The DuelManager will respect the player's max_faith property when applying.
	result.values_applied["faith"] = final_amount
	result.success = true

	if DEBUG_ENABLED:
		var action = "Gain" if final_amount >= 0 else "Spend"
		GLog.debug("FaithEffect: %s %d Faith" % [action, abs(final_amount)])

	return result

func get_preview_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount

	if final_amount >= 0:
		return "Gain %d Faith" % final_amount
	else:
		return "Spend %d Faith" % -final_amount
