extends GameEffect
class_name SimpleTestEffect

## Simple test effect for deterministic testing
## Always returns a predictable result based on the test_value meta

func apply_effect(context: EffectContext) -> EffectResult:
	var result = EffectResult.new()
	result.success = true
	
	var test_value = get_meta("test_value", 0)
	result.values_applied = {"test_damage": test_value}
	result.logs = ["Applied test effect with value: %d" % test_value]
	
	return result

func can_apply(context: EffectContext) -> bool:
	return true  # Always can apply for testing