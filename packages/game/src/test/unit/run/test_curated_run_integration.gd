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


func _complete_incoming_between_fight_transition() -> void:
	SceneManager.is_transitioning = false
	EventBus.scene_transition_completed.emit(SceneManager.SCENE_PATHS["between_fight_choice"])


func _cancel_new_scene_transition_tweens(existing_tweens: Array[Tween]) -> void:
	for tween in get_tree().get_processed_tweens():
		if not existing_tweens.has(tween):
			tween.kill()
	SceneManager.is_transitioning = false


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
	SceneManager.is_transitioning = false
	var existing_tweens := get_tree().get_processed_tweens()

	assert_bool(GameManager.choose_run_recovery()).is_true()

	assert_int(GameManager.run_session.player_snapshot.health).is_equal(original_health + 12)
	assert_int(GameManager.run_session.player_snapshot.sanity).is_equal(original_sanity + 4)
	assert_int(GameManager.run_session.fight_index).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.IN_DUEL)
	assert_bool(bool(GameManager.call("has_pending_run_reward"))).is_false()
	assert_str(GameManager.pending_duel_config.enemy_data.enemy_name).is_equal("Corrupt Sheriff")
	_cancel_new_scene_transition_tweens(existing_tweens)


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
	_complete_incoming_between_fight_transition()

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
	_complete_incoming_between_fight_transition()
	var existing_tweens := get_tree().get_processed_tweens()

	button.pressed.emit()
	button.pressed.emit()

	assert_bool(bool(scene.get("choice_submitted"))).is_true()
	assert_bool(recover_button.disabled).is_true()
	for child in card_offers.get_children():
		assert_bool((child as Button).disabled).is_true()
	assert_array(GameManager.run_session.cards_added).is_equal([offers[0].card_name])
	assert_int(GameManager.run_session.fight_index).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.IN_DUEL)
	_cancel_new_scene_transition_tweens(existing_tweens)


func test_post_application_transition_failure_stays_locked() -> void:
	_prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button
	_complete_incoming_between_fight_transition()
	DeckManager.current_run_deck.cards[0] = null

	recover_button.pressed.emit()

	assert_bool(bool(scene.get("choice_submitted"))).is_true()
	assert_bool(recover_button.disabled).is_true()
	for child in card_offers.get_children():
		assert_bool((child as Button).disabled).is_true()
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(GameManager.run_session.fight_index).is_equal(1)


func test_manager_rejects_card_while_scene_transition_is_busy_without_mutating_reward() -> void:
	var offers := _prepare_pending_reward()
	var original_offer_paths: Array[String] = []
	for card in offers:
		original_offer_paths.append(card.resource_path)

	assert_bool(GameManager.choose_run_card(offers[0])).is_false()

	assert_int(GameManager.run_session.state).is_equal(RunSession.State.REWARD_PENDING)
	assert_int(GameManager.run_session.fight_index).is_equal(0)
	assert_array(GameManager.run_session.cards_added).is_empty()
	var remaining_offer_paths: Array[String] = []
	for card in GameManager.get_pending_run_rewards():
		remaining_offer_paths.append(card.resource_path)
	assert_array(remaining_offer_paths).is_equal(original_offer_paths)


func test_choice_waits_for_matching_transition_and_routes_to_duel_once() -> void:
	var offers := _prepare_pending_reward()
	var scene := _instantiate_between_fight_scene()
	if scene == null:
		return
	var card_offers := scene.get_node("Margin/VBox/CardOffers") as HBoxContainer
	var button := card_offers.get_child(0) as Button
	var recover_button := scene.get_node("Margin/VBox/RecoverButton") as Button

	assert_bool(button.disabled).is_true()
	assert_bool(recover_button.disabled).is_true()
	button.pressed.emit()
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.REWARD_PENDING)
	assert_int(GameManager.run_session.fight_index).is_equal(0)
	assert_array(GameManager.run_session.cards_added).is_empty()
	if GameManager.run_session.state != RunSession.State.REWARD_PENDING:
		return

	EventBus.scene_transition_completed.emit(SceneManager.SCENE_PATHS["main_menu"])
	assert_bool(button.disabled).is_true()
	assert_bool(recover_button.disabled).is_true()
	_complete_incoming_between_fight_transition()
	assert_bool(button.disabled).is_false()
	assert_bool(recover_button.disabled).is_false()

	var existing_tweens := get_tree().get_processed_tweens()
	button.pressed.emit()
	button.pressed.emit()

	assert_array(GameManager.run_session.cards_added).is_equal([offers[0].card_name])
	assert_int(GameManager.run_session.fight_index).is_equal(1)
	assert_int(GameManager.run_session.state).is_equal(RunSession.State.IN_DUEL)
	assert_bool(SceneManager.is_transitioning).is_true()
	var route_tweens: Array[Tween] = []
	for tween in get_tree().get_processed_tweens():
		if not existing_tweens.has(tween):
			route_tweens.append(tween)
	assert_int(route_tweens.size()).is_equal(1)
	_cancel_new_scene_transition_tweens(existing_tweens)


func test_complete_run_persists_choices_and_builds_summary() -> void:
	GameManager.reset_curated_run()
	SeedManager.set_master_seed(515151)
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, 515151)).is_true()
	var first_player := GameManager.run_session.player_snapshot.to_player_data()
	first_player.stats.current_health = 38
	first_player.stats.current_sanity = 14
	first_player.stats.current_gold = 19
	first_player.custom_resources[GameEnums.CustomResourceType.AMMO] = 2
	first_player.run_corruption = 4
	first_player.corruption_triggered_tiers = {Stats.SanityTier.SHAKEN: true}
	var curio := load("res://data/curios/common/lucky_nugget.tres")
	assert_bool(CurioManager.add_curio(curio)).is_true()
	GameManager.run_session.record_victory(first_player)
	var offered := GameManager.get_pending_run_rewards()
	assert_bool(GameManager.run_session.apply_card_reward(offered[0])).is_true()
	var second_config := GameManager.run_session.prepare_current_duel()
	var persisted := second_config.get_modifier("player_data") as PlayerData
	assert_int(persisted.stats.current_health).is_equal(38)
	assert_int(persisted.stats.current_sanity).is_equal(14)
	assert_int(persisted.stats.current_gold).is_equal(19)
	assert_int(persisted.custom_resources[GameEnums.CustomResourceType.AMMO]).is_equal(2)
	assert_int(persisted.run_corruption).is_equal(4)
	assert_bool(persisted.corruption_triggered_tiers[Stats.SanityTier.SHAKEN]).is_true()
	assert_bool(CurioManager.has_curio(curio.curio_name)).is_true()
	var second_player := GameManager.run_session.player_snapshot.to_player_data()
	second_player.stats.current_health = 30
	second_player.stats.current_sanity = 10
	GameManager.run_session.record_victory(second_player)
	assert_bool(GameManager.run_session.apply_recovery()).is_true()
	GameManager.run_session.prepare_current_duel()
	GameManager.run_session.record_victory(GameManager.run_session.player_snapshot.to_player_data())
	var summary := GameManager.run_session.get_summary()
	assert_bool(summary.victory).is_true()
	assert_int(summary.fights_won).is_equal(3)
	assert_int(summary.cards_added.size()).is_equal(1)
	GameManager.reset_curated_run()


func _card_reward_paths(cards: Array[CardData]) -> Array[String]:
	var paths: Array[String] = []
	for card in cards:
		paths.append(card.resource_path)
	return paths


func _play_curated_run_and_capture(run_seed: int) -> Dictionary:
	GameManager.reset_curated_run()
	SeedManager.set_master_seed(run_seed)
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(GameManager.begin_curated_run(character, run_seed)).is_true()
	var enemy_names: Array[String] = []
	var offer_paths: Array[String] = []

	enemy_names.append(GameManager.pending_duel_config.enemy_data.enemy_name)
	assert_bool(
		GameManager.run_session.record_victory(GameManager.run_session.player_snapshot.to_player_data())
	).is_true()
	var first_offers := GameManager.get_pending_run_rewards()
	offer_paths.append("|".join(_card_reward_paths(first_offers)))
	assert_bool(GameManager.run_session.apply_card_reward(first_offers[0])).is_true()

	var second_config := GameManager.run_session.prepare_current_duel()
	enemy_names.append(second_config.enemy_data.enemy_name)
	assert_bool(
		GameManager.run_session.record_victory(GameManager.run_session.player_snapshot.to_player_data())
	).is_true()
	var second_offers := GameManager.get_pending_run_rewards()
	offer_paths.append("|".join(_card_reward_paths(second_offers)))
	assert_bool(GameManager.run_session.apply_recovery()).is_true()

	var third_config := GameManager.run_session.prepare_current_duel()
	enemy_names.append(third_config.enemy_data.enemy_name)
	assert_bool(
		GameManager.run_session.record_victory(GameManager.run_session.player_snapshot.to_player_data())
	).is_true()
	assert_bool(GameManager.run_session.is_complete()).is_true()

	GameManager.reset_curated_run()
	return {"enemy_names": enemy_names, "offer_paths": offer_paths}


func test_same_seed_same_decisions_produce_identical_offers_and_enemies() -> void:
	const RUN_SEED := 424242
	var first_run := _play_curated_run_and_capture(RUN_SEED)
	var second_run := _play_curated_run_and_capture(RUN_SEED)
	assert_int(second_run["enemy_names"].size()).is_equal(3)
	assert_array(second_run["enemy_names"]).is_equal(first_run["enemy_names"])
	assert_array(second_run["offer_paths"]).is_equal(first_run["offer_paths"])
