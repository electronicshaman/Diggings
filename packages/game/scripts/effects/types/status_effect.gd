extends "res://scripts/effects/core/game_effect.gd"
class_name StatusEffect

# Status effects that modify target state (stun, debuff, etc.)

@export var status_type: String = "stun"  # stun, weaken, vulnerable, etc.
@export var duration: int = 1  # How many turns the status lasts
@export var damage_modifier: int = 0  # For debuffs: reduce/increase damage
@export var defense_modifier: int = 0  # For debuffs: reduce/increase defense

var EffectResult := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResult.new()
	if not context:
		result.success = false
		result.prevented_by = "no_context"
		return result

	# Resolve conditional values
	var final_duration = resolve_conditional_value("duration", duration, context)

	# NOTE: Like DamageEffect, we do NOT directly mutate targets during effect
	# resolution. We accumulate intended outcomes in EffectResult and let
	# DuelManager.apply_card_results() perform the actual mutations.
	match status_type:
		"stun":
			result.values_applied["stun_enemy"] = final_duration
			result.success = true
		"weaken", "vulnerable", "debuff":
			result.values_applied["enemy_debuff"] = {
				"damage_reduction": damage_modifier,
				"defense_reduction": defense_modifier,
				"duration": final_duration,
				"debuff_type": status_type
			}
			result.success = true
		_:
			# Generic status - pass through for future expansion
			result.values_applied["status"] = {
				"type": status_type,
				"duration": final_duration
			}
			result.success = true
	return result

func get_preview_text(context: Resource) -> String:
	var final_duration = resolve_conditional_value("duration", duration, context) if context else duration

	match status_type:
		"stun":
			if final_duration == 1:
				return "Enemy skips next turn"
			else:
				return "Enemy skips next %d turns" % final_duration
		"weaken", "vulnerable", "debuff":
			var effects: Array[String] = []
			if damage_modifier != 0:
				effects.append("deals %+d damage" % (-damage_modifier))
			if defense_modifier != 0:
				effects.append("gains %+d block" % (-defense_modifier))
			if effects.is_empty():
				return "Apply %s" % status_type
			var effect_text = ", ".join(effects)
			if final_duration == 1:
				return "Enemy %s next turn" % effect_text
			else:
				return "Enemy %s for %d turns" % [effect_text, final_duration]
		_:
			return "Apply %s for %d turns" % [status_type, final_duration]
