extends "res://scripts/handlers/core/handler_base.gd"
class_name ResourceHandler

@export var resource_type: String = "gold" # gold, energy, sanity, or custom (e.g. ammo, brew)
@export var amount: int = 0
@export var can_go_negative: bool = false
@export var random_range: bool = false
@export var min_amount: int = 0
@export var max_amount: int = 0

## Applies resource changes (gold, energy, sanity, or custom resources).
## Returns a HandlerResult with resource deltas to be applied by DuelManager.
func apply_effect(context: Resource) -> Resource:
	var result = HandlerResult.new()
	if not context:
		result.success = false
		result.prevented_by = "no_context"
		return result

	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)

	var apply_amt = final_amount
	if random_range:
		var lo = min(min_amount, max_amount)
		var hi = max(min_amount, max_amount)
		apply_amt = randi_range(lo, hi)

	# NOTE: Like DamageHandler, we do NOT directly mutate targets during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual mutations.
	
	# Standard resources are handled directly by key
	if resource_type in ["gold", "energy", "sanity"]:
		result.values_applied[resource_type] = apply_amt
	else:
		# Custom resources (including faith) are grouped
		if not result.values_applied.has("custom_resources"):
			result.values_applied["custom_resources"] = {}
		result.values_applied["custom_resources"][resource_type] = apply_amt

	result.values_applied["can_go_negative"] = can_go_negative
	result.success = true
	return result

func get_description_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	var display_name = resource_type.capitalize()

	if random_range:
		var lo = min(min_amount, max_amount)
		var hi = max(min_amount, max_amount)
		if lo == hi:
			if final_amount >= 0:
				return "Gain %d %s" % [lo, display_name]
			else:
				return "Lose %d %s" % [-lo, display_name]
		else:
			if lo >= 0:
				return "Gain %d-%d %s" % [lo, hi, display_name]
			else:
				return "Lose %d-%d %s" % [-hi, -lo, display_name]
	else:
		if final_amount >= 0:
			return "Gain %d %s" % [final_amount, display_name]
		else:
			return "Lose %d %s" % [-final_amount, display_name]
