extends Node
class_name TestContextOptimization

## Test script for context optimization system
## This tests the enhanced EffectContext caching, reuse capabilities, and performance monitoring

const DEBUG_ENABLED: bool = true

func _ready() -> void:
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Starting context optimization tests")
		run_all_tests()

func run_all_tests() -> void:
	"""Run all context optimization tests."""
	test_context_caching()
	test_context_pooling()
	test_performance_monitoring()
	test_conditional_value_caching()
	
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: All tests completed")

func test_context_caching() -> void:
	"""Test context caching functionality."""
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Testing context caching")
	
	var processor = EffectProcessor.new()
	
	# Configure caching
	processor.configure_context_optimization({
		"cache_enabled": true,
		"cache_max_size": 10,
		"cache_ttl_ms": 5000
	})
	
	# Create mock card instance
	var card_instance = CardInstance.new()
	var card_data = CardData.new()
	card_data.card_id = "test_card"
	card_data.card_name = "Test Card"
	card_instance.card_data = card_data
	card_instance.owner = CardInstance.Owner.PLAYER
	
	# Create mock duel manager
	var duel_manager = DuelManager.new()
	
	# Test context creation and caching
	var context1 = processor.create_context_for_card(card_instance, duel_manager)
	var context2 = processor.create_context_for_card(card_instance, duel_manager)
	
	# Get performance stats
	var stats = processor.get_context_performance_stats()
	
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Context caching stats - Cache hits: %d, Cache misses: %d" % [
			stats.cache_hits, stats.cache_misses
		])
	
	# Clean up
	processor.queue_free()

func test_context_pooling() -> void:
	"""Test context object pooling functionality."""
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Testing context pooling")
	
	var processor = EffectProcessor.new()
	
	# Configure pooling
	processor.configure_context_optimization({
		"object_pool_enabled": true,
		"max_pool_size": 5
	})
	
	# Create and return contexts to test pooling
	var contexts = []
	for i in range(3):
		var context = processor._get_pooled_context()
		contexts.append(context)
	
	# Return contexts to pool
	for context in contexts:
		processor._return_pooled_context(context)
	
	# Get new contexts (should reuse pooled ones)
	var reused_contexts = []
	for i in range(3):
		var context = processor._get_pooled_context()
		reused_contexts.append(context)
	
	var config = processor.get_context_optimization_config()
	
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Pool size after reuse: %d" % config.current_pool_size)
	
	# Clean up
	processor.queue_free()

func test_performance_monitoring() -> void:
	"""Test performance monitoring functionality."""
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Testing performance monitoring")
	
	# Test EffectContext performance tracking
	var context = EffectContext.new()
	
	# Simulate some operations
	context.get_curio_modifications()
	context.cache_conditional_values(null)  # Test with null effect
	
	var stats = context.get_performance_stats()
	var global_stats = EffectContext.get_global_performance_stats()
	
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Context stats - Age: %dms, Access count: %d" % [
			stats.age_ms, stats.access_count
		])
		GLog.info("TestContextOptimization: Global stats - Total created: %d, Cache hit rate: %.2f" % [
			global_stats.total_contexts_created, global_stats.cache_hit_rate
		])
	
	# Clean up
	context.queue_free()

func test_conditional_value_caching() -> void:
	"""Test conditional value caching in EffectContext."""
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Testing conditional value caching")
	
	var context = EffectContext.new()
	
	# Set up mock player data
	var player_data = PlayerData.new()
	player_data.health = 80
	player_data.max_health = 100
	player_data.sanity = 60
	player_data.max_sanity = 100
	player_data.gold = 50
	
	context.player_data = player_data
	
	# Create mock effect
	var effect = GameEffect.new()
	effect.effect_id = "test_effect"
	
	# Cache conditional values
	context.cache_conditional_values(effect)
	
	# Test cached value retrieval
	var health_percentage = context.get_cached_conditional_value(effect, "player_health_percentage", 0.0)
	var sanity_percentage = context.get_cached_conditional_value(effect, "player_sanity_percentage", 0.0)
	var gold = context.get_cached_conditional_value(effect, "player_gold", 0)
	
	if DEBUG_ENABLED:
		GLog.info("TestContextOptimization: Cached values - Health: %.2f%%, Sanity: %.2f%%, Gold: %d" % [
			health_percentage * 100, sanity_percentage * 100, gold
		])
	
	# Test cache invalidation
	context.invalidate_cache()
	
	# Clean up
	context.queue_free()
	player_data.queue_free()
	effect.queue_free()

## Run a specific test by name
func run_test(test_name: String) -> void:
	"""Run a specific test by name."""
	match test_name:
		"caching":
			test_context_caching()
		"pooling":
			test_context_pooling()
		"monitoring":
			test_performance_monitoring()
		"conditional":
			test_conditional_value_caching()
		_:
			if DEBUG_ENABLED:
				GLog.warn("TestContextOptimization: Unknown test name: %s" % test_name)