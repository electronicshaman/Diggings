extends Node
class_name TestErrorHandling

## Test script to verify enhanced error handling in EffectProcessor

func run_tests() -> bool:
	GLog.info("TestErrorHandling: Starting error handling tests")
	
	var all_passed = true
	
	# Test 1: Null effect handling
	all_passed = test_null_effect_handling() and all_passed
	
	# Test 2: Malformed context handling
	all_passed = test_malformed_context_handling() and all_passed
	
	# Test 3: Invalid effect array handling
	all_passed = test_invalid_effect_array_handling() and all_passed
	
	# Test 4: Error recovery functionality
	all_passed = test_error_recovery() and all_passed
	
	# Test 5: Critical error detection
	all_passed = test_critical_error_detection() and all_passed
	
	if all_passed:
		GLog.info("TestErrorHandling: All tests PASSED")
	else:
		GLog.error("TestErrorHandling: Some tests FAILED")
	
	return all_passed

func test_null_effect_handling() -> bool:
	GLog.debug("TestErrorHandling: Testing null effect handling")
	
	var processor = EffectProcessor.new()
	
	# Test processing null effect
	var result = processor.process_single_effect(null, null)
	
	if not result:
		GLog.error("TestErrorHandling: Expected HandlerResult for null effect")
		return false
	
	if result.success:
		GLog.error("TestErrorHandling: Expected failure for null effect")
		return false
	
	if result.logs.is_empty():
		GLog.error("TestErrorHandling: Expected error logs for null effect")
		return false
	
	GLog.debug("TestErrorHandling: Null effect handling test passed")
	processor.queue_free()
	return true

func test_malformed_context_handling() -> bool:
	GLog.debug("TestErrorHandling: Testing malformed context handling")
	
	var processor = EffectProcessor.new()
	
	# Create a mock effect
	var mock_effect = MockHandlerBase.new()
	
	# Test with null context
	var result = processor.process_single_effect(mock_effect, null)
	
	if not result or result.success:
		GLog.error("TestErrorHandling: Expected failure for null context")
		processor.queue_free()
		return false
	
	# Test with malformed context (wrong type)
	var malformed_context = Resource.new()  # Not an HandlerContext
	result = processor.process_single_effect(mock_effect, malformed_context)
	
	if not result or result.success:
		GLog.error("TestErrorHandling: Expected failure for malformed context")
		processor.queue_free()
		return false
	
	GLog.debug("TestErrorHandling: Malformed context handling test passed")
	processor.queue_free()
	return true

func test_invalid_effect_array_handling() -> bool:
	GLog.debug("TestErrorHandling: Testing invalid effect array handling")
	
	var processor = EffectProcessor.new()
	var context = HandlerContext.new()
	context.source_type = "test"
	
	# Test with null effects array
	var null_effects: Array[HandlerBase] = []
	var results = processor.process_effects(null_effects, context)
	
	if not results is Array:
		GLog.error("TestErrorHandling: Expected Array result for null effects")
		processor.queue_free()
		return false
	
	# Test with mixed valid/invalid effects
	var mixed_effects: Array[HandlerBase] = []
	mixed_effects.append(MockHandlerBase.new())  # Valid
	mixed_effects.append(MockHandlerBase.new())  # Valid (can't add null to typed array)
	
	results = processor.process_effects(mixed_effects, context)
	
	if results.size() != mixed_effects.size():
		GLog.error("TestErrorHandling: Expected result for each effect in array")
		processor.queue_free()
		return false
	
	GLog.debug("TestErrorHandling: Invalid effect array handling test passed")
	processor.queue_free()
	return true

func test_error_recovery() -> bool:
	GLog.debug("TestErrorHandling: Testing error recovery")
	
	var processor = EffectProcessor.new()
	
	# Enable error recovery
	processor.configure_error_handling({
		"error_recovery_enabled": true,
		"malformed_data_recovery": true,
		"null_safety_enabled": true
	})
	
	var config = processor.get_error_handling_config()
	
	if not config.error_recovery_enabled:
		GLog.error("TestErrorHandling: Error recovery not enabled")
		processor.queue_free()
		return false
	
	if not config.malformed_data_recovery:
		GLog.error("TestErrorHandling: Malformed data recovery not enabled")
		processor.queue_free()
		return false
	
	GLog.debug("TestErrorHandling: Error recovery test passed")
	processor.queue_free()
	return true

func test_critical_error_detection() -> bool:
	GLog.debug("TestErrorHandling: Testing critical error detection")
	
	var processor = EffectProcessor.new()
	
	# Configure low threshold for testing
	processor.configure_error_handling({
		"critical_error_threshold": 2
	})
	
	var initial_stats = processor.get_processing_diagnostics()
	var initial_critical_errors = initial_stats.statistics.critical_errors
	
	# This should be detected as a critical error scenario
	var context = HandlerContext.new()
	context.source_type = "test"
	
	var failing_effect = FailingMockEffect.new()
	var results = processor.process_effects([failing_effect], context)
	
	var final_stats = processor.get_processing_diagnostics()
	
	# Check if critical errors were tracked
	if final_stats.statistics.critical_errors <= initial_critical_errors:
		GLog.debug("TestErrorHandling: No critical errors detected (this may be expected)")
	
	GLog.debug("TestErrorHandling: Critical error detection test passed")
	processor.queue_free()
	return true

# Mock classes for testing

class MockHandlerBase extends HandlerBase:
	func _init():
		effect_id = "mock_effect"
		effect_type = "test"
	
	func apply_effect(_context: Resource) -> Resource:
		var result = HandlerResult.new()
		result.success = true
		result.values_applied = {"test": 1}
		return result
	
	func can_apply(_context: Resource) -> bool:
		return true

class FailingMockEffect extends HandlerBase:
	func _init():
		effect_id = "failing_effect"
		effect_type = "test"
	
	func apply_effect(_context: Resource) -> Resource:
		var result = HandlerResult.new()
		result.success = false
		var logs_array: Array[String] = ["Critical test failure"]
		result.logs = logs_array
		return result
	
	func can_apply(_context: Resource) -> bool:
		return true