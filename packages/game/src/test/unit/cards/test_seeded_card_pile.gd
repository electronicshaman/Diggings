extends GdUnitTestSuite

func _pile(seed_value: int) -> CardPile:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pile := CardPile.new("deck")
	pile.set_rng(rng)
	for name in ["A", "B", "C", "D", "E"]:
		var data := CardData.new()
		data.card_name = name
		pile.add_card(CardInstance.new(data))
	return pile

func _names(pile: CardPile) -> Array[String]:
	var result: Array[String] = []
	for card in pile.cards:
		result.append(card.card_data.card_name)
	return result

func test_same_seed_shuffles_and_draws_identically() -> void:
	var first := _pile(9090)
	var second := _pile(9090)
	first.shuffle()
	second.shuffle()
	assert_array(_names(first)).is_equal(_names(second))
	assert_str(first.draw_random().card_data.card_name).is_equal(second.draw_random().card_data.card_name)
