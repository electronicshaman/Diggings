class_name DeckState
extends Resource

## DeckState Resource
# Persistent storage for the player's deck throughout a run
# Follows Godot's Resource pattern for data-driven architecture

@export var master_deck: Array[CardData] = []
@export var deck_version: int = 1
@export var last_modified: float = 0.0
@export var deck_statistics: Dictionary = {}

func _init():
	last_modified = Time.get_ticks_msec() / 1000.0
	deck_statistics = {
		"cards_added": 0,
		"cards_removed": 0,
		"cards_upgraded": 0,
		"total_modifications": 0
	}

## Get a copy of the deck for read-only access
func get_deck_copy() -> Array[CardData]:
	return master_deck.duplicate()

## Add a card to the deck
func add_card(card: CardData) -> bool:
	if not is_instance_valid(card):
		push_warning("DeckState: Attempted to add invalid card")
		return false
	
	master_deck.append(card)
	deck_statistics.cards_added += 1
	deck_statistics.total_modifications += 1
	_mark_modified()
	emit_changed()
	return true

## Remove a card from the deck by CardData reference
func remove_card(card: CardData) -> bool:
	if not is_instance_valid(card):
		push_warning("DeckState: Attempted to remove invalid card")
		return false
	
	var index = master_deck.find(card)
	if index >= 0:
		master_deck.remove_at(index)
		deck_statistics.cards_removed += 1
		deck_statistics.total_modifications += 1
		_mark_modified()
		emit_changed()
		return true
	
	push_warning("DeckState: Card not found in deck for removal")
	return false

## Remove a card by name (removes first match)
func remove_card_by_name(card_name: String) -> bool:
	if card_name.is_empty():
		push_warning("DeckState: Empty card name provided")
		return false
	
	for i in range(master_deck.size()):
		if master_deck[i] and master_deck[i].card_name == card_name:
			master_deck.remove_at(i)
			deck_statistics.cards_removed += 1
			deck_statistics.total_modifications += 1
			_mark_modified()
			emit_changed()
			return true
	
	push_warning("DeckState: No card with name '%s' found for removal" % card_name)
	return false

## Replace a card with an upgraded version
func upgrade_card(old_card: CardData, new_card: CardData) -> bool:
	if not is_instance_valid(old_card) or not is_instance_valid(new_card):
		push_warning("DeckState: Invalid cards provided for upgrade")
		return false
	
	var index = master_deck.find(old_card)
	if index >= 0:
		master_deck[index] = new_card
		deck_statistics.cards_upgraded += 1
		deck_statistics.total_modifications += 1
		_mark_modified()
		emit_changed()
		return true
	
	push_warning("DeckState: Card not found in deck for upgrade")
	return false

## Clear the entire deck
func clear_deck() -> void:
	var card_count = master_deck.size()
	master_deck.clear()
	deck_statistics.cards_removed += card_count
	deck_statistics.total_modifications += card_count
	_mark_modified()
	emit_changed()

## Initialize deck with an array of cards (for run start)
func initialize_deck(cards: Array[CardData]) -> void:
	master_deck.clear()
	for card in cards:
		if is_instance_valid(card):
			master_deck.append(card)
	
	deck_statistics.cards_added = master_deck.size()
	deck_statistics.total_modifications += 1
	_mark_modified()
	emit_changed()

## Get deck size
func get_deck_size() -> int:
	return master_deck.size()

## Get deck composition by mechanical category
func get_deck_composition() -> Dictionary:
	var composition := {}
	
	for card in master_deck:
		if is_instance_valid(card):
			var category = card.card_type
			if composition.has(category):
				composition[category] += 1
			else:
				composition[category] = 1
	
	return composition

## Get deck composition by card type
func get_deck_by_type() -> Dictionary:
	var by_type := {}
	
	for card in master_deck:
		if is_instance_valid(card):
			var type = card.card_type
			if by_type.has(type):
				by_type[type] += 1
			else:
				by_type[type] = 1
	
	return by_type

## Get energy curve statistics
func get_energy_curve() -> Dictionary:
	var curve := {}
	
	for card in master_deck:
		if is_instance_valid(card):
			var cost = card.energy_cost
			if curve.has(cost):
				curve[cost] += 1
			else:
				curve[cost] = 1
	
	return curve

## Validate deck integrity
func validate_deck() -> Array[String]:
	var issues: Array[String] = []
	
	if master_deck.is_empty():
		issues.append("Deck is empty")
	
	# Check for invalid cards
	var invalid_count = 0
	for card in master_deck:
		if not is_instance_valid(card):
			invalid_count += 1
	
	if invalid_count > 0:
		issues.append("Deck contains %d invalid card(s)" % invalid_count)
	
	# Add other validation rules as needed
	if master_deck.size() < 10:
		issues.append("Deck size below minimum (10 cards)")
	elif master_deck.size() > 50:
		issues.append("Deck size above maximum (50 cards)")
	
	return issues

## Get a summary of the deck for debugging
func get_deck_summary() -> Dictionary:
	return {
		"size": get_deck_size(),
		"composition": get_deck_composition(),
		"by_type": get_deck_by_type(),
		"energy_curve": get_energy_curve(),
		"statistics": deck_statistics.duplicate(),
		"last_modified": last_modified,
		"version": deck_version
	}

## Private method to mark the deck as modified
func _mark_modified() -> void:
	last_modified = Time.get_ticks_msec() / 1000.0
	deck_version += 1
