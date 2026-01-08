extends Resource
class_name EnemyCardManager

## EnemyCardManager - Handles all card-related operations for enemies
## Extracted from EnemyState to follow Single Responsibility Principle
## Manages: deck, hand, discard pile, card drawing, and deck initialization

# Card piles
@export var hand: CardPile
@export var deck: CardPile
@export var discard: CardPile

# Configuration
@export var hand_size_limit: int = 7
@export var cards_per_turn: int = 5

# Deck configuration
@export var deck_data: DeckData

# Change tracking
var _change_listeners: Array[Callable] = []


func _init(hand_limit: int = 7, draw_per_turn: int = 5) -> void:
	hand_size_limit = hand_limit
	cards_per_turn = draw_per_turn
	
	# Initialize card piles
	hand = CardPile.new("enemy_hand", hand_size_limit)
	deck = CardPile.new("enemy_deck")
	discard = CardPile.new("enemy_discard")
	
	# Forward pile change notifications
	hand.add_change_listener(_forward_hand_change)
	deck.add_change_listener(_forward_deck_change)
	discard.add_change_listener(_forward_discard_change)


## Change Listener System

func add_change_listener(callback: Callable) -> void:
	"""Add a callback to be notified of card manager changes"""
	if callback not in _change_listeners:
		_change_listeners.append(callback)


func remove_change_listener(callback: Callable) -> void:
	"""Remove a callback from change notifications"""
	_change_listeners.erase(callback)


func _emit_change(change_type: String, data: Dictionary) -> void:
	"""Emit change notification to all listeners"""
	for callback in _change_listeners:
		callback.call(change_type, data)


func _forward_hand_change(change_type: String, data: Dictionary) -> void:
	"""Forward hand changes to our listeners"""
	_emit_change("hand_" + change_type, data)


func _forward_deck_change(change_type: String, data: Dictionary) -> void:
	"""Forward deck changes to our listeners"""
	_emit_change("deck_" + change_type, data)


func _forward_discard_change(change_type: String, data: Dictionary) -> void:
	"""Forward discard changes to our listeners"""
	_emit_change("discard_" + change_type, data)


## Card Operations

func draw_cards(count: int) -> Array[CardData]:
	"""Draw cards from deck to hand, reshuffling discard if needed"""
	var drawn_cards: Array[CardData] = []
	
	for i in range(count):
		if deck.is_empty():
			# Shuffle discard back into deck
			if not discard.is_empty():
				discard.shuffle()
				discard.move_all_to(deck)
				deck.shuffle()
		
		var card = deck.draw_top()
		if card and hand.add_card(card):
			# Return CardData elements for callers; piles hold CardInstance
			drawn_cards.append(card.card_data)
		else:
			# Hand is full, put card back
			if card:
				deck.add_card(card)
			break
	
	return drawn_cards


func play_card(card_data: CardData) -> void:
	"""Move card from hand to discard"""
	if hand.remove_card_data(card_data):
		discard.add_card_data(card_data)


func discard_card(card_data: CardData) -> void:
	"""Discard a card from hand"""
	if hand.remove_card_data(card_data):
		discard.add_card_data(card_data)


## Deck Initialization

func initialize_from_deck_data(enemy_name: String = "") -> void:
	"""Load deck cards from DeckData resource"""
	if not deck:
		deck = CardPile.new("enemy_deck")
	else:
		deck.clear()
	
	if deck_data:
		GLog.debug("Loading enemy deck from DeckData resource: %s" % deck_data.deck_name)
		var deck_pile = deck_data.to_card_pile(CardInstance.Owner.ENEMY)
		deck_pile.move_all_to(deck)
		GLog.debug("Loaded %d cards from DeckData" % deck.size())
	else:
		GLog.warn("No deck data found for enemy: %s" % enemy_name)


func get_strategy() -> String:
	"""Get enemy's preferred strategy from deck data"""
	if deck_data and deck_data.preferred_strategy:
		return deck_data.preferred_strategy
	return "balanced"


func get_theme() -> String:
	"""Get enemy's deck theme"""
	if deck_data:
		return deck_data.deck_theme
	return "unknown"


func get_difficulty() -> int:
	"""Get enemy's deck difficulty level"""
	if deck_data:
		return deck_data.difficulty_level
	return 1


## State Management

func clear_all() -> void:
	"""Clear all card piles"""
	if hand:
		hand.clear()
	if deck:
		deck.clear()
	if discard:
		discard.clear()


func size() -> int:
	"""Get total number of cards across all piles"""
	var total := 0
	if hand:
		total += hand.size()
	if deck:
		total += deck.size()
	if discard:
		total += discard.size()
	return total


## Serialization

func get_save_data() -> Dictionary:
	return {
		"hand": hand.get_save_data() if hand else {},
		"deck": deck.get_save_data() if deck else {},
		"discard": discard.get_save_data() if discard else {},
		"deck_data_path": deck_data.resource_path if deck_data else "",
		"hand_size_limit": hand_size_limit,
		"cards_per_turn": cards_per_turn
	}


func load_from_data(data: Dictionary) -> void:
	if not hand:
		hand = CardPile.new("enemy_hand", hand_size_limit)
	if not deck:
		deck = CardPile.new("enemy_deck")
	if not discard:
		discard = CardPile.new("enemy_discard")
	
	hand.load_from_data(data.get("hand", {}))
	deck.load_from_data(data.get("deck", {}))
	discard.load_from_data(data.get("discard", {}))
	
	var deck_data_path = data.get("deck_data_path", "")
	if deck_data_path != "":
		deck_data = load(deck_data_path) as DeckData
	
	hand_size_limit = data.get("hand_size_limit", 7)
	cards_per_turn = data.get("cards_per_turn", 5)


## Debug Methods

func print_status(enemy_name: String = "") -> void:
	"""Print current card manager status for debugging"""
	GLog.debug("=== %s Card Manager ===" % enemy_name)
	if deck_data:
		GLog.debug("Deck: %s (%s theme, difficulty %d)" % [deck_data.deck_name, deck_data.deck_theme, deck_data.difficulty_level])
	GLog.debug("Hand: %d cards (limit: %d)" % [hand.size() if hand else 0, hand_size_limit])
	GLog.debug("Deck: %d cards" % (deck.size() if deck else 0))
	GLog.debug("Discard: %d cards" % (discard.size() if discard else 0))
