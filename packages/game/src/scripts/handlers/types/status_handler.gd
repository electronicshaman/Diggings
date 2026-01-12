extends "res://scripts/handlers/core/handler_base.gd"
class_name StatusHandler
## Applies status effects to targets using the StatusEffectManager system.
## Supports all 18 status effects defined in STATUS_EFFECTS_SPEC.md.

## The status effect ID (e.g., "poison", "grit", "weak")
@export var status_effect_id: String = ""

## Number of stacks to apply
@export var stacks: int = 1

## Target for the status: "enemy" or "self"
@export var apply_to: String = "enemy"

## LEGACY: Old status_type field for backward compatibility
@export var status_type: String = "" # Deprecated, use status_effect_id
@export var duration: int = 1 # Deprecated, stacks now represent duration
@export var damage_modifier: int = 0 # Deprecated
@export var defense_modifier: int = 0 # Deprecated


## Applies a status effect to the target.
## Returns a HandlerResult with status data to be applied by CardResolver.
func apply_effect(context: Resource) -> Resource:
	var result = HandlerResult.new()
	if not context:
		result.success = false
		result.prevented_by = "no_context"
		return result

	# Handle legacy fields for backward compatibility
	var effect_id := status_effect_id if not status_effect_id.is_empty() else _convert_legacy_status()
	var final_stacks := resolve_conditional_value("stacks", stacks, context)

	# If still using legacy system without conversion, use old behavior
	if effect_id.is_empty() and not status_type.is_empty():
		return _apply_legacy_effect(context)

	# New status effect system
	result.values_applied["apply_status"] = {
		"effect_id": effect_id,
		"stacks": final_stacks,
		"target_type": apply_to
	}
	result.success = true
	return result


func get_description_text(context: Resource) -> String:
	# Handle legacy descriptions
	var effect_id := status_effect_id if not status_effect_id.is_empty() else _convert_legacy_status()
	if effect_id.is_empty() and not status_type.is_empty():
		return _get_legacy_description(context)

	var final_stacks := resolve_conditional_value("stacks", stacks, context) if context else stacks
	var target_text := "yourself" if apply_to == "self" else "enemy"
	var effect_name := effect_id.capitalize().replace("_", " ")

	if final_stacks == 1:
		return "Apply %s to %s" % [effect_name, target_text]
	else:
		return "Apply %d %s to %s" % [final_stacks, effect_name, target_text]


## Convert legacy status_type to new effect_id
func _convert_legacy_status() -> String:
	match status_type:
		"stun":
			return "disarmed"
		"weaken", "weak":
			return "weak"
		"vulnerable":
			return "wounded"
		"frail":
			return "rattled"
		"strength":
			return "grit"
		"dexterity":
			return "guard"
		"vigor":
			return "surge"
		_:
			return ""


## Legacy effect application for backward compatibility
func _apply_legacy_effect(context: Resource) -> Resource:
	var result = HandlerResult.new()
	var final_duration = resolve_conditional_value("duration", duration, context)

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
			result.values_applied["status"] = {
				"type": status_type,
				"duration": final_duration
			}
			result.success = true
	return result


## Legacy description generation
func _get_legacy_description(context: Resource) -> String:
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
				effects.append("gains %+d defense" % (-defense_modifier))
			if effects.is_empty():
				return "Apply %s" % status_type
			var effect_text = ", ".join(effects)
			if final_duration == 1:
				return "Enemy %s next turn" % effect_text
			else:
				return "Enemy %s for %d turns" % [effect_text, final_duration]
		_:
			return "Apply %s for %d turns" % [status_type, final_duration]
