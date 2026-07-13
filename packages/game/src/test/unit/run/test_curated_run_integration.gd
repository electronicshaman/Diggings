extends GdUnitTestSuite


func after_test() -> void:
	SceneManager.is_transitioning = false
	GameManager.reset_curated_run()
	GameManager.last_run_summary = {}
	GameManager.initialize_game_data()


func _prepare_pending_reward() -> Array[CardData]:
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 7070)).is_true()
	var player := GameManager.pending_duel_config.get_modifier("player_data") as PlayerData
	player.stats.current_health -= 20
	player.stats.current_sanity -= 10
	assert_bool(GameManager.run_session.record_victory(player)).is_true()
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.REWARD_PENDING)
	SceneManager.is_transitioning = true
	return GameManager.get_pending_run_rewards()


func _instantiate_between_fight_scene() -> Control:
	var packed := load("res://scenes/ui/between_fight_choice.tscn") as PackedScene
	assert_object(packed).is_not_null()
	if packed == null:
		return null
	var scene := auto_free(packed.instantiate()) as Control
	add_child(scene)
	return scene


func test_between_fight_scene_has_required_controls() -> void:
	var packed := load("res://scenes/ui/between_fight_choice.tscn") as PackedScene
	assert_object(packed).is_not_null()
	if packed == null:
		return
	var scene: Node = auto_free(packed.instantiate())
	assert_object(scene.get_node("Margin/VBox/RunStatus")).is_not_null()
	assert_object(scene.get_node("Margin/VBox/CardOffers")).is_not_null()
	assert_object(scene.get_node("Margin/VBox/RecoverButton")).is_not_null()


func test_scene_manager_registers_between_fight_choice() -> void:
	assert_str(str(SceneManager.SCENE_PATHS.get("between_fight_choice", ""))).is_equal(
		"res://scenes/ui/between_fight_choice.tscn"
	)


func test_manager_reports_pending_progress_and_applies_exact_recovery() -> void:
	var offers := _prepare_pending_reward()
	assert_int(offers.size()).is_equal(3)
	assert_bool(GameManager.has_method("has_pending_run_reward")).is_true()
	assert_bool(GameManager.has_method("get_run_progress_text")).is_true()
	if not GameManager.has_method("has_pending_run_reward"):
		return
	if not GameManager.has_method("get_run_progress_text"):
		return
	assert_bool(bool(GameManager.call("has_pending_run_reward"))).is_true()
	assert_str(str(GameManager.call("get_run_progress_text"))).is_equal("Fight 1 of 3 complete")
	var original_health: int = GameManager.run_session.player_snapshot.health
	var original_sanity: int = GameManager.run_session.player_snapshot.sanity

	assert_bool(GameManager.choose_run_recovery()).is_true()

	assert_int(GameManager.run_session.player_snapshot.health).is_equal(original_health + 12)
	assert_int(GameManager.run_session.player_snapshot.sanity).is_equal(original_sanity + 4)
	assert_int(GameManager.run_session.fight_index).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.IN_DUEL)
	assert_bool(bool(GameManager.call("has_pending_run_reward"))).is_false()
	assert_str(GameManager.pending_duel_config.enemy_data.enemy_name).is_equal("Corrupt Sheriff")


func test_scene_shows_exact_prepared_offers_and_recovery_copy() -> void:
	var offers := _prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button
	assert_int(card_offers.get_child_count()).is_equal(offers.size())
	for index in offers.size():
		var button := card_offers.get_child(index) as Button
		assert_str(button.text).is_equal("%s\n%s" % [offers[index].card_name, offers[index].description])
	assert_str(recover_button.text).is_equal("Recover 12 Health and 4 Sanity")


func test_rejected_card_restores_all_choices() -> void:
	_prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button

	scene.call("_on_card_selected", CardData.new())

	assert_bool(bool(scene.get("choice_submitted"))).is_false()
	assert_bool(recover_button.disabled).is_false()
	for child in card_offers.get_children():
		assert_bool((child as Button).disabled).is_false()
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.REWARD_PENDING)


func test_duplicate_card_signal_applies_only_one_choice() -> void:
	var offers := _prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var button := card_offers.get_child(0) as Button
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button

	button.pressed.emit()
	button.pressed.emit()

	assert_bool(bool(scene.get("choice_submitted"))).is_true()
	assert_bool(recover_button.disabled).is_true()
	for child in card_offers.get_children():
		assert_bool((child as Button).disabled).is_true()
	assert_array(GameManager.run_session.cards_added).is_equal([offers[0].card_name])
	assert_int(GameManager.run_session.fight_index).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.IN_DUEL)


func test_post_application_transition_failure_stays_locked() -> void:
	_prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button
	DeckManager.current_run_deck.cards[0] = null

	recover_button.pressed.emit()

	assert_bool(bool(scene.get("choice_submitted"))).is_true()
	assert_bool(recover_button.disabled).is_true()
	for child in card_offers.get_children():
		assert_bool((child as Button).disabled).is_true()
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(GameManager.run_session.fight_index).is_equal(1)
