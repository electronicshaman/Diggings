extends Resource
class_name RunDeck

## RunDeck Resource
## Runtime deck for a single run, cloned from DeckData template.
## Modifications persist throughout the run without affecting the source template.
##
## Usage:
##   var run_deck = RunDeck.create_from_template(deck_data)
##   run_deck.add_card(new_card)
##   run_deck.remove_card(old_card)

# Signals
signal deck_modified(change_type: String, card_data: CardData)
signal card_added(card: CardData)
signal card_removed(card: CardData)

# Source template reference (for debugging/analytics)
@export var source_deck_path: String = ""
@export var source_deck_name: String = ""

# Current deck composition
@export var cards: Array[CardData] = []

# Run statistics
@export var statistics: Dictionary = {
	"cards_added": 0,
	"cards_removed": 0,
	"cards_upgraded": 0,
	"total_modifications": 0
}

# Metadata
@export var created_at: float = 0.0
@export var last_modified: float = 0.0
@export var version: int = 1


## Factory method: Create a RunDeck from a DeckData template
static func create_from_template(deck_data: DeckData) -> RunDeck:
	if not is_instance_valid(deck_data):
		push_error("RunDeck: Cannot create from invalid DeckData")
		return null
	
	var run_deck := RunDeck.new()
	run_deck.source_deck_path = deck_data.resource_path
	run_deck.source_deck_name = deck_data.deck_name
	run_deck.created_at = Time.get_unix_time_from_system()
	run_deck.last_modified = run_deck.created_at
	
	# Load cards from template paths
	for card_path in deck_data.card_paths:
		if ResourceLoader.exists(card_path):
			var card := load(card_path) as CardData
			if card:
				run_deck.cards.append(card)
			else:
				push_warning("RunDeck: Failed to load card as CardData: %s" % card_path)
		else:
			push_warning("RunDeck: Card path does not exist: %s" % card_path)
	
	GLog.info("RunDeck created from '%s' with %d cards" % [deck_data.deck_name, run_deck.cards.size()])
	return run_deck


## Add a card to the deck
func add_card(card: CardData) -> bool:
	if not is_instance_valid(card):
		push_warning("RunDeck: Cannot add invalid card")
		return false
	
	cards.append(card)
	statistics.cards_added += 1
	statistics.total_modifications += 1
	_mark_modified()
	
	card_added.emit(card)
	deck_modified.emit("card_added", card)
	emit_changed()
	
	GLog.debug("RunDeck: Added card '%s' (total: %d)" % [card.card_name, cards.size()])
	return true


## Remove a card from the deck (first match)
func remove_card(card: CardData) -> bool:
	if not is_instance_valid(card):
		push_warning("RunDeck: Cannot remove invalid card")
		return false
	
	var index := cards.find(card)
	if index < 0:
		push_warning("RunDeck: Card not found for removal: %s" % card.card_name)
		return false
	
	cards.remove_at(index)
	statistics.cards_removed += 1
	statistics.total_modifications += 1
	_mark_modified()
	
	card_removed.emit(card)
	deck_modified.emit("card_removed", card)
	emit_changed()
	
	GLog.debug("RunDeck: Removed card '%s' (total: %d)" % [card.card_name, cards.size()])
	return true


## Remove a card by name (first match)
func remove_card_by_name(card_name: String) -> bool:
	if card_name.is_empty():
		push_warning("RunDeck: Cannot remove card with empty name")
		return false
	
	for i in range(cards.size()):
		if cards[i] and cards[i].card_name == card_name:
			var card := cards[i]
			cards.remove_at(i)
			statistics.cards_removed += 1
			statistics.total_modifications += 1
			_mark_modified()
			
			card_removed.emit(card)
			deck_modified.emit("card_removed", card)
			emit_changed()
			
			GLog.debug("RunDeck: Removed card by name '%s' (total: %d)" % [card_name, cards.size()])
			return true
	
	push_warning("RunDeck: No card with name '%s' found" % card_name)
	return false


## Upgrade a card (replace old with new)
func upgrade_card(old_card: CardData, new_card: CardData) -> bool:
	if not is_instance_valid(old_card) or not is_instance_valid(new_card):
		push_warning("RunDeck: Cannot upgrade with invalid cards")
		return false
	
	var index := cards.find(old_card)
	if index < 0:
		push_warning("RunDeck: Card not found for upgrade: %s" % old_card.card_name)
		return false
	
	cards[index] = new_card
	statistics.cards_upgraded += 1
	statistics.total_modifications += 1
	_mark_modified()
	
	deck_modified.emit("card_upgraded", new_card)
	emit_changed()
	
	GLog.debug("RunDeck: Upgraded '%s' -> '%s'" % [old_card.card_name, new_card.card_name])
	return true


## Get a copy of all cards (for read-only access)
func get_cards_copy() -> Array[CardData]:
	return cards.duplicate()


## Get deck size
func get_size() -> int:
	return cards.size()


## Check if deck contains a card
func has_card(card: CardData) -> bool:
	return card in cards


## Check if deck contains a card by name
func has_card_by_name(card_name: String) -> bool:
	for card in cards:
		if card and card.card_name == card_name:
			return true
	return false


## Get count of a specific card
func get_card_count(card: CardData) -> int:
	var count := 0
	for c in cards:
		if c == card:
			count += 1
	return count


## Get deck composition by card type
func get_composition_by_type() -> Dictionary:
	var composition := {}
	for card in cards:
		if is_instance_valid(card):
			var card_type: String = card.card_type
			composition[card_type] = composition.get(card_type, 0) + 1
	return composition


## Get energy curve
func get_energy_curve() -> Dictionary:
	var curve := {}
	for card in cards:
		if is_instance_valid(card):
			var cost: int = card.energy_cost
			curve[cost] = curve.get(cost, 0) + 1
	return curve


## Validate deck integrity
func validate() -> Array[String]:
	var issues: Array[String] = []
	
	if cards.is_empty():
		issues.append("Deck is empty")
	
	var invalid_count := 0
	for card in cards:
		if not is_instance_valid(card):
			invalid_count += 1
	
	if invalid_count > 0:
		issues.append("Deck contains %d invalid card(s)" % invalid_count)
	
	return issues


## Get summary for debugging
func get_summary() -> Dictionary:
	return {
		"source": source_deck_name,
		"size": get_size(),
		"composition": get_composition_by_type(),
		"energy_curve": get_energy_curve(),
		"statistics": statistics.duplicate(),
		"version": version,
		"last_modified": last_modified
	}


## Clear the deck
func clear() -> void:
	var count := cards.size()
	cards.clear()
	statistics.cards_removed += count
	statistics.total_modifications += count
	_mark_modified()
	emit_changed()
	GLog.debug("RunDeck: Cleared %d cards" % count)


## Private: Mark deck as modified
func _mark_modified() -> void:
	last_modified = Time.get_unix_time_from_system()
	version += 1
