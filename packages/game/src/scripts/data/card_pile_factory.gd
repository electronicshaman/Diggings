extends RefCounted
class_name CardPileFactory

## CardPileFactory
## Factory for creating CardPile instances from various sources.
## Follows Single Responsibility Principle - pile creation logic is centralized here.


## Create a CardPile from a RunDeck
static func create_from_run_deck(run_deck: RunDeck, owner = null) -> CardPile:
	if not is_instance_valid(run_deck):
		push_error("CardPileFactory: Cannot create pile from invalid RunDeck")
		return null
	
	var pile := CardPile.new("deck")
	
	for card_data in run_deck.cards:
		if is_instance_valid(card_data):
			pile.add_card_data(card_data, owner)
		else:
			push_warning("CardPileFactory: Skipping invalid CardData in RunDeck")
	
	GLog.debug("CardPileFactory: Created pile with %d cards from RunDeck '%s'" % [
		pile.get_count(), run_deck.source_deck_name
	])
	return pile


## Create a CardPile from a DeckData template (for backwards compatibility)
static func create_from_deck_data(deck_data: DeckData, owner = null) -> CardPile:
	if not is_instance_valid(deck_data):
		push_error("CardPileFactory: Cannot create pile from invalid DeckData")
		return null
	
	var pile := CardPile.new("deck")
	
	for card_path in deck_data.card_paths:
		if ResourceLoader.exists(card_path):
			var card_data := load(card_path) as CardData
			if card_data:
				pile.add_card_data(card_data, owner)
			else:
				push_warning("CardPileFactory: Failed to load card: %s" % card_path)
		else:
			push_warning("CardPileFactory: Card path does not exist: %s" % card_path)
	
	GLog.debug("CardPileFactory: Created pile with %d cards from DeckData '%s'" % [
		pile.get_count(), deck_data.deck_name
	])
	return pile


## Create a CardPile from an array of CardData
static func create_from_card_array(cards: Array[CardData], pile_type: String = "deck", owner = null) -> CardPile:
	var pile := CardPile.new(pile_type)
	
	for card_data in cards:
		if is_instance_valid(card_data):
			pile.add_card_data(card_data, owner)
		else:
			push_warning("CardPileFactory: Skipping invalid CardData in array")
	
	GLog.debug("CardPileFactory: Created %s pile with %d cards" % [pile_type, pile.get_count()])
	return pile


## Create an empty CardPile of specified type
static func create_empty(pile_type: String = "deck") -> CardPile:
	var pile := CardPile.new(pile_type)
	GLog.debug("CardPileFactory: Created empty %s pile" % pile_type)
	return pile
