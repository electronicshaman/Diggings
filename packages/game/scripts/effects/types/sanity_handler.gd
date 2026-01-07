extends "res://scripts/effects/core/effect_handler.gd"
class_name SanityHandler

@export var amount: int = 0
@export var percentage_based: bool = false
@export var full_restore: bool = false

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = context.primary_target if context and context.primary_target else (context.player_data if context else null)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	var max_sanity = target.get("max_sanity")
	var sanity = target.get("sanity")
	var apply_amt = amount
	if full_restore and max_sanity != null:
		apply_amt = int(max_sanity)
	elif percentage_based and max_sanity != null:
		apply_amt = int(round(float(max_sanity) * clamp(amount / 100.0, 0.0, 1.0)))
	if sanity != null:
		var new_sanity = sanity + apply_amt
		if max_sanity != null:
			new_sanity = min(new_sanity, max_sanity)
		target.set("sanity", new_sanity)
	result.values_applied["sanity"] = apply_amt
	result.success = true
	return result
