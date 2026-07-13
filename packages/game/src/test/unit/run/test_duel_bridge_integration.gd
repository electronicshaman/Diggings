extends GdUnitTestSuite

func _manager() -> DuelManager:
	var manager := auto_free(DuelManager.new()) as DuelManager
	manager.duel_state = DuelState.new()
	manager._ready()
	return manager


func after_test() -> void:
	SceneManager.is_transitioning = false
	GameManager.reset_curated_run()
	GameManager.initialize_game_data()


func test_duplicate_curated_completion_closes_and_hands_off_once() -> void:
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 6060)).is_true()
	GameManager.last_run_summary = {}
	var player := GameManager.pending_duel_config.get_modifier("player_data") as PlayerData
	var manager := _manager()
	manager.duel_state.player_data = player
	manager.duel_state.start_duel()
	var signal_count := [0]
	var active_at_signal: Array[bool] = []
	manager.duel_ended.connect(func(_winner: String) -> void:
		signal_count[0] += 1
		active_at_signal.append(manager.duel_state.duel_active)
	)
	SceneManager.is_transitioning = true

	manager.end_duel("player")
	manager.end_duel("player")

	assert_bool(manager.duel_state.duel_active).is_false()
	assert_bool(manager.duel_state.winner == "player").is_true()
	assert_int(signal_count[0]).is_equal(1)
	assert_array(active_at_signal).is_equal([false])
	assert_int(GameManager.run_session.fights_won).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.REWARD_PENDING)
	assert_int(GameManager.run_session.end_reason).is_equal(RunSession.EndReason.NONE)
	assert_bool(GameManager.is_run_active).is_true()
	assert_dict(GameManager.last_run_summary).is_empty()
	manager.passive_handler.cleanup()
