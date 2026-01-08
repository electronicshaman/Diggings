extends Node

## DeckManager Autoload
# Centralized management of the player's persistent deck throughout the run
# Handles deck modifications, statistics, and provides deck data for duels

const DEBUG_ENABLED: bool = true

signal deck_changed(change_type: String, card_data: Dictionary)
signal deck_loaded()
signal deck_saved()

var current_deck_state: DeckState
var is_deck_loaded: bool = false

func _ready() -> void:
	GLog.debug("DeckManager initialized - Master of Cards")
	current_deck_state = DeckState.new()
	
	# Connect to deck state changes
	if current_deck_state.changed.connect(_on_deck_state_changed) != OK:
		push_warning("DeckManager: Failed to connect to deck state changes")

## Initialize a new deck for a run start
func start_new_run_deck(character_class: String) -> bool:
	GLog.info("Starting new run deck for character: %s" % character_class)
	
	var starting_deck = _load_character_starting_deck(character_class)
	if starting_deck.is_empty():
		GLog.error("Failed to load starting deck for character: %s" % character_class)
		return false
	
	current_deck_state = DeckState.new()
	current_deck_state.initialize_deck(starting_deck)
	
	# Connect to new deck state
	if current_deck_state.changed.connect(_on_deck_state_changed) != OK:
		push_warning("DeckManager: Failed to connect to new deck state changes")
	
	is_deck_loaded = true
	deck_loaded.emit()
	
	GLog.info("New run deck initialized with %d cards" % current_deck_state.get_deck_size())
	return true

## Get the current deck for duel initialization
func get_current_deck() -> Array[CardData]:
	if not is_deck_loaded or not current_deck_state:
		GLog.warn("DeckManager: No deck loaded, returning empty array")
		return []
	
	return current_deck_state.get_deck_copy()

## Add a card to the current deck (e.g., from card rewards)
func add_card(card: CardData) -> bool:
	if not is_deck_loaded or not current_deck_state:
		GLog.error("DeckManager: Cannot add card - no deck loaded")
		return false
	
	if not is_instance_valid(card):
		GLog.error("DeckManager: Cannot add invalid card")
		return false
	
	var success = current_deck_state.add_card(card)
	if success:
		GLog.info("Added card to deck: %s" % card.card_name)
		deck_changed.emit("card_added", {"card": card})
		
		# Update statistics if GameManager is available
		if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
			GameManager.increment_statistic("cards_acquired")
	else:
		GLog.error("Failed to add card to deck: %s" % card.card_name)
	
	return success

## Remove a card from the current deck
func remove_card(card: CardData) -> bool:
	if not is_deck_loaded or not current_deck_state:
		GLog.error("DeckManager: Cannot remove card - no deck loaded")
		return false
	
	if not is_instance_valid(card):
		GLog.error("DeckManager: Cannot remove invalid card")
		return false
	
	var success = current_deck_state.remove_card(card)
	if success:
		GLog.info("Removed card from deck: %s" % card.card_name)
		deck_changed.emit("card_removed", {"card": card})
	else:
		GLog.error("Failed to remove card from deck: %s" % card.card_name)
	
	return success

## Remove a card by name (removes first match)
func remove_card_by_name(card_name: String) -> bool:
	if not is_deck_loaded or not current_deck_state:
		GLog.error("DeckManager: Cannot remove card - no deck loaded")
		return false
	
	if card_name.is_empty():
		GLog.error("DeckManager: Cannot remove card with empty name")
		return false
	
	var success = current_deck_state.remove_card_by_name(card_name)
	if success:
		GLog.info("Removed card from deck by name: %s" % card_name)
		deck_changed.emit("card_removed", {"card_name": card_name})
	else:
		GLog.error("Failed to remove card from deck by name: %s" % card_name)
	
	return success

## Upgrade a card (replace with upgraded version)
func upgrade_card(old_card: CardData, new_card: CardData) -> bool:
	if not is_deck_loaded or not current_deck_state:
		GLog.error("DeckManager: Cannot upgrade card - no deck loaded")
		return false
	
	if not is_instance_valid(old_card) or not is_instance_valid(new_card):
		GLog.error("DeckManager: Cannot upgrade with invalid cards")
		return false
	
	var success = current_deck_state.upgrade_card(old_card, new_card)
	if success:
		GLog.info("Upgraded card: %s -> %s" % [old_card.card_name, new_card.card_name])
		deck_changed.emit("card_upgraded", {"old_card": old_card, "new_card": new_card})
		
		# Update statistics if GameManager is available
		if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
			GameManager.increment_statistic("cards_upgraded")
	else:
		GLog.error("Failed to upgrade card: %s" % old_card.card_name)
	
	return success

## Get current deck size
func get_deck_size() -> int:
	if not is_deck_loaded or not current_deck_state:
		return 0
	
	return current_deck_state.get_deck_size()

## Get deck composition for UI display
func get_deck_composition() -> Dictionary:
	if not is_deck_loaded or not current_deck_state:
		return {}
	
	return current_deck_state.get_deck_composition()

## Get deck statistics
func get_deck_statistics() -> Dictionary:
	if not is_deck_loaded or not current_deck_state:
		return {}
	
	return current_deck_state.deck_statistics.duplicate()

## Get comprehensive deck summary for debugging
func get_deck_summary() -> Dictionary:
	if not is_deck_loaded or not current_deck_state:
		return {"error": "No deck loaded"}
	
	return current_deck_state.get_deck_summary()

## Validate current deck integrity
func validate_current_deck() -> Array[String]:
	if not is_deck_loaded or not current_deck_state:
		return ["No deck loaded"]
	
	return current_deck_state.validate_deck()

## Save deck state to file (for persistent saves)
func save_deck_state(save_path: String) -> bool:
	if not is_deck_loaded or not current_deck_state:
		GLog.error("DeckManager: Cannot save - no deck loaded")
		return false
	
	var result = ResourceSaver.save(current_deck_state, save_path)
	if result == OK:
		GLog.debug("Deck state saved to: %s" % save_path)
		deck_saved.emit()
		return true
	else:
		GLog.error("Failed to save deck state to: %s (Error: %d)" % [save_path, result])
		return false

## Load deck state from file
func load_deck_state(load_path: String) -> bool:
	if not ResourceLoader.exists(load_path):
		GLog.error("DeckManager: Deck state file not found: %s" % load_path)
		return false
	
	var loaded_resource = ResourceLoader.load(load_path)
	if not loaded_resource or not loaded_resource is DeckState:
		GLog.error("DeckManager: Invalid deck state resource at: %s" % load_path)
		return false
	
	current_deck_state = loaded_resource as DeckState
	
	# Connect to loaded deck state
	if current_deck_state.changed.connect(_on_deck_state_changed) != OK:
		push_warning("DeckManager: Failed to connect to loaded deck state changes")
	
	is_deck_loaded = true
	deck_loaded.emit()
	
	GLog.info("Deck state loaded from: %s (%d cards)" % [load_path, current_deck_state.get_deck_size()])
	return true

## Check if a deck is currently loaded
func is_deck_available() -> bool:
	return is_deck_loaded and current_deck_state != null

## Clear current deck (for run end)
func clear_current_deck() -> void:
	if current_deck_state:
		current_deck_state.clear_deck()
	
	is_deck_loaded = false
	GLog.debug("Current deck cleared")

## Get a card by name from the current deck (for UI/debugging)
func find_card_by_name(card_name: String) -> CardData:
	if not is_deck_loaded or not current_deck_state:
		return null
	
	for card in current_deck_state.master_deck:
		if is_instance_valid(card) and card.card_name == card_name:
			return card
	
	return null

## Get cards by mechanical category
func get_cards_by_category(category: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	if not is_deck_loaded or not current_deck_state:
		return cards
	
	for card in current_deck_state.master_deck:
		if is_instance_valid(card) and card.card_type == category:
			cards.append(card)
	
	return cards

## Get cards by type
func get_cards_by_type(card_type: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	if not is_deck_loaded or not current_deck_state:
		return cards
	
	for card in current_deck_state.master_deck:
		if is_instance_valid(card) and card.card_type == card_type:
			cards.append(card)
	
	return cards

## Private: Load starting deck for a character class
func _load_character_starting_deck(character_class: String) -> Array[CardData]:
	var deck: Array[CardData] = []
	
	var character_path = "res://data/characters/%s.tres" % character_class.to_lower()
	if not ResourceLoader.exists(character_path):
		GLog.error("Character resource not found: %s" % character_path)
		return deck
	
	var character_resource = ResourceLoader.load(character_path)
	if not character_resource:
		GLog.error("Failed to load character resource: %s" % character_path)
		return deck
	
	if character_resource.has_method("load_starting_deck"):
		deck = character_resource.load_starting_deck()
		GLog.debug("Loaded starting deck for %s: %d cards" % [character_class, deck.size()])
	else:
		GLog.error("Character resource missing load_starting_deck method: %s" % character_path)
	
	return deck

## Private: Handle deck state changes
func _on_deck_state_changed() -> void:
	GLog.debug("Deck state changed - Version: %d, Size: %d" % [
		current_deck_state.deck_version if current_deck_state else 0,
		current_deck_state.get_deck_size() if current_deck_state else 0
	])
	
	# Emit EventBus signal if available
	if is_instance_valid(EventBus) and EventBus.has_signal("deck_modified"):
		EventBus.deck_modified.emit(current_deck_state.get_deck_summary() if current_deck_state else {})
