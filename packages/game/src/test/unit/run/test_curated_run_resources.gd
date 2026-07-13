extends GdUnitTestSuite

const CLASS_PATHS: Array[String] = [
	"res://data/characters/bushranger.tres",
	"res://data/characters/prospector.tres",
	"res://data/characters/tracker.tres",
	"res://data/characters/publican.tres",
	"res://data/characters/preacher.tres"
]


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
