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
	assert_str(definition.enemies[0].resource_path).is_equal("res://data/enemies/claim_jumper.tres")
	assert_str(definition.enemies[1].resource_path).is_equal("res://data/enemies/corrupt_sheriff.tres")
	assert_str(definition.enemies[2].resource_path).is_equal("res://data/enemies/whispering_cultist.tres")

	var claim_jumper := definition.enemies[0] as EnemyState
	var corrupt_sheriff := definition.enemies[1] as EnemyState
	var whispering_cultist := definition.enemies[2] as EnemyState
	assert_int(claim_jumper.stats.current_health).is_equal(24)
	assert_int(claim_jumper.stats.max_health).is_equal(24)
	assert_int(corrupt_sheriff.stats.current_health).is_equal(32)
	assert_int(corrupt_sheriff.stats.max_health).is_equal(32)
	assert_int(whispering_cultist.stats.current_health).is_equal(40)
	assert_int(whispering_cultist.stats.max_health).is_equal(40)

	assert_int(definition.recovery_health).is_equal(12)
	assert_int(definition.recovery_sanity).is_equal(4)
	assert_int(definition.card_offer_count).is_equal(3)
