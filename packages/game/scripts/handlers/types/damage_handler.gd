extends "res://scripts/handlers/core/handler_base.gd"
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

var HandlerResultResource := preload("res://scripts/handlers/core/handler_result.gd")

## Applies damage to the target based on configured values and context modifiers.
## Returns a HandlerResult with damage values to be applied by DuelManager.
func apply_effect(context: Resource) -> Resource:
	var result = HandlerResultResource.new()
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
	result.values_applied["damage"] = final_amount
	if final_ignores_defense:
		result.values_applied["ignores_defense"] = true
	if multi_hit and times > 1:
		result.values_applied["damage_hits"] = times
	result.success = true
	return result

## Selects the appropriate target for this damage effect based on context and configuration.
func _select_target(context: Resource) -> Resource:
	if not context:
		return null
	if random_target and context.secondary_targets and context.secondary_targets.size() > 0:
		return context.secondary_targets[randi() % context.secondary_targets.size()]
	return context.primary_target if context.primary_target else context.enemy_data

func _resolve_conditional_bool(property_name: String, base_value: bool, context: Resource) -> bool:
	# Convert conditional int values to bool (0 = false, non-zero = true)
	var resolved_int = resolve_conditional_value(property_name, 1 if base_value else 0, context)
	return resolved_int != 0

## Generates human-readable description text for this damage effect.
## Resolves conditional values and includes curio bonuses for accurate display.
func get_description_text(context: Resource) -> String:
	var curio_bonus = _get_curio_bonus(context, "damage")
	var base_text := _build_damage_text(context, curio_bonus)
	base_text += _build_modifier_text(context)
	return base_text

## Builds the core damage value portion of the description.
func _build_damage_text(context: Resource, curio_bonus: int) -> String:
	if random_range:
		return _build_random_damage_text(context, curio_bonus)
	else:
		return _build_fixed_damage_text(context, curio_bonus)

func _build_random_damage_text(context: Resource, curio_bonus: int) -> String:
	var final_min = resolve_conditional_value("min_amount", min_amount, context) if context else min_amount
	var final_max = resolve_conditional_value("max_amount", max_amount, context) if context else max_amount
	
	if final_min == final_max:
		if curio_bonus > 0:
			return "Deal %s damage" % _format_value_with_bonus(final_min, curio_bonus, "")
		else:
			return "Deal %d damage" % final_min
	else:
		if curio_bonus > 0:
			return "Deal %d-%d [color=purple](+%d)[/color] damage" % [final_min, final_max, curio_bonus]
		else:
			return "Deal %d-%d damage" % [final_min, final_max]

func _build_fixed_damage_text(context: Resource, curio_bonus: int) -> String:
	var final_amount = resolve_conditional_value("amount", amount, context) if context else amount
	if curio_bonus > 0:
		return "Deal %s damage" % _format_value_with_bonus(final_amount, curio_bonus, "")
	else:
		return "Deal %d damage" % final_amount

## Builds modifier text (ignores defense, multi-hit) for the description.
func _build_modifier_text(context: Resource) -> String:
	var modifiers := ""
	
	var final_ignores_defense = _resolve_conditional_bool("ignores_defense", ignores_defense, context) if context else ignores_defense
	if final_ignores_defense:
		modifiers += " (ignores defense)"

	if multi_hit:
		var final_hits = resolve_conditional_value("hits", hits, context) if context else hits
		modifiers += " (%d hits)" % final_hits

	return modifiers
