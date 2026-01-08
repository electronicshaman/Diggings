extends GdUnitTestSuite
class_name TestCardData

var _card_data: CardData

func before_test():
	_card_data = CardData.new()
	_card_data.card_name = "Test Card"

func test_initialization():
	assert_str(_card_data.card_name).is_equal("Test Card")
	assert_int(_card_data.energy_cost).is_equal(1)
	assert_str(_card_data.card_type).is_equal("Attack")
	assert_str(_card_data.rarity).is_equal("Common")

func test_standard_handling():
	_card_data.card_handling = "Standard"
	
	assert_bool(_card_data.discards_after_use()).is_true()
	assert_bool(_card_data.starts_in_hand()).is_false()
	assert_bool(_card_data.removed_after_use()).is_false()
	assert_bool(_card_data.returns_to_deck()).is_false()
	assert_int(_card_data.get_resolution_destination()).is_equal(CardHandling.Destination.DISCARD)

func test_equipped_handling():
	_card_data.card_handling = "Equipped"
	
	assert_bool(_card_data.discards_after_use()).is_true()
	assert_bool(_card_data.starts_in_hand()).is_true()
	
func test_oneshot_handling():
	_card_data.card_handling = "Oneshot"
	
	assert_bool(_card_data.discards_after_use()).is_false() # Oneshot doesn't discard, it removes
	assert_bool(_card_data.removed_after_use()).is_true()

func test_recycle_handling():
	_card_data.card_handling = "Recycle"
	
	assert_bool(_card_data.discards_after_use()).is_false()
	assert_bool(_card_data.returns_to_deck()).is_true()
	assert_int(_card_data.get_resolution_destination()).is_equal(CardHandling.Destination.DECK_SHUFFLE)

func test_top_deck_handling():
	_card_data.card_handling = "TopDeck"
	
	assert_bool(_card_data.returns_to_deck()).is_true()
	assert_int(_card_data.get_resolution_destination()).is_equal(CardHandling.Destination.DECK_TOP)
	
func test_class_access_methods():
	_card_data.accessibility_tier = "Class"
	assert_bool(_card_data.is_class_card()).is_true()
	assert_bool(_card_data.is_starting_card()).is_false()
	
	_card_data.accessibility_tier = "Starting"
	assert_bool(_card_data.is_starting_card()).is_true()
	
func test_card_type_helpers():
	_card_data.card_type = "Attack"
	assert_bool(_card_data.is_attack()).is_true()
	assert_bool(_card_data.is_skill()).is_false()
	
	_card_data.card_type = "Skill"
	assert_bool(_card_data.is_skill()).is_true()
	
	_card_data.card_type = "Power"
	assert_bool(_card_data.is_power()).is_true()
