extends "res://scripts/handlers/core/handler_base.gd"
class_name DefenseHandler

@export var amount: int = 0
@export var duration: int = 0
@export var condition: String = "" # descriptive only; enforcement left to systems
# Note: delayed is inherited from EffectHandler base class


func apply_effect(context):
	var result = HandlerResult.new()
	var target = context.primary_target if context and context.primary_target else (context.player_data if context else null)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result

	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)

	# Apply curio defense bonus from context (only for player cards)
	# Player cards typically target player_data for defense
	var is_player_card = context and context.primary_target == context.player_data
	if is_player_card:
		var curio_defense_bonus = _get_curio_bonus(context, "defense")
		if curio_defense_bonus > 0:
			final_amount += curio_defense_bonus

	# NOTE: Like DamageHandler, we do NOT directly mutate targets during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual mutations.
	if delayed:
		if not result.values_applied.has("delayed_defense"):
			result.values_applied["delayed_defense"] = []
		result.values_applied["delayed_defense"].append({
			"defense_amount": final_amount,
			"condition": condition
		})
	else:
		result.values_applied["defense"] = final_amount

	result.values_applied["duration"] = duration
	result.values_applied["condition"] = condition
	result.success = true
	return result

func get_preview_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	var curio_bonus = _get_curio_bonus(context, "defense")

	var text: String
	if curio_bonus > 0:
		text = "Gain %s defense" % _format_value_with_bonus(final_amount, curio_bonus, "")
	else:
		text = "Gain %d defense" % final_amount

	if delayed:
		text = "Next turn: " + text
	return text
