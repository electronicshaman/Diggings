extends HandlerBase
class_name SimpleTestEffect

## Simple test effect for deterministic testing
## Always returns a predictable result based on the test_value meta

func apply_effect(context: Resource) -> Resource:
	var result = HandlerResult.new()
	result.success = true
	
	var test_value = get_meta("test_value", 0)
	result.values_applied = {"test_damage": test_value}
	var logs_array: Array[String] = ["Applied test effect with value: %d" % test_value]
	result.logs = logs_array
	
	return result

func can_apply(context: Resource) -> bool:
	return true  # Always can apply for testing
