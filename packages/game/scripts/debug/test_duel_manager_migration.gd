extends Node
class_name TestDuelManagerMigration

const DEBUG_ENABLED: bool = true

## Test to verify DuelManager migration to EffectProcessor works correctly
func run_migration_test() -> bool:
	GLog.info("TestDuelManagerMigration: Starting migration validation test")
	
	var duel_manager = DuelManager.new()
	var test_passed = true
	
	# Test 1: Verify DuelManager creates EffectProcessor instead of CardEffects
	if not _test_effect_processor_creation(duel_manager):
		test_passed = false
	
	# Test 2: Verify EffectProcessor has required legacy methods
	if not _test_legacy_compatibility_methods(duel_manager):
		test_passed = false
	
	# Test 3: Verify DuelManager can call EffectProcessor methods
	if not _test_method_calls(duel_manager):
		test_passed = false
	
	if test_passed:
		GLog.info("TestDuelManagerMigration: Migration test PASSED")
	else:
		GLog.error("TestDuelManagerMigration: Migration test FAILED")
	
	duel_manager.queue_free()
	return test_passed

func _test_effect_processor_creation(duel_manager: DuelManager) -> bool:
	GLog.debug("TestDuelManagerMigration: Testing EffectProcessor creation")
	
	# Trigger _ready() to initialize the processor
	duel_manager._ready()
	
	# Check that effect_processor exists and is valid
	if not duel_manager.has("effect_processor"):
		GLog.error("TestDuelManagerMigration: DuelManager missing effect_processor property")
		return false
	
	if not is_instance_valid(duel_manager.effect_processor):
		GLog.error("TestDuelManagerMigration: DuelManager effect_processor is invalid")
		return false
	
	if not duel_manager.effect_processor is EffectProcessor:
		GLog.error("TestDuelManagerMigration: effect_processor is not an EffectProcessor instance")
		return false
	
	GLog.debug("TestDuelManagerMigration: EffectProcessor creation test PASSED")
	return true

func _test_legacy_compatibility_methods(duel_manager: DuelManager) -> bool:
	GLog.debug("TestDuelManagerMigration: Testing legacy compatibility methods")
	
	var processor = duel_manager.effect_processor
	
	# Check that required legacy methods exist
	var required_methods = [
		"apply_card_instance_effects",
		"apply_card_instance_effects_with_context"
	]
	
	for method_name in required_methods:
		if not processor.has_method(method_name):
			GLog.error("TestDuelManagerMigration: EffectProcessor missing method: %s" % method_name)
			return false
	
	GLog.debug("TestDuelManagerMigration: Legacy compatibility methods test PASSED")
	return true

func _test_method_calls(duel_manager: DuelManager) -> bool:
	GLog.debug("TestDuelManagerMigration: Testing method calls")
	
	var processor = duel_manager.effect_processor
	
	# Test calling legacy compatibility methods with null inputs (should handle gracefully)
	var result1 = processor.apply_card_instance_effects(null, null)
	if not result1 is Dictionary:
		GLog.error("TestDuelManagerMigration: apply_card_instance_effects should return Dictionary")
		return false
	
	var result2 = processor.apply_card_instance_effects_with_context(null, null, 0, 0)
	if not result2 is Dictionary:
		GLog.error("TestDuelManagerMigration: apply_card_instance_effects_with_context should return Dictionary")
		return false
	
	# Both methods should return the same default structure for null inputs
	var expected_keys = ["damage", "defense", "heal", "draw", "energy_restore", "stun_enemy", "ignores_defense", "discard_random", "add_curse", "sanity_restore", "exhaust_random"]
	
	for key in expected_keys:
		if not result1.has(key):
			GLog.error("TestDuelManagerMigration: Result missing expected key: %s" % key)
			return false
		if not result2.has(key):
			GLog.error("TestDuelManagerMigration: Result missing expected key: %s" % key)
			return false
	
	GLog.debug("TestDuelManagerMigration: Method calls test PASSED")
	return true

## Run test when this script is executed directly
func _ready():
	if DEBUG_ENABLED:
		# Add a small delay to ensure autoloads are ready
		await get_tree().create_timer(0.1).timeout
		run_migration_test()