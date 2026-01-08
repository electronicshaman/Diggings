extends GdUnitTestSuite
## Test suite for CardHandling class


func test_valid_handling_types():
	assert_bool(CardHandling.is_valid_handling("Standard")).is_true()
	assert_bool(CardHandling.is_valid_handling("Equipped")).is_true()
	assert_bool(CardHandling.is_valid_handling("Flash")).is_true()
	assert_bool(CardHandling.is_valid_handling("Keep")).is_true()
	assert_bool(CardHandling.is_valid_handling("Hold")).is_true()
	assert_bool(CardHandling.is_valid_handling("Oneshot")).is_true()
	assert_bool(CardHandling.is_valid_handling("Recycle")).is_true()
	assert_bool(CardHandling.is_valid_handling("TopDeck")).is_true()
	assert_bool(CardHandling.is_valid_handling("BottomDeck")).is_true()
	assert_bool(CardHandling.is_valid_handling("Invalid")).is_false()
	assert_bool(CardHandling.is_valid_handling("")).is_false()


func test_standard_handling():
	var def = CardHandling.get_handling_definition("Standard")
	
	assert_bool(def.get("discards_after_use")).is_true()
	assert_bool(def.get("discards_end_of_turn")).is_false()
	assert_bool(def.get("starts_in_hand")).is_false()
	assert_bool(def.get("removed_after_use")).is_false()
	assert_bool(def.get("triggers_on_draw")).is_false()
	assert_str(def.get("deck_return_position")).is_equal(CardHandling.DECK_RETURN_NONE)


func test_equipped_handling():
	var def = CardHandling.get_handling_definition("Equipped")
	
	assert_bool(def.get("discards_after_use")).is_true()
	assert_bool(def.get("starts_in_hand")).is_true() # Key difference
	assert_bool(def.get("removed_after_use")).is_false()


func test_flash_handling():
	var def = CardHandling.get_handling_definition("Flash")
	
	assert_bool(def.get("triggers_on_draw")).is_true() # Key difference
	assert_bool(def.get("discards_after_use")).is_true()


func test_keep_handling():
	var def = CardHandling.get_handling_definition("Keep")
	
	assert_bool(def.get("discards_after_use")).is_false() # Key difference
	assert_bool(def.get("discards_end_of_turn")).is_false()


func test_hold_handling():
	var def = CardHandling.get_handling_definition("Hold")
	
	assert_bool(def.get("discards_after_use")).is_false()
	assert_bool(def.get("discards_end_of_turn")).is_false()


func test_oneshot_handling():
	var def = CardHandling.get_handling_definition("Oneshot")
	
	assert_bool(def.get("removed_after_use")).is_true() # Key difference
	assert_bool(def.get("discards_after_use")).is_false()


func test_recycle_handling():
	var def = CardHandling.get_handling_definition("Recycle")
	
	assert_str(def.get("deck_return_position")).is_equal(CardHandling.DECK_RETURN_SHUFFLE)
	assert_bool(def.get("discards_after_use")).is_false()
	assert_bool(def.get("removed_after_use")).is_false()


func test_topdeck_handling():
	var def = CardHandling.get_handling_definition("TopDeck")
	
	assert_str(def.get("deck_return_position")).is_equal(CardHandling.DECK_RETURN_TOP)
	assert_bool(def.get("discards_after_use")).is_false()
	assert_bool(def.get("removed_after_use")).is_false()


func test_bottomdeck_handling():
	var def = CardHandling.get_handling_definition("BottomDeck")
	
	assert_str(def.get("deck_return_position")).is_equal(CardHandling.DECK_RETURN_BOTTOM)
	assert_bool(def.get("discards_after_use")).is_false()
	assert_bool(def.get("removed_after_use")).is_false()


func test_unknown_handling_defaults_to_standard():
	var def = CardHandling.get_handling_definition("InvalidType")
	var standard = CardHandling.get_handling_definition("Standard")
	
	# Unknown types should default to Standard behavior
	assert_bool(def.get("discards_after_use")).is_equal(standard.get("discards_after_use"))
	assert_bool(def.get("discards_end_of_turn")).is_equal(standard.get("discards_end_of_turn"))
	assert_bool(def.get("starts_in_hand")).is_equal(standard.get("starts_in_hand"))
	assert_bool(def.get("removed_after_use")).is_equal(standard.get("removed_after_use"))
	assert_bool(def.get("triggers_on_draw")).is_equal(standard.get("triggers_on_draw"))
	assert_str(def.get("deck_return_position")).is_equal(CardHandling.DECK_RETURN_NONE)
