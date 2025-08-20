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
func resolve_conditional_value(property_name: String, base_value: int, context: Resource) -> int:
	for conditional_value in conditional_values:
		if conditional_value.property_name == property_name:
			return conditional_value.resolve_value(context, base_value)
	
	return base_value

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
