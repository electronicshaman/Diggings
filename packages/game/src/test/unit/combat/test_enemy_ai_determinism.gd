extends GdUnitTestSuite

## Determinism coverage for the cunning AI's random fallback (deferred from
## the Task 9 review): with no player-pattern match, selection must come from
## the injected RNG so identical seeds reproduce identical picks.


func _controller_with_seed(seed_value: int) -> EnemyAIController:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return EnemyAIController.new(DuelState.new(), rng)


func _card(name: String) -> CardData:
	var card := CardData.new()
	card.card_name = name
	card.card_type = "Power"
	return card


func _pick_sequence(controller: EnemyAIController, enemy: EnemyState, cards: Array[CardData]) -> Array[String]:
	var picks: Array[String] = []
	for i in 12:
		picks.append(controller.select_card(enemy, cards).card_name)
	return picks


func test_cunning_fallback_reproduces_picks_for_identical_seeds() -> void:
	var enemy := auto_free(EnemyState.new()) as EnemyState
	enemy.ai_type = GameEnums.AIType.CUNNING
	var cards: Array[CardData] = [
		_card("Dust Devil"), _card("Fools Gold"), _card("Deep Shaft"), _card("Black Damp")
	]

	var first := _pick_sequence(_controller_with_seed(4242), enemy, cards)
	var second := _pick_sequence(_controller_with_seed(4242), enemy, cards)

	assert_array(second).is_equal(first)


func test_cunning_fallback_diverges_for_different_seeds() -> void:
	var enemy := auto_free(EnemyState.new()) as EnemyState
	enemy.ai_type = GameEnums.AIType.CUNNING
	var cards: Array[CardData] = [
		_card("Dust Devil"), _card("Fools Gold"), _card("Deep Shaft"), _card("Black Damp")
	]

	var first := _pick_sequence(_controller_with_seed(4242), enemy, cards)
	var second := _pick_sequence(_controller_with_seed(171717), enemy, cards)

	assert_bool(first == second).is_false()
