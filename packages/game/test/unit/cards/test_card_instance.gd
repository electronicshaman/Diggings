extends GdUnitTestSuite
# Test suite for CardInstance class


var _card_data: CardData
var _instance: CardInstance

func before_test():
	_card_data = CardData.new()
	_card_data.card_name = "Test Card"
	_card_data.base_durability = 3
	_card_data.description = "Base Description"
	
	_instance = CardInstance.new(_card_data)

func test_initialization():
	assert_str(_instance.get_card_name()).is_equal("Test Card")
	assert_int(_instance.get_base_durability()).is_equal(3)
	assert_int(_instance.get_current_durability()).is_equal(3)
	assert_bool(_instance.is_broken()).is_false()

func test_durability_decrement():
	# Decrement 1
	var broke = _instance.decrement_durability()
	assert_bool(broke).is_false()
	assert_int(_instance.get_current_durability()).is_equal(2)
	
	# Decrement 2
	broke = _instance.decrement_durability()
	assert_bool(broke).is_false()
	assert_int(_instance.get_current_durability()).is_equal(1)
	
	# Decrement 3 (Break)
	broke = _instance.decrement_durability()
	assert_bool(broke).is_true()
	assert_int(_instance.get_current_durability()).is_equal(0)
	assert_bool(_instance.is_broken()).is_true()

func test_dynamic_properties():
	assert_str(_instance.get_description()).is_equal("Base Description")
	
	_instance.set_dynamic_description("Overridden Description")
	assert_str(_instance.get_description()).is_equal("Overridden Description")
	
	_instance.clear_dynamic_properties()
	assert_str(_instance.get_description()).is_equal("Base Description")

func test_hold_mechanic():
	assert_int(_instance.turns_held).is_equal(0)
	
	_instance.increment_turns_held()
	assert_int(_instance.turns_held).is_equal(1)
	
	_instance.reset_turns_held()
	assert_int(_instance.turns_held).is_equal(0)
