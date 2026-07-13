extends GdUnitTestSuite

const DuelSceneControllerScript := preload("res://scripts/combat/duel_scene_controller.gd")


class StartDuelProxy:
	extends Node
	var duel_manager: DuelManager

	func _init(manager: DuelManager) -> void:
		duel_manager = manager

	func start_duel(player_deck: DeckData, enemy: Resource) -> Error:
		duel_manager.start_new_duel(player_deck, enemy)
		return OK


func _manager() -> DuelManager:
	var manager := auto_free(DuelManager.new()) as DuelManager
	manager.duel_state = DuelState.new()
	manager._ready()
	return manager


func after_test() -> void:
	SceneManager.is_transitioning = false
	GameManager.reset_curated_run()
	GameManager.initialize_game_data()


func test_configured_player_is_installed_before_duel_start_side_effects() -> void:
	var preacher := load("res://data/characters/preacher.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(preacher, 7070)).is_true()
	var configured_player := (
		GameManager.pending_duel_config.get_modifier("player_data") as PlayerData
	)
	configured_player.cards_played_this_turn = 9
	configured_player.stats.current_energy = 1
	configured_player.corruption_triggered_tiers = {Stats.SanityTier.SHAKEN: true}
	var manager := _manager()
	var players_at_start: Array[PlayerData] = []
	manager.duel_started.connect(func() -> void:
		players_at_start.append(manager.duel_state.player_data)
	)
	var state_manager := auto_free(StartDuelProxy.new(manager)) as StartDuelProxy
	var controller := auto_free(DuelSceneControllerScript.new()) as Node2D
	controller.duel_manager = manager
	controller.duel_state_manager = state_manager

	controller._initialize_duel()

	assert_object(manager.duel_state.player_data).is_same(configured_player)
	assert_object(GameManager.game_data["player"]).is_same(configured_player)
	assert_array(players_at_start).has_size(1)
	assert_object(players_at_start[0]).is_same(configured_player)
	assert_int(configured_player.cards_played_this_turn).is_equal(0)
	assert_int(configured_player.stats.current_energy).is_equal(
		configured_player.stats.max_energy
	)
	assert_bool(
		manager.sanity_tracker.has_triggered_corruption(Stats.SanityTier.SHAKEN)
	).is_true()
	assert_int(manager.passive_handler._connected_signals.size()).is_equal(3)
	manager.passive_handler.cleanup()
