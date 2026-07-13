extends GdUnitTestSuite


class FakeDeckManager:
	extends RefCounted
	var cards: Array[CardData] = []

	func is_deck_available() -> bool:
		return not cards.is_empty()

	func get_current_deck() -> Array[CardData]:
		return cards.duplicate()

	func add_card(card: CardData) -> bool:
		cards.append(card)
		return true


func _session() -> RunSession:
	var fake := FakeDeckManager.new()
	fake.cards = [load("res://data/cards/player/attack/tent_stake.tres")]
	var seed_manager := SeedManager
	seed_manager.set_master_seed(12345)
	var session := RunSession.new(fake, seed_manager)
	var definition := load("res://data/runs/the_diggings_short_run.tres") as RunDefinition
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	assert_bool(session.begin(definition, character, 12345)).is_true()
	return session


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
