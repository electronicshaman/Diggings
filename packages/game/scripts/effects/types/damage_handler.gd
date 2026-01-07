extends "res://scripts/effects/core/effect_handler.gd"
class_name DamageHandler

@export var amount: int = 0
@export var ignores_defense: bool = false
@export var multi_hit: bool = false
@export var hits: int = 1
@export var random_target: bool = false
# Random damage range (when random_range is true, damage is randi_range(min_amount, max_amount))
@export var random_range: bool = false
@export var min_amount: int = 0
@export var max_amount: int = 0

var EffectResultResource := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResultResource.new()
	var applied = 0
	var target = _select_target(context)
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	
	# Resolve conditional values
	var final_amount: int
	if random_range:
		# Random damage between min and max
		var final_min = resolve_conditional_value("min_amount", min_amount, context)
		var final_max = resolve_conditional_value("max_amount", max_amount, context)
		final_amount = randi_range(final_min, final_max)
	else:
		final_amount = resolve_conditional_value("amount", amount, context)

	# Apply curio damage bonus from context (only for player cards)
	# Player attack cards target enemy_data, enemy attack cards target player_data
	var is_player_card = context and context.primary_target == context.enemy_data
	if is_player_card:
		var curio_damage_bonus = _get_curio_bonus(context, "damage")
		if curio_damage_bonus > 0:
			final_amount += curio_damage_bonus

	var final_hits = resolve_conditional_value("hits", hits, context)
	var final_ignores_defense = _resolve_conditional_bool("ignores_defense", ignores_defense, context)
	
	# NOTE: EffectHandler system standardizes on NOT directly mutating targets during
	# effect resolution; instead we accumulate intended outcomes in EffectResult
	# and let the central DuelManager.apply_card_results() perform mutations.
	# The previous implementation applied damage immediately AND then the
	# aggregated results pipeline applied it again, causing double damage.
	var times = final_hits if multi_hit else 1
	applied = final_amount * times
	result.values_applied["damage"] = final_amount
	if final_ignores_defense:
		result.values_applied["ignores_defense"] = true
	if multi_hit and times > 1:
		result.values_applied["damage_hits"] = times
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
	var base_text: String
	var curio_bonus = _get_curio_bonus(context, "damage")

	if random_range:
		var final_min = resolve_conditional_value("min_amount", min_amount, context) if context else min_amount
		var final_max = resolve_conditional_value("max_amount", max_amount, context) if context else max_amount
		if final_min == final_max:
			if curio_bonus > 0:
				base_text = "Deal %s damage" % _format_value_with_bonus(final_min, curio_bonus, "")
			else:
				base_text = "Deal %d damage" % final_min
		else:
			if curio_bonus > 0:
				base_text = "Deal %d-%d [color=purple](+%d)[/color] damage" % [final_min, final_max, curio_bonus]
			else:
				base_text = "Deal %d-%d damage" % [final_min, final_max]
	else:
		var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
		if curio_bonus > 0:
			base_text = "Deal %s damage" % _format_value_with_bonus(final_amount, curio_bonus, "")
		else:
			base_text = "Deal %d damage" % final_amount

	var final_ignores_defense = _resolve_conditional_bool("ignores_defense", ignores_defense, context) if context else ignores_defense
	if final_ignores_defense:
		base_text += " (ignores defense)"

	if multi_hit:
		var final_hits = resolve_conditional_value("hits", hits, context) if context else hits
		base_text += " (%d hits)" % final_hits

	return base_text
