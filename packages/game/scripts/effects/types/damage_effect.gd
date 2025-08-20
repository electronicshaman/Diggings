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
	
	# Resolve conditional values
	var final_amount = resolve_conditional_value("amount", amount, context)
	var final_hits = resolve_conditional_value("hits", hits, context)
	var final_ignores_defense = _resolve_conditional_bool("ignores_defense", ignores_defense, context)
	
	var times = final_hits if multi_hit else 1
	for i in times:
		var dmg = final_amount
		if target.has_method("apply_damage"):
			target.apply_damage(dmg, final_ignores_defense)
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

func _resolve_conditional_bool(property_name: String, base_value: bool, context: Resource) -> bool:
	# Convert conditional int values to bool (0 = false, non-zero = true)
	var resolved_int = resolve_conditional_value(property_name, 1 if base_value else 0, context)
	return resolved_int != 0

func get_preview_text(context: Resource) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	var base_text = "Deal %d damage" % final_amount
	
	var final_ignores_defense = _resolve_conditional_bool("ignores_defense", ignores_defense, context) if context else ignores_defense
	if final_ignores_defense:
		base_text += " (ignores defense)"
	
	if multi_hit:
		var final_hits = resolve_conditional_value("hits", hits, context) if context else hits
		base_text += " (%d hits)" % final_hits
	
	return base_text
