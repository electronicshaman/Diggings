extends "res://scripts/effects/core/game_effect.gd"
class_name HealthEffect

@export var amount: int = 0
@export var percentage_based: bool = false
@export var percentage: float = 0.0
@export var full_heal: bool = false
@export var can_overheal: bool = false

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = _get_target(context)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	var heal_amount = _calculate_amount(target, context)
	if heal_amount <= 0:
		result.success = true
		result.values_applied["heal"] = 0
		return result
	# NOTE: Like DamageEffect, we do NOT directly mutate targets during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual mutations.
	result.values_applied["heal"] = heal_amount
	result.success = true
	return result

func _get_target(context):
	if context and context.primary_target:
		return context.primary_target
	return context.player_data if context else null

func _calculate_amount(target, context) -> int:
	var max_hp = null
	if target:
		max_hp = target.get("max_hp")
	if full_heal and max_hp != null:
		return int(max_hp)
	if percentage_based and max_hp != null:
		return int(round(float(max_hp) * clamp(percentage, 0.0, 1.0)))
	# Use conditional value resolution for base amount
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	return max(0, final_amount)

func get_preview_text(context: Resource) -> String:
	if full_heal:
		return "Heal to full health"
	elif percentage_based:
		var pct = int(percentage * 100)
		return "Heal for %d%% of max health" % pct
	else:
		var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
		return "Heal %d health" % final_amount
