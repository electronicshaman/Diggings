extends GdUnitTestSuite

func _paths(cards: Array[CardData]) -> Array[String]:
	var result: Array[String] = []
	for card in cards:
		result.append(card.resource_path)
	return result

func _unique_path_count(cards: Array[CardData]) -> int:
	var unique: Dictionary = {}
	for card in cards:
		unique[card.resource_path] = true
	return unique.size()

func test_same_seed_produces_same_unique_legal_offers() -> void:
	var character := load("res://data/characters/bushranger.tres") as CharacterClass
	var candidates := RewardOfferGenerator.load_candidates("res://data/cards/player")
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 424242
	second_rng.seed = 424242
	var first := RewardOfferGenerator.generate(character, candidates, 3, first_rng)
	var second := RewardOfferGenerator.generate(character, candidates, 3, second_rng)
	assert_array(_paths(first)).is_equal(_paths(second))
	assert_int(first.size()).is_equal(3)
	assert_int(_unique_path_count(first)).is_equal(3)
	for card in first:
		assert_bool(character.can_use_card(card)).is_true()

func test_ten_seed_sample_contains_multiple_offer_sets() -> void:
	var character := load("res://data/characters/prospector.tres") as CharacterClass
	var candidates := RewardOfferGenerator.load_candidates("res://data/cards/player")
	var offer_sets: Dictionary = {}
	for seed_value in range(100, 110):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		offer_sets["|".join(_paths(RewardOfferGenerator.generate(character, candidates, 3, rng)))] = true
	assert_bool(offer_sets.size() >= 2).is_true()
