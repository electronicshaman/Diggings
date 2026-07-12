extends GdUnitTestSuite

func test_snapshot_persists_run_state_and_resets_combat_state() -> void:
	var player := PlayerData.new()
	player.stats.max_health = 50
	player.stats.current_health = 31
	player.stats.max_sanity = 20
	player.stats.current_sanity = 9
	player.stats.max_energy = 4
	player.stats.current_energy = 1
	player.stats.defense = 17
	player.stats.current_gold = 23
	player.custom_resources = {GameEnums.CustomResourceType.BREW: 3}
	player.custom_resource_max = {GameEnums.CustomResourceType.BREW: 8}
	player.run_corruption = 6
	player.corruption_triggered_tiers = {Stats.SanityTier.SHAKEN: true}
	player.next_card_free = true
	player.attack_cost_reduction = 2

	var restored := RunPlayerSnapshot.capture(player).to_player_data()
	assert_int(restored.stats.current_health).is_equal(31)
	assert_int(restored.stats.current_sanity).is_equal(9)
	assert_int(restored.stats.current_energy).is_equal(4)
	assert_int(restored.stats.defense).is_equal(0)
	assert_int(restored.stats.current_gold).is_equal(23)
	assert_int(restored.custom_resources[GameEnums.CustomResourceType.BREW]).is_equal(3)
	assert_int(restored.run_corruption).is_equal(6)
	assert_bool(restored.corruption_triggered_tiers[Stats.SanityTier.SHAKEN]).is_true()
	assert_bool(restored.next_card_free).is_false()
	assert_int(restored.attack_cost_reduction).is_equal(0)

func test_stats_save_round_trip_includes_gold() -> void:
	var stats := Stats.new()
	stats.current_gold = 41
	var restored := Stats.new()
	restored.load_from_data(stats.get_save_data())
	assert_int(restored.current_gold).is_equal(41)
