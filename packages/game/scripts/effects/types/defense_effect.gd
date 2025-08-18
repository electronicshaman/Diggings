extends "res://scripts/effects/core/game_effect.gd"
class_name DefenseEffect

@export var amount: int = 0
@export var duration: int = 0
@export var condition: String = "" # descriptive only; enforcement left to systems

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var target = context.primary_target if context and context.primary_target else (context.player_data if context else null)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	if target.has_method("add_armor"):
		target.add_armor(amount)
	else:
		var armor = target.get("armor")
		if armor != null:
			target.set("armor", int(armor) + amount)
	result.values_applied["defense"] = amount
	result.values_applied["duration"] = duration
	result.values_applied["condition"] = condition
	result.success = true
	return result
