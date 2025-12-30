extends "res://scripts/effects/core/game_effect.gd"
class_name DefenseEffect

@export var amount: int = 0
@export var duration: int = 0
@export var condition: String = "" # descriptive only; enforcement left to systems
# Delayed defense (applied next turn)
@export var delayed: bool = false

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = context.primary_target if context and context.primary_target else (context.player_data if context else null)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result

	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)

	# NOTE: Like DamageEffect, we do NOT directly mutate targets during effect
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
	var text = "Gain %d block" % final_amount
	if delayed:
		text = "Next turn: " + text
	return text
