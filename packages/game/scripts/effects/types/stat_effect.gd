extends "res://scripts/effects/core/game_effect.gd"
class_name StatEffect

@export var stat_name: String = ""
@export var modifier_value: float = 0.0
@export var modifier_type: String = "flat" # "flat" | "percent"
@export var duration: int = 0 # 0 immediate, >0 persistent turns

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = context.primary_target if context and context.primary_target else (context.player_data if context else null)
	if target == null or stat_name == "":
		result.success = false
		result.prevented_by = "invalid_target_or_stat"
		return result
	var current = target.get(stat_name)
	if current == null:
		result.success = false
		result.prevented_by = "stat_not_found"
		return result
	if modifier_type == "flat":
		target.set(stat_name, current + modifier_value)
	elif modifier_type == "percent":
		target.set(stat_name, int(round(float(current) * (1.0 + modifier_value))))
	result.values_applied["stat"] = stat_name
	result.values_applied["value"] = modifier_value
	result.values_applied["type"] = modifier_type
	result.values_applied["duration"] = duration
	result.success = true
	return result
