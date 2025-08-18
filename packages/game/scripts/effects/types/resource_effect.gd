extends "res://scripts/effects/core/game_effect.gd"
class_name ResourceEffect

@export var resource_type: String = "gold" # gold, energy, corruption
@export var amount: int = 0
@export var can_go_negative: bool = false

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = context.player_data if context else null
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	var cur_val = target.get(resource_type)
	if cur_val == null:
		result.success = false
		result.prevented_by = "unknown_resource"
		return result
	var new_val = int(cur_val) + amount
	if not can_go_negative:
		new_val = max(0, new_val)
	target.set(resource_type, new_val)
	result.values_applied[resource_type] = amount
	result.success = true
	return result
