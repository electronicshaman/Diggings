extends EncounterOutcome
class_name CardReward

const OUTCOME_NAME := "CardReward"

@export var card_paths: Array[String] = []
@export var random_cards: bool = false
@export var card_count: int = 1
@export var card_rarity: String = "Common"
@export var card_type: String = ""
@export var remove_card: bool = false

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	if remove_card:
		_handle_card_removal(encounter_manager, game_state)
	else:
		_handle_card_addition(encounter_manager, game_state)

func _handle_card_addition(encounter_manager: Node, game_state: Dictionary) -> void:
	var cards_to_add = []
	
	if random_cards:
		cards_to_add = _get_random_cards(game_state)
	else:
		for path in card_paths:
			if ResourceLoader.exists(path):
				var card_data = load(path)
				if card_data:
					cards_to_add.append(card_data)
	
	for card in cards_to_add:
		if encounter_manager.game_manager:
			encounter_manager.game_manager.add_card_to_deck(card)
		
		if encounter_manager.event_bus:
			encounter_manager.event_bus.card_created.emit(card)
		
		GLog.debug("Added card to deck: %s" % card.card_name)

func _handle_card_removal(encounter_manager: Node, _game_state: Dictionary) -> void:
	if encounter_manager.event_bus:
		encounter_manager.event_bus.ui_popup_opened.emit("card_removal")
	
	GLog.debug("Opened card removal interface")

func _get_random_cards(game_state: Dictionary) -> Array:
	var cards = []
	var base_path = "res://data/cards/"
	var type_folders = {
		"Attack": "attack/",
		"Skill": "skill/",
		"Power": "power/",
		"Fortune": "fortune/"
	}
	
	var folder = ""
	if card_type != "" and card_type in type_folders:
		folder = type_folders[card_type]
	else:
		var keys = type_folders.keys()
		folder = type_folders[keys[randi() % keys.size()]]
	
	var character_class = game_state.get("character_class", "")
	
	for i in range(card_count):
		var card = _load_random_card_from_folder(base_path + folder, character_class)
		if card:
			cards.append(card)
	
	return cards

func _load_random_card_from_folder(folder_path: String, character_class: String) -> Resource:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return null
	
	var valid_cards = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card_path = folder_path + file_name
			var card = load(card_path)
			if card and card.is_available_to_class(character_class):
				if card_rarity == "" or card.accessibility_tier == card_rarity:
					valid_cards.append(card)
		file_name = dir.get_next()
	
	if valid_cards.is_empty():
		return null
	
	return valid_cards[randi() % valid_cards.size()]

func get_formatted_description() -> String:
	if remove_card:
		return "Remove a card from your deck"
	elif random_cards:
		var type_text = ""
		if card_type != "":
			type_text = " %s" % card_type
		return "Add %d random%s card(s) to your deck" % [card_count, type_text]
	else:
		if card_paths.size() == 1:
			var card_name = card_paths[0].get_file().get_basename().replace("_", " ").capitalize()
			return "Add %s to your deck" % card_name
		return "Add %d specific cards to your deck" % card_paths.size()

func get_preview_text() -> String:
	if remove_card:
		return "Remove card"
	elif random_cards:
		return "+%d card(s)" % card_count
	else:
		return "+%d card(s)" % card_paths.size()

func is_positive() -> bool:
	return not remove_card

func get_outcome_name() -> String:
	return OUTCOME_NAME
