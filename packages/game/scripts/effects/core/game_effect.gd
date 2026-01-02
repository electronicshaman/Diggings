extends Resource
class_name GameEffect

@export var effect_id: String = ""
@export var effect_type: String = ""
@export var target_type: String = "player" # "player", "enemy", "all", "random"
@export var timing: String = "immediate" # "immediate", "delayed", "persistent"
@export var description: String = ""
@export var delayed: bool = false
@export var delay_turns: int = 0

# Execution and ordering
@export var priority: int = 0
@export var phase: String = "default" # e.g., "on_play", "turn_start", "turn_end"

# Stacking semantics
@export var stack_key: String = ""
@export var stack_behavior: String = "independent" # "independent" | "stack_values" | "refresh_duration" | "cap_value"
@export var stack_cap: int = 0 # 0 = no cap

# Versioning for save/migration
@export var version: int = 1
@export var tags: Array[String] = []

# Conditional activation and values
@export var activation_condition: EffectCondition  # Optional condition for when effect applies
@export var conditional_values: Array[ConditionalValue] = []  # Values that change based on conditions

func apply_effect(_context: Resource) -> Resource:
	# Should return EffectResult
	return null

func can_apply(_context: Resource) -> bool:
	# Check activation condition if present
	if activation_condition:
		return activation_condition.evaluate(_context)
	return true

func get_preview_text(_context: Resource) -> String:
	return description

func get_formatted_description(context: Resource = null) -> String:
	"""Compatibility method for CardData description generation"""
	return get_preview_text(context)

func on_added(_context: Resource) -> void:
	pass

func on_removed(_context: Resource) -> void:
	pass

# Helper method to resolve conditional values for a given property
# Processes ALL conditional values with the matching property name, accumulating their effects
func resolve_conditional_value(property_name: String, base_value: int, context: Resource) -> int:
	var resolved_value = base_value
	var found_any = false
	
	for conditional_value in conditional_values:
		if conditional_value.property_name == property_name:
			found_any = true
			# Use resolve_value which handles both applies_to_base_value cases correctly
			# Pass resolved_value (not base_value) so modifications accumulate if multiple conditional values exist
			resolved_value = conditional_value.resolve_value(context, resolved_value)
	
	return resolved_value if found_any else base_value

# Get description including conditions
func get_full_description(context: Resource = null) -> String:
	var base_desc = description

	if activation_condition:
		base_desc += " (if " + activation_condition.get_description() + ")"

	if conditional_values.size() > 0:
		base_desc += " ["
		for i in range(conditional_values.size()):
			if i > 0:
				base_desc += ", "
			base_desc += conditional_values[i].get_description()
		base_desc += "]"

	return base_desc

## Helper to get curio bonus from context
## Returns the curio modification value for the given bonus type (damage, defense, cost, draw)
func _get_curio_bonus(context: Resource, bonus_type: String) -> int:
	if not context:
		return 0
	if not "curio_modifications" in context:
		return 0
	var mods = context.curio_modifications
	if not mods or not mods.has(bonus_type):
		return 0
	return mods.get(bonus_type, 0)

## Helper to format value with curio bonus for display
## Returns formatted text like "8 [color=purple](+3)[/color]" or just "8" if no bonus
func _format_value_with_bonus(base_value: int, bonus: int, label: String = "") -> String:
	if bonus > 0:
		if label.is_empty():
			return "%d [color=purple](+%d)[/color]" % [base_value, bonus]
		else:
			return "%d [color=purple](+%d)[/color] %s" % [base_value, bonus, label]
	else:
		if label.is_empty():
			return "%d" % base_value
		else:
			return "%d %s" % [base_value, label]
