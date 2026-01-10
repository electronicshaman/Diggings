extends Node

## DeckManager Autoload
## Centralized management of the player's persistent deck throughout a run.
## Uses RunDeck for runtime deck state that can be saved/loaded.

const DEBUG_ENABLED: bool = true

signal deck_changed(change_type: String, card_data: Dictionary)
signal deck_loaded()
signal deck_saved()

## The current run's deck (null if no run active)
var current_run_deck: RunDeck = null

## Convenience property
var is_deck_loaded: bool:
	get: return current_run_deck != null


func _ready() -> void:
	GLog.debug("DeckManager initialized - Master of Cards")


## Initialize a new deck for a run from character class
func start_new_run_deck(character_class: String) -> bool:
	GLog.info("Starting new run deck for character: %s" % character_class)
	
	var deck_data := _load_character_deck_data(character_class)
	if not deck_data:
		GLog.error("Failed to load DeckData for character: %s" % character_class)
		return false
	
	current_run_deck = RunDeck.create_from_template(deck_data)
	if not current_run_deck:
		GLog.error("Failed to create RunDeck from template")
		return false
	
	# Connect to RunDeck signals
	_connect_run_deck_signals()
	
	deck_loaded.emit()
	GLog.info("New run deck initialized with %d cards" % current_run_deck.get_size())
	return true


## Initialize a run deck directly from a DeckData resource
func start_run_deck_from_data(deck_data: DeckData) -> bool:
	if not is_instance_valid(deck_data):
		GLog.error("DeckManager: Invalid DeckData provided")
		return false
	
	current_run_deck = RunDeck.create_from_template(deck_data)
	if not current_run_deck:
		GLog.error("Failed to create RunDeck from provided DeckData")
		return false
	
	_connect_run_deck_signals()
	deck_loaded.emit()
	GLog.info("Run deck initialized from '%s' with %d cards" % [deck_data.deck_name, current_run_deck.get_size()])
	return true


## Get the current RunDeck (for advanced usage)
func get_run_deck() -> RunDeck:
	return current_run_deck


## Get current deck cards for duel initialization
func get_current_deck() -> Array[CardData]:
	if not current_run_deck:
		GLog.warn("DeckManager: No deck loaded, returning empty array")
		return []
	
	return current_run_deck.get_cards_copy()


## Create a CardPile from the current deck (uses factory)
func create_card_pile(card_owner = null) -> CardPile:
	if not current_run_deck:
		GLog.error("DeckManager: Cannot create CardPile - no deck loaded")
		return null
	
	return CardPileFactory.create_from_run_deck(current_run_deck, card_owner)


## Add a card to the current deck (e.g., from card rewards)
func add_card(card: CardData) -> bool:
	if not current_run_deck:
		GLog.error("DeckManager: Cannot add card - no deck loaded")
		return false
	
	if not is_instance_valid(card):
		GLog.error("DeckManager: Cannot add invalid card")
		return false
	
	var success = current_run_deck.add_card(card)
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
	if not current_run_deck:
		GLog.error("DeckManager: Cannot remove card - no deck loaded")
		return false
	
	if not is_instance_valid(card):
		GLog.error("DeckManager: Cannot remove invalid card")
		return false
	
	var success = current_run_deck.remove_card(card)
	if success:
		GLog.info("Removed card from deck: %s" % card.card_name)
		deck_changed.emit("card_removed", {"card": card})
	else:
		GLog.error("Failed to remove card from deck: %s" % card.card_name)
	
	return success


## Remove a card by name (removes first match)
func remove_card_by_name(card_name: String) -> bool:
	if not current_run_deck:
		GLog.error("DeckManager: Cannot remove card - no deck loaded")
		return false
	
	if card_name.is_empty():
		GLog.error("DeckManager: Cannot remove card with empty name")
		return false
	
	var success = current_run_deck.remove_card_by_name(card_name)
	if success:
		GLog.info("Removed card from deck by name: %s" % card_name)
		deck_changed.emit("card_removed", {"card_name": card_name})
	else:
		GLog.error("Failed to remove card from deck by name: %s" % card_name)
	
	return success


## Upgrade a card (replace with upgraded version)
func upgrade_card(old_card: CardData, new_card: CardData) -> bool:
	if not current_run_deck:
		GLog.error("DeckManager: Cannot upgrade card - no deck loaded")
		return false
	
	if not is_instance_valid(old_card) or not is_instance_valid(new_card):
		GLog.error("DeckManager: Cannot upgrade with invalid cards")
		return false
	
	var success = current_run_deck.upgrade_card(old_card, new_card)
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
	if not current_run_deck:
		return 0
	return current_run_deck.get_size()


## Get deck composition for UI display
func get_deck_composition() -> Dictionary:
	if not current_run_deck:
		return {}
	return current_run_deck.get_composition_by_type()


## Get deck statistics
func get_deck_statistics() -> Dictionary:
	if not current_run_deck:
		return {}
	return current_run_deck.statistics.duplicate()


## Get comprehensive deck summary for debugging
func get_deck_summary() -> Dictionary:
	if not current_run_deck:
		return {"error": "No deck loaded"}
	return current_run_deck.get_summary()


## Validate current deck integrity
func validate_current_deck() -> Array[String]:
	if not current_run_deck:
		return ["No deck loaded"]
	return current_run_deck.validate()


## Save deck to file (for save games)
func save_deck(save_path: String) -> bool:
	if not current_run_deck:
		GLog.error("DeckManager: Cannot save - no deck loaded")
		return false
	
	var result := ResourceSaver.save(current_run_deck, save_path)
	if result == OK:
		GLog.debug("Run deck saved to: %s" % save_path)
		deck_saved.emit()
		return true
	else:
		GLog.error("Failed to save deck to: %s (Error: %d)" % [save_path, result])
		return false


## Load deck from file (for save games)
func load_deck(load_path: String) -> bool:
	if not ResourceLoader.exists(load_path):
		GLog.error("DeckManager: Deck file not found: %s" % load_path)
		return false
	
	var loaded_resource = ResourceLoader.load(load_path)
	if not loaded_resource or not loaded_resource is RunDeck:
		GLog.error("DeckManager: Invalid RunDeck resource at: %s" % load_path)
		return false
	
	current_run_deck = loaded_resource as RunDeck
	_connect_run_deck_signals()
	
	deck_loaded.emit()
	GLog.info("Deck loaded from: %s (%d cards)" % [load_path, current_run_deck.get_size()])
	return true


## Check if a deck is currently loaded
func is_deck_available() -> bool:
	return current_run_deck != null


## Clear current deck (for run end)
func clear_current_deck() -> void:
	if current_run_deck:
		current_run_deck.clear()
	current_run_deck = null
	GLog.debug("Current deck cleared")


## Get a card by name from the current deck (for UI/debugging)
func find_card_by_name(card_name: String) -> CardData:
	if not current_run_deck:
		return null
	
	for card in current_run_deck.cards:
		if is_instance_valid(card) and card.card_name == card_name:
			return card
	
	return null


## Get cards by type
func get_cards_by_type(card_type: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	
	if not current_run_deck:
		return cards
	
	for card in current_run_deck.cards:
		if is_instance_valid(card) and card.card_type == card_type:
			cards.append(card)
	
	return cards


## Get all curse cards in the deck (for UI display or rest site)
func get_curse_cards() -> Array[CardData]:
	return get_cards_by_type("Curse")


## Remove all curse cards from deck (called at rest sites)
## Returns number of curses removed
func remove_curse_cards() -> int:
	if not current_run_deck:
		GLog.warn("DeckManager: Cannot remove curses - no deck loaded")
		return 0
	
	var curses = get_curse_cards()
	var removed_count = 0
	
	for curse in curses:
		if current_run_deck.remove_card(curse):
			removed_count += 1
			GLog.info("Removed curse from deck: %s" % curse.card_name)
	
	if removed_count > 0:
		deck_changed.emit("curses_removed", {"count": removed_count})
		GLog.info("DeckManager: Removed %d curse cards at rest" % removed_count)
	
	return removed_count


# ============================================================================
# Private Methods
# ============================================================================

## Load DeckData for a character class
func _load_character_deck_data(character_class: String) -> DeckData:
	var character_path := "res://data/characters/%s.tres" % character_class.to_lower()
	if not ResourceLoader.exists(character_path):
		GLog.error("Character resource not found: %s" % character_path)
		return null
	
	var character_resource = ResourceLoader.load(character_path)
	if not character_resource:
		GLog.error("Failed to load character resource: %s" % character_path)
		return null
	
	# Get the DeckData from the character
	var deck_resource_path: String = character_resource.get("starting_deck_resource")
	if deck_resource_path.is_empty():
		GLog.error("Character has no starting_deck_resource: %s" % character_class)
		return null
	
	if not ResourceLoader.exists(deck_resource_path):
		GLog.error("DeckData resource not found: %s" % deck_resource_path)
		return null
	
	var deck_data := load(deck_resource_path) as DeckData
	if not deck_data:
		GLog.error("Failed to load DeckData: %s" % deck_resource_path)
		return null
	
	GLog.debug("Loaded DeckData for %s: %s" % [character_class, deck_data.deck_name])
	return deck_data


## Connect to RunDeck signals
func _connect_run_deck_signals() -> void:
	if not current_run_deck:
		return
	
	# Disconnect any existing connections
	if current_run_deck.changed.is_connected(_on_run_deck_changed):
		current_run_deck.changed.disconnect(_on_run_deck_changed)
	
	# Connect to changes
	current_run_deck.changed.connect(_on_run_deck_changed)


## Handle RunDeck changes
func _on_run_deck_changed() -> void:
	GLog.debug("Deck changed - Version: %d, Size: %d" % [
		current_run_deck.version if current_run_deck else 0,
		current_run_deck.get_size() if current_run_deck else 0
	])
	
	# Emit EventBus signal if available
	if is_instance_valid(EventBus) and EventBus.has_signal("deck_modified"):
		EventBus.deck_modified.emit(current_run_deck.get_summary() if current_run_deck else {})
