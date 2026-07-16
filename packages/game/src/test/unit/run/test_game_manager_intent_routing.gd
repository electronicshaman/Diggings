extends GdUnitTestSuite

## Regression coverage for GameManager's curated-duel intent routing:
## defeat reasons must arrive at game_over as GameOverIntent and the final
## victory must arrive at run_complete as RunCompleteIntent (deferred from
## the Task 8 review).


func after_test() -> void:
	SceneManager.is_transitioning = false
	SceneManager.get_pending_intent()
	GameManager.reset_curated_run()
	GameManager.last_run_summary = {}
	GameManager.initialize_game_data()


## Starts a run, then blocks real scene loads: with is_transitioning held
## true, SceneManager still stores the pending intent but load_scene is a
## no-op, so routing is observable without scene changes or tweens.
func _begin_run_with_blocked_transitions() -> PlayerData:
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 8080)).is_true()
	SceneManager.is_transitioning = true
	return GameManager.pending_duel_config.get_modifier("player_data") as PlayerData


func test_health_defeat_routes_game_over_intent_with_health_reason() -> void:
	var player := _begin_run_with_blocked_transitions()
	player.stats.current_health = 0

	GameManager.complete_curated_duel(player, "enemy")

	var intent := SceneManager.get_pending_intent() as GameOverIntent
	assert_object(intent).is_not_null()
	if intent == null:
		return
	assert_int(intent.reason).is_equal(RunSession.EndReason.HEALTH)
	assert_bool(GameManager.has_active_run()).is_false()
	assert_bool(bool(GameManager.get_last_run_summary().get("victory", true))).is_false()


func test_sanity_defeat_routes_game_over_intent_with_sanity_reason() -> void:
	var player := _begin_run_with_blocked_transitions()
	player.stats.current_health = 0
	player.stats.current_sanity = 0

	GameManager.complete_curated_duel(player, "enemy")

	var intent := SceneManager.get_pending_intent() as GameOverIntent
	assert_object(intent).is_not_null()
	if intent == null:
		return
	assert_int(intent.reason).is_equal(RunSession.EndReason.SANITY)


func test_final_victory_routes_run_complete_intent() -> void:
	_begin_run_with_blocked_transitions()

	assert_bool(
		GameManager.run_session.record_victory(
			GameManager.run_session.player_snapshot.to_player_data()
		)
	).is_true()
	assert_bool(GameManager.run_session.apply_recovery()).is_true()
	GameManager.run_session.prepare_current_duel()
	assert_bool(
		GameManager.run_session.record_victory(
			GameManager.run_session.player_snapshot.to_player_data()
		)
	).is_true()
	assert_bool(GameManager.run_session.apply_recovery()).is_true()
	GameManager.pending_duel_config = GameManager.run_session.prepare_current_duel()

	GameManager.complete_curated_duel(
		GameManager.run_session.player_snapshot.to_player_data(), "player"
	)

	var intent := SceneManager.get_pending_intent() as RunCompleteIntent
	assert_object(intent).is_not_null()
	if intent == null:
		return
	assert_bool(intent.victory).is_true()
	assert_int(intent.battles_won).is_equal(3)
	assert_bool(GameManager.has_active_run()).is_false()
