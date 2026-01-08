extends GdUnitTestSuite
## Test suite for CardProperties class


func test_valid_card_types():
	assert_bool(CardProperties.is_valid_card_type("Attack")).is_true()
	assert_bool(CardProperties.is_valid_card_type("Skill")).is_true()
	assert_bool(CardProperties.is_valid_card_type("Power")).is_true()
	assert_bool(CardProperties.is_valid_card_type("Fortune")).is_true()
	assert_bool(CardProperties.is_valid_card_type("Invalid")).is_false()
	assert_bool(CardProperties.is_valid_card_type("")).is_false()


func test_card_type_colors():
	# Valid types return specific colors
	assert_object(CardProperties.get_card_color("Attack")).is_not_equal(Color.WHITE)
	assert_object(CardProperties.get_card_color("Skill")).is_not_equal(Color.WHITE)
	assert_object(CardProperties.get_card_color("Power")).is_not_equal(Color.WHITE)
	assert_object(CardProperties.get_card_color("Fortune")).is_not_equal(Color.WHITE)
	
	# Invalid type returns WHITE
	assert_object(CardProperties.get_card_color("Invalid")).is_equal(Color.WHITE)


func test_card_type_symbols():
	# Each type has a unique symbol
	var attack_symbol = CardProperties.get_card_symbol("Attack")
	var skill_symbol = CardProperties.get_card_symbol("Skill")
	var power_symbol = CardProperties.get_card_symbol("Power")
	var fortune_symbol = CardProperties.get_card_symbol("Fortune")
	
	assert_str(attack_symbol).is_not_empty()
	assert_str(skill_symbol).is_not_empty()
	assert_str(power_symbol).is_not_empty()
	assert_str(fortune_symbol).is_not_empty()
	
	# All symbols should be different
	assert_str(attack_symbol).is_not_equal(skill_symbol)
	assert_str(attack_symbol).is_not_equal(power_symbol)
	assert_str(attack_symbol).is_not_equal(fortune_symbol)
	
	# Invalid type returns "?"
	assert_str(CardProperties.get_card_symbol("Invalid")).is_equal("?")


func test_valid_card_rarity():
	assert_bool(CardProperties.is_valid_card_rarity("Common")).is_true()
	assert_bool(CardProperties.is_valid_card_rarity("Uncommon")).is_true()
	assert_bool(CardProperties.is_valid_card_rarity("Rare")).is_true()
	assert_bool(CardProperties.is_valid_card_rarity("Eldritch")).is_true()
	assert_bool(CardProperties.is_valid_card_rarity("Legendary")).is_false() # Curio rarity, not card
	assert_bool(CardProperties.is_valid_card_rarity("Invalid")).is_false()


func test_rarity_colors():
	# All valid rarities return specific colors
	assert_object(CardProperties.get_rarity_color("Common")).is_equal(Color.GRAY)
	assert_object(CardProperties.get_rarity_color("Uncommon")).is_equal(Color.LIME)
	assert_object(CardProperties.get_rarity_color("Rare")).is_equal(Color.CYAN)
	assert_object(CardProperties.get_rarity_color("Legendary")).is_equal(Color.GOLD)
	assert_object(CardProperties.get_rarity_color("Eldritch")).is_equal(Color.DARK_VIOLET)
	assert_object(CardProperties.get_rarity_color("Corrupted")).is_equal(Color.PURPLE)
	assert_object(CardProperties.get_rarity_color("Story")).is_equal(Color.PURPLE)
	
	# Invalid rarity returns WHITE
	assert_object(CardProperties.get_rarity_color("Invalid")).is_equal(Color.WHITE)
