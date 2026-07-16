extends GdUnitTestSuite

func test_run_complete_intent_preserves_summary() -> void:
	var summary := {
		"character_class": "Bushranger",
		"seed": 12345,
		"fights_won": 3,
		"final_health": 22,
		"final_sanity": 8,
		"cards_added": ["Quick Shot"],
		"victory": true
	}
	var intent := RunCompleteIntent.from_summary(summary)
	assert_str(intent.character_class).is_equal("Bushranger")
	assert_int(intent.seed).is_equal(12345)
	assert_array(intent.cards_added).is_equal(["Quick Shot"])
	assert_bool(intent.victory).is_true()

func test_run_complete_intent_respects_defeat_summary() -> void:
	var intent := RunCompleteIntent.from_summary({"victory": false})
	assert_bool(intent.victory).is_false()

func test_run_complete_intent_defaults_to_victory_when_flag_missing() -> void:
	var intent := RunCompleteIntent.from_summary({})
	assert_bool(intent.victory).is_true()

func test_game_over_intent_identifies_sanity_defeat() -> void:
	var intent := GameOverIntent.new(RunSession.EndReason.SANITY)
	assert_int(intent.reason).is_equal(RunSession.EndReason.SANITY)
