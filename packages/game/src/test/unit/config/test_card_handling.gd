extends GdUnitTestSuite
## Test suite for CardHandling class


func test_valid_handling_types():
	assert_bool(CardHandling.is_valid_handling("Standard")).is_true()
	assert_bool(CardHandling.is_valid_handling("Equipped")).is_true()
	assert_bool(CardHandling.is_valid_handling("Flash")).is_true()
	assert_bool(CardHandling.is_valid_handling("Hold")).is_true()
	assert_bool(CardHandling.is_valid_handling("Oneshot")).is_true()
	assert_bool(CardHandling.is_valid_handling("Recycle")).is_true()
	assert_bool(CardHandling.is_valid_handling("TopDeck")).is_true()
	assert_bool(CardHandling.is_valid_handling("BottomDeck")).is_true()
	assert_bool(CardHandling.is_valid_handling("Exhaust")).is_true()
	assert_bool(CardHandling.is_valid_handling("Keep")).is_false() # Keep was removed
	assert_bool(CardHandling.is_valid_handling("Invalid")).is_false()
	assert_bool(CardHandling.is_valid_handling("")).is_false()


func test_standard_handling():
	var def := CardHandling.get_handling_definition("Standard")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DISCARD)
	assert_bool(def.discards_after_use()).is_true()
	assert_bool(def.discards_end_of_turn).is_false()
	assert_bool(def.starts_in_hand).is_false()
	assert_bool(def.removed_after_use()).is_false()
	assert_bool(def.triggers_on_draw).is_false()
	assert_bool(def.returns_to_deck()).is_false()


func test_equipped_handling():
	var def := CardHandling.get_handling_definition("Equipped")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DISCARD)
	assert_bool(def.discards_after_use()).is_true()
	assert_bool(def.starts_in_hand).is_true() # Key difference


func test_flash_handling():
	var def := CardHandling.get_handling_definition("Flash")
	
	assert_bool(def.triggers_on_draw).is_true() # Key difference
	assert_bool(def.discards_after_use()).is_true()


func test_hold_handling():
	# Hold cards stay in hand at end of turn if not played, but discard normally when played
	var def := CardHandling.get_handling_definition("Hold")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DISCARD)
	assert_bool(def.discards_after_use()).is_true() # Discards when played
	assert_bool(def.discards_end_of_turn).is_false() # Stays in hand if not played


func test_repeat_handling():
	# Repeat cards return to hand after use (like boomerangs)
	var def := CardHandling.get_handling_definition("Repeat")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.HAND)
	assert_bool(def.stays_in_hand()).is_true()
	assert_bool(def.discards_after_use()).is_false()
	assert_bool(def.removed_after_use()).is_false()


func test_oneshot_handling():
	var def := CardHandling.get_handling_definition("Oneshot")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.EXHAUST)
	assert_bool(def.removed_after_use()).is_true() # Key difference
	assert_bool(def.discards_after_use()).is_false()


func test_exhaust_handling():
	var def := CardHandling.get_handling_definition("Exhaust")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.EXHAUST)
	assert_bool(def.removed_after_use()).is_true()
	assert_bool(def.discards_after_use()).is_false()


func test_recycle_handling():
	var def := CardHandling.get_handling_definition("Recycle")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DECK_SHUFFLE)
	assert_bool(def.returns_to_deck()).is_true()
	assert_bool(def.discards_after_use()).is_false()
	assert_bool(def.removed_after_use()).is_false()


func test_topdeck_handling():
	var def := CardHandling.get_handling_definition("TopDeck")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DECK_TOP)
	assert_bool(def.returns_to_deck()).is_true()
	assert_bool(def.discards_after_use()).is_false()
	assert_bool(def.removed_after_use()).is_false()


func test_bottomdeck_handling():
	var def := CardHandling.get_handling_definition("BottomDeck")
	
	assert_int(def.resolution_destination).is_equal(CardHandling.Destination.DECK_BOTTOM)
	assert_bool(def.returns_to_deck()).is_true()
	assert_bool(def.discards_after_use()).is_false()
	assert_bool(def.removed_after_use()).is_false()


func test_unknown_handling_defaults_to_standard():
	var def := CardHandling.get_handling_definition("InvalidType")
	var standard := CardHandling.get_handling_definition("Standard")
	
	# Unknown types should default to Standard behavior
	assert_int(def.resolution_destination).is_equal(standard.resolution_destination)
	assert_bool(def.discards_end_of_turn).is_equal(standard.discards_end_of_turn)
	assert_bool(def.starts_in_hand).is_equal(standard.starts_in_hand)
	assert_bool(def.triggers_on_draw).is_equal(standard.triggers_on_draw)
