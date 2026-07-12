extends GdUnitTestSuite

func test_definition_requires_exactly_three_valid_enemies() -> void:
	var definition := RunDefinition.new()
	definition.run_id = &"test_run"
	definition.display_name = "Test Run"
	definition.enemies = [
		load("res://data/enemies/claim_jumper.tres"),
		load("res://data/enemies/corrupt_sheriff.tres")
	]
	assert_bool(definition.is_valid()).is_false()
	assert_array(definition.get_validation_errors()).contains(["Run must contain exactly 3 enemies"])

func test_definition_rejects_enemy_without_deck() -> void:
	var definition := RunDefinition.new()
	definition.run_id = &"test_run"
	definition.display_name = "Test Run"
	definition.enemies = [
		load("res://data/enemies/claim_jumper.tres"),
		EnemyState.new(),
		load("res://data/enemies/whispering_cultist.tres")
	]
	assert_bool(definition.is_valid()).is_false()
	assert_array(definition.get_validation_errors()).contains(["Enemy 2 has no valid deck"])

func test_curated_definition_is_valid() -> void:
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	assert_object(definition).is_not_null()
	assert_bool(definition.is_valid()).is_true()
	assert_int(definition.recovery_health).is_equal(12)
	assert_int(definition.recovery_sanity).is_equal(4)
	assert_int(definition.card_offer_count).is_equal(3)
