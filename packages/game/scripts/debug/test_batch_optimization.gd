extends Node
class_name TestBatchOptimization

## Test script for batch processing optimization functionality
## This script tests the performance improvements and correctness of batch processing

const DEBUG_ENABLED: bool = true

func _ready():
	if DEBUG_ENABLED:
		GLog.info("TestBatchOptimization: Starting batch optimization tests")
		test_batch_optimization_functionality()

## Test batch processing optimization functionality
func test_batch_optimization_functionality():
	var effect_processor = EffectProcessor.new()
	
	# Test 1: Configuration
	test_optimization_configuration(effect_processor)
	
	# Test 2: Object pooling
	test_object_pooling(effect_processor)
	
	# Test 3: Validation caching
	test_validation_caching(effect_processor)
	
	# Test 4: Performance comparison
	test_performance_comparison(effect_processor)
	
	# Test 5: Batch size thresholds
	test_batch_size_thresholds(effect_processor)
	
	if DEBUG_ENABLED:
		GLog.info("TestBatchOptimization: All batch optimization tests completed")

## Test optimization configuration
func test_optimization_configuration(processor: EffectProcessor):
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Testing optimization configuration")
	
	# Test default configuration
	var default_config = processor.get_batch_optimization_config()
	assert(default_config.has("batch_optimization_enabled"), "Default config should have batch_optimization_enabled")
	assert(default_config.has("batch_size_threshold"), "Default config should have batch_size_threshold")
	assert(default_config.has("object_pool_enabled"), "Default config should have object_pool_enabled")
	
	# Test configuration changes
	processor.configure_batch_optimization({
		"batch_optimization_enabled": false,
		"batch_size_threshold": 10,
		"object_pool_enabled": false,
		"validation_cache_enabled": false
	})
	
	var updated_config = processor.get_batch_optimization_config()
	assert(not updated_config.batch_optimization_enabled, "Batch optimization should be disabled")
	assert(updated_config.batch_size_threshold == 10, "Batch size threshold should be 10")
	assert(not updated_config.object_pool_enabled, "Object pooling should be disabled")
	
	# Reset to defaults
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 5,
		"object_pool_enabled": true,
		"validation_cache_enabled": true
	})
	
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Configuration test passed")

## Test object pooling functionality
func test_object_pooling(processor: EffectProcessor):
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Testing object pooling")
	
	# Enable object pooling
	processor.configure_batch_optimization({"object_pool_enabled": true})
	
	# Get initial pool stats
	var initial_stats = processor.get_batch_performance_stats()
	var initial_pooled = initial_stats.get("objects_pooled", 0)
	
	# Create test effects that should trigger pooling
	var test_effects: Array[EffectHandler] = []
	for i in range(10):  # Above threshold to trigger optimization
		var effect = DamageHandler.new()
		effect.effect_id = "pool_test_effect_%d" % i
		effect.amount = 1
		test_effects.append(effect)
	
	# Create test context
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "pool_test"
	
	# Process effects (should use object pooling)
	var results = processor.process_effects(test_effects, context)
	
	# Check that pooling was used
	var final_stats = processor.get_batch_performance_stats()
	var final_pooled = final_stats.get("objects_pooled", 0)
	
	assert(results.size() == test_effects.size(), "Should process all effects")
	assert(final_pooled > initial_pooled, "Object pooling should have been used")
	
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Object pooling test passed - %d objects pooled" % (final_pooled - initial_pooled))

## Test validation caching functionality
func test_validation_caching(processor: EffectProcessor):
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Testing validation caching")
	
	# Enable validation caching
	processor.configure_batch_optimization({"validation_cache_enabled": true})
	
	# Clear caches to start fresh
	processor.clear_optimization_caches()
	
	# Get initial cache stats
	var initial_stats = processor.get_batch_performance_stats()
	var initial_cache_hits = initial_stats.get("validation_cache_hits", 0)
	
	# Create test effects
	var test_effects: Array[EffectHandler] = []
	for i in range(8):  # Above threshold
		var effect = DamageHandler.new()
		effect.effect_id = "cache_test_effect_%d" % i
		effect.amount = 1
		test_effects.append(effect)
	
	# Create test context
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "cache_test"
	
	# Process effects first time (should populate cache)
	processor.process_effects(test_effects, context)
	
	# Process same pattern again (should hit cache)
	processor.process_effects(test_effects, context)
	
	# Check that caching was used
	var final_stats = processor.get_batch_performance_stats()
	var final_cache_hits = final_stats.get("validation_cache_hits", 0)
	
	assert(final_cache_hits > initial_cache_hits, "Validation caching should have been used")
	
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Validation caching test passed - %d cache hits" % (final_cache_hits - initial_cache_hits))

## Test performance comparison between optimized and standard processing
func test_performance_comparison(processor: EffectProcessor):
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Testing performance comparison")
	
	# Create a larger set of test effects
	var test_effects: Array[EffectHandler] = []
	for i in range(20):  # Large enough to see performance difference
		var effect = DamageHandler.new()
		effect.effect_id = "perf_test_effect_%d" % i
		effect.amount = 1
		test_effects.append(effect)
	
	# Create test context
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "performance_test"
	
	# Test with optimizations enabled
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 5
	})
	
	var optimized_start = Time.get_ticks_msec()
	var optimized_results = processor.process_effects(test_effects, context)
	var optimized_time = Time.get_ticks_msec() - optimized_start
	
	# Test with optimizations disabled
	processor.configure_batch_optimization({
		"batch_optimization_enabled": false
	})
	
	var standard_start = Time.get_ticks_msec()
	var standard_results = processor.process_effects(test_effects, context)
	var standard_time = Time.get_ticks_msec() - standard_start
	
	# Verify results are equivalent
	assert(optimized_results.size() == standard_results.size(), "Results should be equivalent")
	
	# Log performance comparison
	if DEBUG_ENABLED:
		var improvement = 0.0
		if standard_time > 0:
			improvement = ((standard_time - optimized_time) / float(standard_time)) * 100.0
		
		GLog.debug("TestBatchOptimization: Performance comparison - Optimized: %dms, Standard: %dms, Improvement: %.1f%%" % [
			optimized_time, standard_time, improvement
		])
	
	# Re-enable optimizations for other tests
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 5
	})

## Test batch size threshold behavior
func test_batch_size_thresholds(processor: EffectProcessor):
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Testing batch size thresholds")
	
	# Set a high threshold
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 15
	})
	
	# Get initial optimization stats
	var initial_stats = processor.get_batch_performance_stats()
	var initial_optimized = initial_stats.get("batches_optimized", 0)
	
	# Create small batch (below threshold)
	var small_effects: Array[EffectHandler] = []
	for i in range(5):  # Below threshold
		var effect = DamageHandler.new()
		effect.effect_id = "small_batch_effect_%d" % i
		effect.amount = 1
		small_effects.append(effect)
	
	# Create large batch (above threshold)
	var large_effects: Array[EffectHandler] = []
	for i in range(20):  # Above threshold
		var effect = DamageHandler.new()
		effect.effect_id = "large_batch_effect_%d" % i
		effect.amount = 1
		large_effects.append(effect)
	
	# Create test context
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "threshold_test"
	
	# Process small batch (should use standard processing)
	processor.process_effects(small_effects, context)
	
	# Process large batch (should use optimized processing)
	processor.process_effects(large_effects, context)
	
	# Check that only the large batch was optimized
	var final_stats = processor.get_batch_performance_stats()
	var final_optimized = final_stats.get("batches_optimized", 0)
	
	assert(final_optimized == initial_optimized + 1, "Only large batch should have been optimized")
	
	if DEBUG_ENABLED:
		GLog.debug("TestBatchOptimization: Batch size threshold test passed")

## Run a comprehensive benchmark
func run_benchmark():
	if DEBUG_ENABLED:
		GLog.info("TestBatchOptimization: Running comprehensive benchmark")
	
	var processor = EffectProcessor.new()
	
	# Configure for benchmarking
	processor.configure_batch_optimization({
		"batch_optimization_enabled": true,
		"batch_size_threshold": 1,
		"object_pool_enabled": true,
		"validation_cache_enabled": true
	})
	
	# Run benchmark with different effect counts
	var effect_counts = [1, 5, 10, 25, 50]
	var benchmark_results = processor.benchmark_batch_processing(effect_counts, 5)
	
	# Log results
	if DEBUG_ENABLED:
		GLog.info("TestBatchOptimization: Benchmark Results:")
		for test_key in benchmark_results.results.keys():
			var result = benchmark_results.results[test_key]
			GLog.info("  %s: %.1fms optimized, %.1fms standard, %.1f%% improvement" % [
				test_key,
				result.optimized_avg,
				result.standard_avg,
				result.performance_improvement
			])