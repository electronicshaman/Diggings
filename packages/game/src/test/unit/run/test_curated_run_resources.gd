extends GdUnitTestSuite

const CLASS_PATHS: Array[String] = [
	"res://data/characters/bushranger.tres",
	"res://data/characters/prospector.tres",
	"res://data/characters/tracker.tres",
	"res://data/characters/publican.tres",
	"res://data/characters/preacher.tres"
]


func after_test() -> void:
	CurioManager.clear_curios()
	CurioManager.reset_run_curios()
	GameManager.reset_curated_run()
	SeedManager.end_run()
	GameManager.initialize_game_data()


func test_all_classes_have_valid_starting_decks() -> void:
	for path in CLASS_PATHS:
		var character := load(path) as CharacterClass
		assert_object(character).is_not_null()
		assert_bool(not character.starting_deck_resource.is_empty()).is_true()
		assert_bool(ResourceLoader.exists(character.starting_deck_resource)).is_true()
		assert_bool(not character.load_starting_deck().is_empty()).is_true()


func test_game_manager_can_begin_curated_run_for_each_class() -> void:
	for path in CLASS_PATHS:
		GameManager.reset_curated_run()
		var character := load(path) as CharacterClass
		assert_bool(GameManager.begin_curated_run(character, 777)).is_true()
		assert_bool(GameManager.has_active_run()).is_true()
		assert_bool(GameManager.is_duel_prepared()).is_true()
	GameManager.reset_curated_run()


func test_reset_curated_run_clears_curios_stacks_and_offer_history() -> void:
	var curio := load("res://data/curios/common/worn_bible.tres") as CurioData
	assert_bool(CurioManager.add_curio(curio)).is_true()
	assert_bool(CurioManager.add_curio(curio)).is_true()
	assert_int(CurioManager.get_active_curios().size()).is_equal(1)
	assert_int(CurioManager.get_curio_stack_count(curio.curio_name)).is_equal(2)
	assert_bool(curio.curio_name in CurioManager.curios_offered_this_run).is_true()

	GameManager.reset_curated_run()

	assert_array(CurioManager.get_active_curios()).is_empty()
	assert_int(CurioManager.get_curio_stack_count(curio.curio_name)).is_equal(0)
	assert_array(CurioManager.curios_offered_this_run).is_empty()


func test_failed_start_new_run_ends_seed_lifecycle_and_clears_run_state() -> void:
	var invalid_character := CharacterClass.new()
	invalid_character.character_class_name = "Missing Deck Class"
	invalid_character.starting_deck_resource = "res://missing/deck.tres"

	assert_bool(GameManager.start_new_run(invalid_character, "A1B2C3D4E5")).is_false()

	assert_bool(GameManager.has_active_run()).is_false()
	assert_object(GameManager.run_session).is_null()
	assert_object(GameManager.pending_duel_config).is_null()
	assert_bool(DeckManager.is_deck_available()).is_false()
	assert_bool(SeedManager.is_run_active()).is_false()


func test_direct_begin_curated_run_marks_seed_lifecycle_active() -> void:
	var character := load(CLASS_PATHS[0]) as CharacterClass
	SeedManager.set_master_seed(24680)
	SeedManager.end_run()

	assert_bool(GameManager.begin_curated_run(character, 24680)).is_true()
	assert_bool(SeedManager.is_run_active()).is_true()


func test_curated_run_preserves_user_hash_and_resets_subsystem_streams() -> void:
	const USER_HASH := "A1B2C3D4E5"
	SeedManager.set_master_seed(USER_HASH)
	var derived_seed := SeedManager.get_master_seed()
	var expected_first_draws: Dictionary = {}
	for stream_name in ["map", "combat", "loot", "character", "event"]:
		var expected_rng := RandomNumberGenerator.new()
		expected_rng.seed = SeedManager.generate_subseed(stream_name)
		expected_first_draws[stream_name] = expected_rng.randi()
	for _draw in range(17):
		SeedManager.map_rng.randi()
		SeedManager.combat_rng.randi()
		SeedManager.loot_rng.randi()
		SeedManager.character_rng.randi()
		SeedManager.event_rng.randi()

	var character := load(CLASS_PATHS[0]) as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, derived_seed)).is_true()

	assert_str(SeedManager.get_hash_seed_string()).is_equal(USER_HASH)
	assert_str(GameManager.current_run_hash_seed).is_equal(USER_HASH)
	assert_int(SeedManager.map_rng.randi()).is_equal(expected_first_draws["map"])
	assert_int(SeedManager.combat_rng.randi()).is_equal(expected_first_draws["combat"])
	assert_int(SeedManager.loot_rng.randi()).is_equal(expected_first_draws["loot"])
	assert_int(SeedManager.character_rng.randi()).is_equal(expected_first_draws["character"])
	assert_int(SeedManager.event_rng.randi()).is_equal(expected_first_draws["event"])


func test_reset_curated_run_clears_stale_player_reference() -> void:
	GameManager.initialize_game_data()
	GameManager.game_data["player"] = PlayerData.new()

	GameManager.reset_curated_run()

	assert_object(GameManager.game_data.get("player")).is_null()


func test_add_corruption_synchronizes_registered_player() -> void:
	GameManager.initialize_game_data()
	var player := PlayerData.new()
	GameManager.game_data["player"] = player

	GameManager.add_corruption(7)
	assert_int(GameManager.game_data["corruption"]).is_equal(7)
	assert_int(player.run_corruption).is_equal(7)

	GameManager.add_corruption(-20)
	assert_int(GameManager.game_data["corruption"]).is_equal(0)
	assert_int(player.run_corruption).is_equal(0)
