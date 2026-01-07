extends Resource
class_name ConditionalValue

# Allows effect values to change based on conditions
# Example: Ambush damage is 15 if first card, 6 otherwise

@export var property_name: String = "" # Which property this affects (e.g., "amount", "hits")
@export var condition: HandlerCondition
@export var value_if_true: int = 0
@export var value_if_false: int = 0
@export var applies_to_base_value: bool = false # If true, modifies base value; if false, replaces it

func resolve_value(context: Resource, base_value: int = 0) -> int:
	if not condition:
		return base_value
	
	var condition_met = condition.evaluate(context)
	var conditional_result = value_if_true if condition_met else value_if_false
	
	if applies_to_base_value:
		# Modify the base value (add/subtract)
		return base_value + conditional_result
	else:
		# Replace the base value entirely
		return conditional_result

func get_description() -> String:
	var condition_desc = condition.get_description() if condition else "no condition"
	
	if applies_to_base_value:
		var modifier_true = "+" + str(value_if_true) if value_if_true >= 0 else str(value_if_true)
		var modifier_false = "+" + str(value_if_false) if value_if_false >= 0 else str(value_if_false)
		return "%s: %s if %s, %s otherwise" % [property_name, modifier_true, condition_desc, modifier_false]
	else:
		return "%s: %d if %s, %d otherwise" % [property_name, value_if_true, condition_desc, value_if_false]