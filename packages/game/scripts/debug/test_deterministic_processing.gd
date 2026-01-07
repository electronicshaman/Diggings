extends Node
class_name TestDeterministicProcessing

const DEBUG_ENABLED: bool = true

## Property test for deterministic processing in EffectProcessor
## **Feature: effect-system-cleanup, Property 8: Deterministic Processing**
## **Validates: Requirements 8.2**

func run_deterministic_processing_property_test() -> bool:
	"""Property test: For any effect processing scenario, running the same effects 
	multiple times with identical inputs should produce identical results."""
	
	GLog.info("TestDeterministicProcessing: Starting property test for deterministic processing")
	
	var processor = EffectProcessor.new()
	var test_passed = true
	var iterations = 100  # Property test with 100 iterations as specified
	
	# Configure processor for deterministic mode
	processor.configure_deterministic_processing({
		"deterministic_mode": true,
		"sort_effects_by_id": true,
		"validate_deterministic_results": false
	})
	
	# Test multiple scenarios with different effect combinations
	for i in range(iterations):
		var scenario_passed = _test_deterministic_scenario(processor, i)
		if not scenario_passed:
			test_passed = false
			GLog.error("TestDeterministicProcessing: Scenario %d failed deterministic test" % i)
	
	# Test specific edge cases
	if not _test_empty_effects_determinism(processor):
		test_passed = false
	
	if not _test_single_effect_determinism(processor):
		test_passed = false
	
	if not _test_multiple_identical_effects_determinism(processor):
		test_passed = false
	
	if not _test_gambling_determinism(processor):
		test_passed = false
	
	processor.queue_free()
	
	if test_passed:
		GLog.info("TestDeterministicProcessing: Property test PASSED - All %d iterations produced deterministic results" % iterations)
	else:
		GLog.error("TestDeterministicProcessing: Property test FAILED - Non-deterministic behavior detected")
	
	return test_passed

func _test_deterministic_scenario(processor: EffectProcessor, scenario_index: int) -> bool:
	"""Test a single deterministic scenario with generated effects."""
	
	# Generate random effects for this scenario
	var effects = _generate_test_effects(scenario_index)
	var context = _create_test_context(scenario_index)
	
	if effects.is_empty():
		return true  # Empty effects should be deterministic
	
	# Run the same effects multiple times
	var first_results = processor.process_effects(effects, context)
	var second_results = processor.process_effects(effects, context)
	var third_results = processor.process_effects(effects, context)
	
	# Compare results for consistency
	var comparison1 = _compare_effect_results(first_results, second_results)
	var comparison2 = _compare_effect_results(first_results, third_results)
	
	if not comparison1.identical or not comparison2.identical:
		GLog.error("TestDeterministicProcessing: Non-deterministic results in scenario %d" % scenario_index)
		GLog.error("  First vs Second: %s" % ("identical" if comparison1.identical else "different"))
		GLog.error("  First vs Third: %s" % ("identical" if comparison2.identical else "different"))
		
		if not comparison1.identical:
			for diff in comparison1.differences:
				GLog.error("    Diff 1-2: %s" % diff)
		
		if not comparison2.identical:
			for diff in comparison2.differences:
				GLog.error("    Diff 1-3: %s" % diff)
		
		return false
	
	return true

func _test_empty_effects_determinism(processor: EffectProcessor) -> bool:
	"""Test that empty effect arrays are processed deterministically."""
	var empty_effects: Array[EffectHandler] = []
	var context = _create_test_context(0)
	
	var result1 = processor.process_effects(empty_effects, context)
	var result2 = processor.process_effects(empty_effects, context)
	
	var comparison = _compare_effect_results(result1, result2)
	
	if not comparison.identical:
		GLog.error("TestDeterministicProcessing: Empty effects not processed deterministically")
		return false
	
	return true

func _test_single_effect_determinism(processor: EffectProcessor) -> bool:
	"""Test that single effects are processed deterministically."""
	var effect = _create_damage_effect("test_single", 10)
	var effects: Array[EffectHandler] = [effect]
	var context = _create_test_context(1)
	
	var result1 = processor.process_effects(effects, context)
	var result2 = processor.process_effects(effects, context)
	
	var comparison = _compare_effect_results(result1, result2)
	
	if not comparison.identical:
		GLog.error("TestDeterministicProcessing: Single effect not processed deterministically")
		for diff in comparison.differences:
			GLog.error("  Diff: %s" % diff)
		return false
	
	return true

func _test_multiple_identical_effects_determinism(processor: EffectProcessor) -> bool:
	"""Test that multiple identical effects are processed deterministically."""
	var effect1 = _create_damage_effect("identical_1", 5)
	var effect2 = _create_damage_effect("identical_2", 5)
	var effect3 = _create_damage_effect("identical_3", 5)
	
	var effects: Array[EffectHandler] = [effect1, effect2, effect3]
	var context = _create_test_context(2)
	
	var result1 = processor.process_effects(effects, context)
	var result2 = processor.process_effects(effects, context)
	
	var comparison = _compare_effect_results(result1, result2)
	
	if not comparison.identical:
		GLog.error("TestDeterministicProcessing: Multiple identical effects not processed deterministically")
		for diff in comparison.differences:
			GLog.error("  Diff: %s" % diff)
		return false
	
	return true

func _test_gambling_determinism(processor: EffectProcessor) -> bool:
	"""Test that gambling effects are deterministic when using seeded RNG."""
	
	# Set a specific seed for deterministic gambling
	SeedManager.set_master_seed(12345)
	
	# Create a card instance that would trigger gambling
	var card_data = _create_test_card_data()
	var card_instance = _create_test_card_instance(card_data)
	var duel_manager = _create_test_duel_manager()
	
	# Process the same card multiple times
	var result1 = processor.apply_card_instance_effects(duel_manager, card_instance)
	
	# Reset to same seed to ensure deterministic behavior
	SeedManager.set_master_seed(12345)
	var result2 = processor.apply_card_instance_effects(duel_manager, card_instance)
	
	# Compare results
	var identical = _compare_legacy_results(result1, result2)
	
	if not identical:
		GLog.error("TestDeterministicProcessing: Gambling effects not deterministic")
		GLog.error("  Result 1: %s" % str(result1))
		GLog.error("  Result 2: %s" % str(result2))
		return false
	
	return true

func _generate_test_effects(seed: int) -> Array[EffectHandler]:
	"""Generate a random array of effects for testing."""
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	
	var effects: Array[EffectHandler] = []
	var effect_count = rng.randi_range(0, 5)  # 0-5 effects
	
	for i in range(effect_count):
		var effect_type = rng.randi_range(0, 2)
		match effect_type:
			0:
				effects.append(_create_damage_effect("gen_%d_%d" % [seed, i], rng.randi_range(1, 20)))
			1:
				effects.append(_create_heal_effect("gen_%d_%d" % [seed, i], rng.randi_range(1, 15)))
			2:
				effects.append(_create_resource_effect("gen_%d_%d" % [seed, i], rng.randi_range(1, 10)))
	
	return effects

func _create_test_context(seed: int) -> EffectContext:
	"""Create a test context for effect processing."""
	var context = EffectContext.new()
	context.source_type = "test"
	context.trigger_event = "test_trigger"
	context.trigger_data = {"seed": seed}
	
	# Create minimal test data
	context.player_data = _create_test_player_data()
	context.enemy_data = _create_test_enemy_data()
	context.primary_target = context.player_data
	
	return context

func _create_damage_effect(id: String, amount: int) -> EffectHandler:
	"""Create a test damage effect."""
	var effect = load("res://scripts/effects/types/damage_handler.gd").new()
	effect.effect_id = id
	effect.amount = amount
	effect.target_type = "enemy"
	return effect

func _create_heal_effect(id: String, amount: int) -> EffectHandler:
	"""Create a test heal effect."""
	var effect = load("res://scripts/effects/types/resource_handler.gd").new()
	effect.effect_id = id
	effect.resource_type = "health"
	effect.amount = amount
	effect.target_type = "player"
	return effect

func _create_resource_effect(id: String, amount: int) -> EffectHandler:
	"""Create a test resource effect."""
	var effect = load("res://scripts/effects/types/resource_handler.gd").new()
	effect.effect_id = id
	effect.resource_type = "energy"
	effect.amount = amount
	effect.target_type = "player"
	return effect

func _create_test_player_data() -> Resource:
	"""Create minimal test player data."""
	var player_data = load("res://scripts/data/player_data.gd").new()
	player_data.health = 100
	player_data.max_health = 100
	player_data.energy = 3
	player_data.max_energy = 3
	return player_data

func _create_test_enemy_data() -> Resource:
	"""Create minimal test enemy data."""
	var enemy_data = load("res://scripts/data/enemy_data.gd").new()
	enemy_data.health = 50
	enemy_data.max_health = 50
	return enemy_data

func _create_test_card_data() -> Resource:
	"""Create test card data for gambling tests."""
	var card_data = load("res://scripts/cards/card_data.gd").new()
	card_data.card_name = "Test Gambling Card"
	card_data.effects = [_create_damage_effect("gambling_test", 10)]
	return card_data

func _create_test_card_instance(card_data: Resource) -> Resource:
	"""Create test card instance."""
	var card_instance = load("res://scripts/cards/card_instance.gd").new()
	card_instance.card_data = card_data
	card_instance.owner = 0  # PLAYER
	return card_instance

func _create_test_duel_manager() -> Resource:
	"""Create minimal test duel manager."""
	var duel_manager = load("res://scripts/combat/main_game_controller.gd").new()
	
	# Create minimal duel state
	var duel_state = load("res://scripts/data/duel_state.gd").new()
	duel_state.player_data = _create_test_player_data()
	duel_state.enemy_data = _create_test_enemy_data()
	
	duel_manager.duel_state = duel_state
	return duel_manager

func _compare_effect_results(results1: Array[EffectResult], results2: Array[EffectResult]) -> Dictionary:
	"""Compare two arrays of EffectResult for identical content."""
	var comparison = {
		"identical": true,
		"differences": []
	}
	
	if results1.size() != results2.size():
		comparison.identical = false
		comparison.differences.append("Result count differs: %d vs %d" % [results1.size(), results2.size()])
		return comparison
	
	for i in range(results1.size()):
		var result1 = results1[i]
		var result2 = results2[i]
		
		if not result1 and not result2:
			continue
		
		if not result1 or not result2:
			comparison.identical = false
			comparison.differences.append("Result %d null mismatch: %s vs %s" % [i, str(result1), str(result2)])
			continue
		
		# Compare success
		if result1.success != result2.success:
			comparison.identical = false
			comparison.differences.append("Result %d success differs: %s vs %s" % [i, result1.success, result2.success])
		
		# Compare values_applied
		if not _compare_dictionaries(result1.values_applied, result2.values_applied):
			comparison.identical = false
			comparison.differences.append("Result %d values_applied differs: %s vs %s" % [i, str(result1.values_applied), str(result2.values_applied)])
		
		# Compare logs (sort for consistent comparison)
		var logs1 = result1.logs.duplicate() if result1.logs else []
		var logs2 = result2.logs.duplicate() if result2.logs else []
		logs1.sort()
		logs2.sort()
		
		if logs1 != logs2:
			comparison.identical = false
			comparison.differences.append("Result %d logs differ: %s vs %s" % [i, str(logs1), str(logs2)])
	
	return comparison

func _compare_legacy_results(result1: Dictionary, result2: Dictionary) -> bool:
	"""Compare two legacy result dictionaries for identical content."""
	if result1.size() != result2.size():
		return false
	
	for key in result1.keys():
		if not result2.has(key):
			return false
		if result1[key] != result2[key]:
			return false
	
	return true

func _compare_dictionaries(dict1: Dictionary, dict2: Dictionary) -> bool:
	"""Compare two dictionaries for identical content."""
	if not dict1 and not dict2:
		return true
	
	if not dict1 or not dict2:
		return false
	
	if dict1.size() != dict2.size():
		return false
	
	for key in dict1.keys():
		if not dict2.has(key):
			return false
		if dict1[key] != dict2[key]:
			return false
	
	return true