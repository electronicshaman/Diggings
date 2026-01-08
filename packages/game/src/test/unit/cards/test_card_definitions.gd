extends GdUnitTestSuite
class_name TestCardDefinitions

const CARDS_PATH = "res://data/cards/"

func test_validate_all_cards():
	var cards = _load_all_cards(CARDS_PATH)
	assert_array(cards).is_not_empty()
	
	for card in cards:
		_validate_card(card)

func _load_all_cards(path: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					cards.append_array(_load_all_cards(path + "/" + file_name))
			elif file_name.ends_with(".tres") or file_name.ends_with(".remap"):
				# Godot exports sometimes use .remap, but in editor .tres is standard
				var full_path = path + "/" + file_name.replace(".remap", "")
				var resource = load(full_path)
				if resource is CardData:
					cards.append(resource)
			file_name = dir.get_next()
	return cards

func _validate_card(card: CardData):
	assert_object(card).is_not_null()
	
	# Basic Properties
	assert_str(card.card_name).is_not_empty()
	assert_int(card.energy_cost).is_greater_equal(0)
	
	# Type validity
	assert_bool(CardProperties.is_valid_card_type(card.card_type)).override_failure_message("Card '%s' has invalid type: '%s'" % [card.card_name, card.card_type]).is_true()
	
	# Handling
	assert_bool(CardHandling.is_valid_handling(card.card_handling)).override_failure_message("Card '%s' has invalid handling: '%s'" % [card.card_name, card.card_handling]).is_true()
	
	# Effects validity
	if card.effects:
		for effect in card.effects:
			assert_object(effect).is_not_null()
			# Ideally check if effect is a HandlerBase, but checking not null is a good start
