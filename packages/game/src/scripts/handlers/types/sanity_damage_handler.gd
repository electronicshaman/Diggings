extends "res://scripts/handlers/core/handler_base.gd"
class_name SanityDamageHandler

## Handler for dealing sanity damage to targets.
## Used by eldritch enemy attacks and cosmic horror effects.
## Unlike SanityHandler (which modifies sanity generally), this represents
## hostile mental attacks that specifically reduce sanity.

@export var amount: int = 0 # Base sanity damage
@export var percentage_based: bool = false # Damage as % of max sanity

## Apply sanity damage to the target.
## Returns a HandlerResult with sanity_damage value to be applied later.
func apply_effect(context: Resource) -> Resource:
	var result = HandlerResult.new()
	
	# Determine target - for enemy cards, target is typically player_data
	var target = context.primary_target if context and context.primary_target else null
	if target == null and context:
		target = context.player_data
	
	if target == null:
		result.success = false
		result.prevented_by = "no_target"
		return result
	
	# Get max sanity for percentage calculations
	var max_sanity = _get_target_max_sanity(target)
	
	# Calculate damage amount
	var damage_amount = amount
	if percentage_based and max_sanity > 0:
		damage_amount = int(round(float(max_sanity) * clamp(amount / 100.0, 0.0, 1.0)))
	
	# Resolve conditional values (for cards with scaling sanity damage)
	damage_amount = resolve_conditional_value("amount", damage_amount, context)
	
	# Ensure non-negative
	damage_amount = max(0, damage_amount)
	
	# Store as sanity_damage for later application by the effect system
	result.values_applied["sanity_damage"] = damage_amount
	result.success = true
	
	return result


## Get max sanity from target, handling different resource types.
func _get_target_max_sanity(target: Resource) -> int:
	if target == null:
		return 20 # Default if no target
	
	# Try direct stats property (PlayerData, EnemyState)
	if "stats" in target and target.stats:
		return target.stats.max_sanity
	
	# Try direct max_sanity property
	if "max_sanity" in target:
		return target.max_sanity
	
	return 20 # Default


## Generate formatted description for card display.
func get_formatted_description(_context: Resource = null) -> String:
	if percentage_based:
		return "Deal %d%% sanity damage" % amount
	return "Deal %d sanity damage" % amount
