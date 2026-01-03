extends "res://scripts/effects/core/game_effect.gd"
class_name FaithEffect

const DEBUG_ENABLED: bool = true

@export var amount: int = 1  # Positive = gain, negative = spend
@export var trigger_on_damage: bool = false  # Auto-trigger when taking damage
@export var damage_threshold: int = 10  # Minimum damage to trigger
@export var max_faith: int = 10  # Faith cap (can be modified by curios)

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
	result.values_applied["faith"] = final_amount
	result.values_applied["max_faith"] = max_faith
	result.success = true

	if DEBUG_ENABLED:
		var action = "Gain" if final_amount >= 0 else "Spend"
		GLog.debug("FaithEffect: %s %d Faith (max: %d)" % [action, abs(final_amount), max_faith])

	return result

func get_preview_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount

	if final_amount >= 0:
		return "Gain %d Faith" % final_amount
	else:
		return "Spend %d Faith" % -final_amount
