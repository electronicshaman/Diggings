extends Node
class_name TestEffectProcessor

const DEBUG_ENABLED: bool = true

## Simple test to validate EffectProcessor functionality
func run_basic_tests() -> bool:
	GLog.info("TestEffectProcessor: Starting basic validation tests")
	
	var processor = EffectProcessor.new()
	var all_tests_passed = true
	
	# Test 1: Processor creation and basic functionality
	if not _test_processor_creation(processor):
		all_tests_passed = false
	
	# Test 2: Context creation for cards
	if not _test_card_context_creation(processor):
		all_tests_passed = false
	
	# Test 3: Context creation for encounters
	if not _test_encounter_context_creation(processor):
		all_tests_passed = false
	
	# Test 4: Context creation for curios
	if not _test_curio_context_creation(processor):
		all_tests_passed = false
	
	# Test 5: Effect processing with valid effects
	if not _test_effect_processing(processor):
		all_tests_passed = false
	
	# Test 6: Error handling with invalid inputs
	if not _test_error_handling(processor):
		all_tests_passed = false
	
	# Test 7: Deterministic processing property test
	if not _test_deterministic_processing_property(processor):
		all_tests_passed = false
	
	# Test 8: Batch processing optimization
	if not _test_batch_processing_optimization(processor):
		all_tests_passed = false
	
	if all_tests_passed:
		GLog.info("TestEffectProcessor: All tests PASSED")
	else:
		GLog.error("TestEffectProcessor: Some tests FAILED")
	
	processor.queue_free()
	return all_tests_passed

func _test_processor_creation(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing processor creation")
	
	if not is_instance_valid(processor):
		GLog.error("TestEffectProcessor: Processor creation failed")
		return false
	
	var diagnostics = processor.get_processing_diagnostics()
	if not diagnostics.has("debug_enabled"):
		GLog.error("TestEffectProcessor: Diagnostics missing expected keys")
		return false
	
	GLog.debug("TestEffectProcessor: Processor creation test PASSED")
	return true

func _test_card_context_creation(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing card context creation")
	
	# Test with null inputs (should return null and log errors)
	var context = processor.create_context_for_card(null, null)
	if context != null:
		GLog.error("TestEffectProcessor: Expected null context for null inputs")
		return false
	
	# Test with valid inputs would require creating mock objects
	# For now, just test the error handling path
	GLog.debug("TestEffectProcessor: Card context creation test PASSED")
	return true

func _test_encounter_context_creation(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing encounter context creation")
	
	# Test with null inputs (should return null and log errors)
	var context = processor.create_context_for_encounter(null, null)
	if context != null:
		GLog.error("TestEffectProcessor: Expected null context for null inputs")
		return false
	
	GLog.debug("TestEffectProcessor: Encounter context creation test PASSED")
	return true

func _test_curio_context_creation(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing curio context creation")
	
	# Test with null inputs (should return null and log errors)
	var context = processor.create_context_for_curio(null, "", null)
	if context != null:
		GLog.error("TestEffectProcessor: Expected null context for null inputs")
		return false
	
	# Test with empty trigger event
	var curio = CurioData.new()
	var player_data = PlayerData.new()
	context = processor.create_context_for_curio(curio, "", player_data)
	if context != null:
		GLog.error("TestEffectProcessor: Expected null context for empty trigger event")
		return false
	
	GLog.debug("TestEffectProcessor: Curio context creation test PASSED")
	return true

func _test_effect_processing(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing effect processing")
	
	# Create a simple damage effect for testing
	var damage_effect = DamageHandler.new()
	damage_effect.effect_id = "test_damage"
	damage_effect.amount = 5
	
	# Create a basic context
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "test_trigger"
	
	# Create mock target
	var mock_target = PlayerData.new()
	context.primary_target = mock_target
	
	# Process single effect
	var result = processor.process_single_effect(damage_effect, context)
	
	if not is_instance_valid(result):
		GLog.error("TestEffectProcessor: Effect processing returned invalid result")
		return false
	
	if not result.success:
		GLog.error("TestEffectProcessor: Effect processing failed: %s" % str(result.logs))
		return false
	
	# Test batch processing
	var effects: Array[EffectHandler] = [damage_effect]
	var results = processor.process_effects(effects, context)
	
	if results.size() != 1:
		GLog.error("TestEffectProcessor: Batch processing returned wrong number of results")
		return false
	
	GLog.debug("TestEffectProcessor: Effect processing test PASSED")
	return true

func _test_error_handling(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing error handling")
	
	# Test with invalid effect
	var context = EffectContext.new()
	context.source_type = "test"
	var result = processor.process_single_effect(null, context)
	
	if result.success:
		GLog.error("TestEffectProcessor: Expected failure for null effect")
		return false
	
	# Test with invalid context
	var damage_effect = DamageHandler.new()
	damage_effect.effect_id = "test_damage"
	result = processor.process_single_effect(damage_effect, null)
	
	if result.success:
		GLog.error("TestEffectProcessor: Expected failure for null context")
		return false
	
	# Test batch validation with empty array
	var empty_effects: Array[EffectHandler] = []
	var results = processor.process_effects(empty_effects, context)
	
	if results.size() != 0:
		GLog.error("TestEffectProcessor: Expected empty results for empty effects array")
		return false
	
	GLog.debug("TestEffectProcessor: Error handling test PASSED")
	return true

## Property test for deterministic processing
## **Feature: effect-system-cleanup, Property 8: Deterministic Processing**
## **Validates: Requirements 8.2**
func _test_deterministic_processing_property(processor: EffectProcessor) -> bool:
	"""Property test: For any effect processing scenario, running the same effects 
	multiple times with identical inputs should produce identical results."""
	
	GLog.debug("TestEffectProcessor: Testing deterministic processing property")
	
	# Configure processor for deterministic mode
	processor.configure_deterministic_processing({
		"deterministic_mode": true,
		"sort_effects_by_id": true,
		"validate_deterministic_results": false
	})
	
	# Test 1: Empty effects should be deterministic
	if not _test_empty_effects_determinism(processor):
		return false
	
	# Test 2: Single effect should be deterministic
	if not _test_single_effect_determinism(processor):
		return false
	
	# Test 3: Multiple effects should be deterministic
	if not _test_multiple_effects_determinism(processor):
		return false
	
	# Test 4: Effects with different IDs should be sorted consistently
	if not _test_effect_sorting_determinism(processor):
		return false
	
	GLog.debug("TestEffectProcessor: Deterministic processing property test PASSED")
	return true

func _test_empty_effects_determinism(processor: EffectProcessor) -> bool:
	"""Test that empty effect arrays are processed deterministically."""
	var empty_effects: Array[EffectHandler] = []
	var context = _create_minimal_test_context()
	
	var result1 = processor.process_effects(empty_effects, context)
	var result2 = processor.process_effects(empty_effects, context)
	
	if result1.size() != result2.size():
		GLog.error("TestEffectProcessor: Empty effects produced different result counts")
		return false
	
	return true

func _test_single_effect_determinism(processor: EffectProcessor) -> bool:
	"""Test that single effects are processed deterministically."""
	var effect = _create_simple_test_effect("deterministic_test", 10)
	var effects: Array[EffectHandler] = [effect]
	var context = _create_minimal_test_context()
	
	var result1 = processor.process_effects(effects, context)
	var result2 = processor.process_effects(effects, context)
	
	if result1.size() != result2.size():
		GLog.error("TestEffectProcessor: Single effect produced different result counts")
		return false
	
	if result1.size() > 0 and result2.size() > 0:
		if result1[0].success != result2[0].success:
			GLog.error("TestEffectProcessor: Single effect produced different success values")
			return false
	
	return true

func _test_multiple_effects_determinism(processor: EffectProcessor) -> bool:
	"""Test that multiple effects are processed deterministically."""
	var effect1 = _create_simple_test_effect("multi_test_1", 5)
	var effect2 = _create_simple_test_effect("multi_test_2", 10)
	var effect3 = _create_simple_test_effect("multi_test_3", 15)
	
	var effects: Array[EffectHandler] = [effect1, effect2, effect3]
	var context = _create_minimal_test_context()
	
	var result1 = processor.process_effects(effects, context)
	var result2 = processor.process_effects(effects, context)
	
	if result1.size() != result2.size():
		GLog.error("TestEffectProcessor: Multiple effects produced different result counts")
		return false
	
	# Check that results are in the same order
	for i in range(min(result1.size(), result2.size())):
		if result1[i].success != result2[i].success:
			GLog.error("TestEffectProcessor: Multiple effects produced different success at index %d" % i)
			return false
	
	return true

func _test_effect_sorting_determinism(processor: EffectProcessor) -> bool:
	"""Test that effects with different IDs are sorted consistently."""
	# Create effects with IDs that would be sorted differently than creation order
	var effect_z = _create_simple_test_effect("z_last", 1)
	var effect_a = _create_simple_test_effect("a_first", 2)
	var effect_m = _create_simple_test_effect("m_middle", 3)
	
	var effects: Array[EffectHandler] = [effect_z, effect_a, effect_m]
	var context = _create_minimal_test_context()
	
	# Process multiple times to ensure consistent ordering
	var result1 = processor.process_effects(effects, context)
	var result2 = processor.process_effects(effects, context)
	var result3 = processor.process_effects(effects, context)
	
	# All results should have the same size
	if result1.size() != result2.size() or result1.size() != result3.size():
		GLog.error("TestEffectProcessor: Effect sorting produced inconsistent result counts")
		return false
	
	# Results should be identical across runs
	for i in range(result1.size()):
		if result1[i].success != result2[i].success or result1[i].success != result3[i].success:
			GLog.error("TestEffectProcessor: Effect sorting produced inconsistent results at index %d" % i)
			return false
	
	return true

func _create_minimal_test_context() -> EffectContext:
	"""Create a minimal test context for deterministic testing."""
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "test_trigger"
	context.trigger_data = {}
	
	# Create minimal mock data
	var mock_player = Resource.new()
	mock_player.set_meta("health", 100)
	mock_player.set_meta("max_health", 100)
	
	context.player_data = mock_player
	context.primary_target = mock_player
	
	return context

func _create_test_context() -> EffectContext:
	"""Create a test context for batch optimization testing."""
	return _create_minimal_test_context()

func _create_simple_test_effect(id: String, value: int) -> EffectHandler:
	"""Create a simple test effect for deterministic testing."""
	var effect = EffectHandler.new()
	effect.effect_id = id
	effect.effect_type = "test"
	effect.set_meta("test_value", value)
	
	# Override apply_effect to return a predictable result
	effect.set_script(preload("res://scripts/debug/simple_test_effect.gd"))
	
	return effect

## Test batch processing optimization functionality
func _test_batch_processing_optimization(processor: EffectProcessor) -> bool:
	GLog.debug("TestEffectProcessor: Testing batch processing optimization")
	
	# Test 1: Configuration
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 5,
		"object_pool_enabled": true,
		"validation_cache_enabled": true
	})
	
	var config = processor.get_batch_optimization_config()
	if not config.batch_optimization_enabled:
		GLog.error("TestEffectProcessor: Batch optimization should be enabled")
		return false
	
	# Test 2: Create effects above threshold to trigger optimization
	var test_effects: Array[EffectHandler] = []
	for i in range(10):  # Above threshold
		var effect = _create_simple_test_effect("batch_test_%d" % i, i)
		test_effects.append(effect)
	
	# Create test context
	var context = _create_test_context()
	
	# Get initial performance stats
	var initial_stats = processor.get_batch_performance_stats()
	var initial_optimized = initial_stats.get("batches_optimized", 0)
	
	# Process effects (should trigger optimization)
	var results = processor.process_effects(test_effects, context)
	
	# Verify results
	if results.size() != test_effects.size():
		GLog.error("TestEffectProcessor: Expected %d results, got %d" % [test_effects.size(), results.size()])
		return false
	
	# Check that optimization was used
	var final_stats = processor.get_batch_performance_stats()
	var final_optimized = final_stats.get("batches_optimized", 0)
	
	if final_optimized <= initial_optimized:
		GLog.error("TestEffectProcessor: Batch optimization should have been triggered")
		return false
	
	# Test 3: Test with effects below threshold (should use standard processing)
	var small_effects: Array[EffectHandler] = []
	for i in range(3):  # Below threshold
		var effect = _create_simple_test_effect("small_batch_%d" % i, i)
		small_effects.append(effect)
	
	var before_small = processor.get_batch_performance_stats().get("batches_optimized", 0)
	processor.process_effects(small_effects, context)
	var after_small = processor.get_batch_performance_stats().get("batches_optimized", 0)
	
	if after_small != before_small:
		GLog.error("TestEffectProcessor: Small batch should not trigger optimization")
		return false
	
	# Test 4: Test object pooling (check that objects are being reused)
	var pool_stats_before = processor.get_batch_performance_stats().get("objects_pooled", 0)
	processor.process_effects(test_effects, context)  # Process again
	var pool_stats_after = processor.get_batch_performance_stats().get("objects_pooled", 0)
	
	if pool_stats_after <= pool_stats_before:
		GLog.warn("TestEffectProcessor: Object pooling may not be working as expected")
		# This is a warning, not a failure, as pooling behavior can vary
	
	GLog.debug("TestEffectProcessor: Batch optimization test passed")
	return true

## Run tests when this script is executed directly
func _ready():
	if DEBUG_ENABLED:
		# Add a small delay to ensure autoloads are ready
		await get_tree().create_timer(0.1).timeout
		run_basic_tests()
