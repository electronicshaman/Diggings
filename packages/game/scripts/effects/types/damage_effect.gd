extends "res://scripts/effects/core/game_effect.gd"
class_name DamageEffect

@export var amount: int = 0
@export var ignores_defense: bool = false
@export var multi_hit: bool = false
@export var hits: int = 1
@export var random_target: bool = false

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	var applied = 0
	var target = _select_target(context)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	var times = hits if multi_hit else 1
	for i in times:
		var dmg = amount
		if target.has_method("apply_damage"):
			target.apply_damage(dmg, ignores_defense)
		elif target.has_method("take_damage"):
			target.take_damage(dmg)
		applied += dmg
	result.values_applied["damage"] = applied
	result.success = true
	return result

func _select_target(context):
	if not context:
		return null
	if random_target and context.secondary_targets and context.secondary_targets.size() > 0:
		return context.secondary_targets[randi() % context.secondary_targets.size()]
	return context.primary_target if context.primary_target else context.enemy_data
