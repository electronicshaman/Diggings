extends GdUnitTestSuite


class FakeDeckManager:
	extends RefCounted
	var cards: Array[CardData] = []
	var add_succeeds: bool = true

	func is_deck_available() -> bool:
		return not cards.is_empty()

	func get_current_deck() -> Array[CardData]:
		return cards.duplicate()

	func add_card(card: CardData) -> bool:
		if not add_succeeds:
			return false
		cards.append(card)
		return true


func _deck_manager() -> FakeDeckManager:
	var fake := FakeDeckManager.new()
	fake.cards = [load("res://data/cards/player/attack/tent_stake.tres")]
	return fake


func _session(run_seed: int = 12345, fake: FakeDeckManager = null) -> RunSession:
	if fake == null:
		fake = _deck_manager()
	var session := RunSession.new(fake, SeedManager)
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(session.begin(definition, character, run_seed)).is_true()
	return session


func _card_paths(cards: Array[CardData]) -> Array[String]:
	var paths: Array[String] = []
	for card in cards:
		paths.append(card.resource_path)
	return paths


func _recovery_offer_path(session: RunSession) -> Array[String]:
	var path: Array[String] = []
	for _fight in range(2):
		assert_object(session.prepare_current_duel()).is_not_null()
		assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
		path.append("|".join(_card_paths(session.get_pending_card_offers())))
		assert_bool(session.apply_recovery()).is_true()
	return path


func _assert_invalid_victory_preserves_snapshot(session: RunSession, player: PlayerData) -> void:
	var original_snapshot := session.player_snapshot
	assert_bool(session.record_victory(player)).is_false()
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(session.end_reason).is_equal(RunSession.EndReason.INVALID_STATE)
	assert_int(session.fights_won).is_equal(0)
	assert_int(session.fight_index).is_equal(0)
	assert_object(session.player_snapshot).is_same(original_snapshot)


func test_prepared_duel_contains_normalized_player_data() -> void:
	var session := _session()
	session.player_snapshot.health = 19
	session.player_snapshot.sanity = 7
	var config := session.prepare_current_duel()
	assert_bool(config.get_modifier("curated_run", false)).is_true()
	var player := config.get_modifier("player_data") as PlayerData
	assert_int(player.stats.current_health).is_equal(19)
	assert_int(player.stats.current_sanity).is_equal(7)
	assert_int(player.stats.current_energy).is_equal(player.stats.max_energy)


func test_begin_reseeds_loot_rng_for_deterministic_replay() -> void:
	const RUN_SEED := 8675309
	SeedManager.set_master_seed(RUN_SEED)
	var first_path := _recovery_offer_path(_session(RUN_SEED))

	SeedManager.set_master_seed(RUN_SEED)
	for _draw in range(37):
		SeedManager.loot_rng.randi()
	var replay_path := _recovery_offer_path(_session(RUN_SEED))

	assert_array(replay_path).is_equal(first_path)


func test_victory_rejects_missing_character_identity() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	var player := session.player_snapshot.to_player_data()
	player.set_character_class(null)
	_assert_invalid_victory_preserves_snapshot(session, player)


func test_victory_rejects_wrong_character_identity() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	var player := session.player_snapshot.to_player_data()
	player.set_character_class(load("res://data/characters/prospector.tres") as CharacterClass)
	_assert_invalid_victory_preserves_snapshot(session, player)


func test_victory_rejects_zero_health() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	var player := session.player_snapshot.to_player_data()
	player.stats.current_health = 0
	_assert_invalid_victory_preserves_snapshot(session, player)


func test_victory_rejects_zero_sanity() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	var player := session.player_snapshot.to_player_data()
	player.stats.current_sanity = 0
	_assert_invalid_victory_preserves_snapshot(session, player)


func test_victory_accepts_changed_maxima_and_class_resources() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	var player := session.player_snapshot.to_player_data()
	player.stats.max_health += 8
	player.stats.current_health += 4
	player.stats.max_sanity += 6
	player.stats.current_sanity += 3
	player.custom_resources = {GameEnums.CustomResourceType.AMMO: 4}
	player.custom_resource_max = {GameEnums.CustomResourceType.AMMO: 9}

	assert_bool(session.record_victory(player)).is_true()
	assert_int(session.player_snapshot.max_health).is_equal(player.stats.max_health)
	assert_int(session.player_snapshot.max_sanity).is_equal(player.stats.max_sanity)
	assert_int(session.player_snapshot.custom_resources[GameEnums.CustomResourceType.AMMO]).is_equal(4)
	assert_int(session.player_snapshot.custom_resource_max[GameEnums.CustomResourceType.AMMO]).is_equal(9)


func test_defeat_normalizes_none_reason_to_invalid_state() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	session.record_defeat(RunSession.EndReason.NONE)
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(session.end_reason).is_equal(RunSession.EndReason.INVALID_STATE)
	assert_int(session.get_summary().end_reason).is_equal(RunSession.EndReason.INVALID_STATE)


func test_invalid_begin_inputs_leave_session_inactive() -> void:
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	var invalid_definition := RunDefinition.new()
	var cases: Array[Array] = [
		[null, character, _deck_manager()],
		[invalid_definition, character, _deck_manager()],
		[definition, null, _deck_manager()],
		[definition, character, FakeDeckManager.new()],
	]

	for test_case in cases:
		var session := RunSession.new(test_case[2], SeedManager)
		assert_bool(session.begin(test_case[0], test_case[1], 4567)).is_false()
		assert_int(session.state).is_equal(RunSession.State.INACTIVE)
		assert_object(session.definition).is_null()
		assert_object(session.character).is_null()
		assert_object(session.player_snapshot).is_null()
		assert_int(session.seed).is_equal(0)
		assert_int(session.fight_index).is_equal(0)
		assert_int(session.fights_won).is_equal(0)
		assert_array(session.pending_card_offers).is_empty()
		assert_array(session.cards_added).is_empty()


func test_second_begin_does_not_replace_active_session() -> void:
	var session := _session(12345)
	var original_definition := session.definition
	var original_character := session.character
	var original_snapshot := session.player_snapshot
	assert_bool(session.begin(original_definition, original_character, 99999)).is_false()
	assert_int(session.state).is_equal(RunSession.State.FIGHT_READY)
	assert_int(session.seed).is_equal(12345)
	assert_object(session.definition).is_same(original_definition)
	assert_object(session.character).is_same(original_character)
	assert_object(session.player_snapshot).is_same(original_snapshot)


func test_duplicate_duel_preparation_and_victory_do_not_advance_twice() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	assert_object(session.prepare_current_duel()).is_null()
	var player := session.player_snapshot.to_player_data()
	assert_bool(session.record_victory(player)).is_true()
	var original_offers := _card_paths(session.get_pending_card_offers())
	assert_bool(session.record_victory(player)).is_false()
	assert_int(session.state).is_equal(RunSession.State.REWARD_PENDING)
	assert_int(session.fight_index).is_equal(0)
	assert_int(session.fights_won).is_equal(1)
	assert_array(_card_paths(session.get_pending_card_offers())).is_equal(original_offers)


func test_pending_offers_match_definition_and_are_unique_and_class_legal() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	var offers := session.get_pending_card_offers()
	var unique_paths := {}
	assert_int(offers.size()).is_equal(session.definition.card_offer_count)
	for card in offers:
		assert_bool(session.character.can_use_card(card)).is_true()
		unique_paths[card.resource_path] = true
	assert_int(unique_paths.size()).is_equal(offers.size())


func test_failed_card_add_leaves_pending_reward_unchanged() -> void:
	var fake := _deck_manager()
	fake.add_succeeds = false
	var session := _session(12345, fake)
	assert_object(session.prepare_current_duel()).is_not_null()
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	var original_offers := _card_paths(session.get_pending_card_offers())

	assert_bool(session.apply_card_reward(session.get_pending_card_offers()[0])).is_false()
	assert_int(session.state).is_equal(RunSession.State.REWARD_PENDING)
	assert_int(session.fight_index).is_equal(0)
	assert_array(session.cards_added).is_empty()
	assert_array(_card_paths(session.get_pending_card_offers())).is_equal(original_offers)


func test_terminal_defeat_cannot_be_rewritten() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	session.record_defeat(RunSession.EndReason.HEALTH)
	session.record_defeat(RunSession.EndReason.SANITY)
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(session.end_reason).is_equal(RunSession.EndReason.HEALTH)


func test_completed_summary_reports_victory_and_three_wins() -> void:
	var session := _session()
	for fight in range(3):
		assert_object(session.prepare_current_duel()).is_not_null()
		assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
		if fight < 2:
			assert_bool(session.apply_recovery()).is_true()
	var summary := session.get_summary()
	assert_bool(summary.victory).is_true()
	assert_int(summary.end_reason).is_equal(RunSession.EndReason.NONE)
	assert_int(summary.fights_won).is_equal(3)


func test_defeated_summary_reports_reason_and_wins_before_defeat() -> void:
	var session := _session()
	assert_object(session.prepare_current_duel()).is_not_null()
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	assert_bool(session.apply_recovery()).is_true()
	assert_object(session.prepare_current_duel()).is_not_null()
	session.record_defeat(RunSession.EndReason.SANITY)
	var summary := session.get_summary()
	assert_bool(summary.victory).is_false()
	assert_int(summary.end_reason).is_equal(RunSession.EndReason.SANITY)
	assert_int(summary.fights_won).is_equal(1)


func test_happy_path_advances_three_fights_and_two_choices() -> void:
	var session := _session()
	assert_int(session.state).is_equal(RunSession.State.FIGHT_READY)
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Claim Jumper")
	var player := session.player_snapshot.to_player_data()
	player.stats.current_health = 40
	assert_bool(session.record_victory(player)).is_true()
	assert_int(session.state).is_equal(RunSession.State.REWARD_PENDING)
	var offers := session.get_pending_card_offers()
	assert_bool(session.apply_card_reward(offers[0])).is_true()
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Corrupt Sheriff")
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	assert_bool(session.apply_recovery()).is_true()
	assert_str(session.prepare_current_duel().enemy_data.enemy_name).is_equal("Whispering Cultist")
	assert_bool(session.record_victory(session.player_snapshot.to_player_data())).is_true()
	assert_int(session.state).is_equal(RunSession.State.COMPLETED)
	assert_bool(session.is_complete()).is_true()


func test_reward_is_atomic_and_recovery_clamps() -> void:
	var session := _session()
	session.prepare_current_duel()
	var player := session.player_snapshot.to_player_data()
	player.stats.current_health = player.stats.max_health - 2
	player.stats.current_sanity = player.stats.max_sanity - 1
	session.record_victory(player)
	assert_bool(session.apply_recovery()).is_true()
	assert_bool(session.apply_recovery()).is_false()
	assert_int(session.player_snapshot.health).is_equal(session.player_snapshot.max_health)
	assert_int(session.player_snapshot.sanity).is_equal(session.player_snapshot.max_sanity)


func test_invalid_card_and_defeat_do_not_advance() -> void:
	var session := _session()
	session.prepare_current_duel()
	session.record_victory(session.player_snapshot.to_player_data())
	assert_bool(session.apply_card_reward(CardData.new())).is_false()
	session.record_defeat(RunSession.EndReason.SANITY)
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)


func test_malformed_player_snapshot_ends_run_safely() -> void:
	var session := _session()
	session.prepare_current_duel()
	assert_bool(session.record_victory(null)).is_false()
	assert_int(session.state).is_equal(RunSession.State.DEFEATED)
	assert_int(session.end_reason).is_equal(RunSession.EndReason.INVALID_STATE)
