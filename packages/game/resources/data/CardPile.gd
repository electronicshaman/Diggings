extends Resource
class_name CardPile

# CardPile Resource - Generic card collection for hand, deck, discard, and removed piles
# Part of the resource-based architecture migration for better performance and reusability

# Debug toggle for this file - set to false to disable CardPile logging
const DEBUG_ENABLED: bool = true

# Card storage
@export var cards: Array[CardData] = []
@export var pile_type: String = "generic"  # "hand", "deck", "discard", "removed"
@export var max_size: int = -1  # -1 for unlimited

# Change tracking system - since Resources don't have signals, we use a callback system
var _change_listeners: Array[Callable] = []

func _init(type: String = "generic", maximum_size: int = -1) -> void:
	pile_type = type
	max_size = maximum_size
	
	# Example GLog usage - now much cleaner!
	GLog.debug("CardPile created: type=%s, max_size=%s" % [type, maximum_size])

# Add a callback to be notified of pile changes
func add_change_listener(callback: Callable) -> void:
	if callback not in _change_listeners:
		_change_listeners.append(callback)

# Remove a callback from change notifications
func remove_change_listener(callback: Callable) -> void:
	_change_listeners.erase(callback)

# Emit change notification to all listeners
func _emit_change(change_type: String, data: Dictionary = {}) -> void:
	data["pile_type"] = pile_type
	data["pile_size"] = cards.size()
	for callback in _change_listeners:
		callback.call(change_type, data)

# Basic pile operations

# Add a card to the pile, returns true if successful
func add_card(card_data: CardData) -> bool:
	if not card_data:
		GLog.warn("Attempted to add null card to %s pile" % pile_type)
		return false
	
	# Check size limit
	if max_size > 0 and cards.size() >= max_size:
		GLog.warn("Pile %s is full (%d/%d), cannot add card: %s" % [pile_type, cards.size(), max_size, card_data.card_name])
		return false
	
	cards.append(card_data)
	
	# Example of different logging levels - much cleaner now!
	GLog.debug("Added card to %s pile: %s (pile size: %d)" % [pile_type, card_data.card_name, cards.size()])
	
	_emit_change("card_added", {"card": card_data})
	return true

# Add multiple cards to the pile, returns number of cards actually added
func add_cards(card_list: Array[CardData]) -> int:
	var added_count: int = 0
	for card_data in card_list:
		if add_card(card_data):
			added_count += 1
		else:
			break  # Stop if we hit size limit
	return added_count

# Remove a specific card from the pile, returns true if found and removed
func remove_card(card_data: CardData) -> bool:
	var index: int = cards.find(card_data)
	if index >= 0:
		cards.remove_at(index)
		_emit_change("card_removed", {"card": card_data})
		return true
	return false

# Remove card at specific index, returns the removed card or null
func remove_card_at(index: int) -> CardData:
	if index < 0 or index >= cards.size():
		return null
	
	var removed_card: CardData = cards[index]
	cards.remove_at(index)
	_emit_change("card_removed", {"card": removed_card, "index": index})
	return removed_card

# Get card at specific index without removing it
func get_card_at(index: int) -> CardData:
	if index < 0 or index >= cards.size():
		return null
	return cards[index]

# Peek at the top card without removing it
func peek_top() -> CardData:
	if cards.is_empty():
		return null
	return cards[cards.size() - 1]

# Peek at the bottom card without removing it
func peek_bottom() -> CardData:
	if cards.is_empty():
		return null
	return cards[0]

# Draw (remove and return) the top card
func draw_top() -> CardData:
	if cards.is_empty():
		return null
	
	var drawn_card: CardData = cards[cards.size() - 1]
	cards.remove_at(cards.size() - 1)
	_emit_change("card_drawn", {"card": drawn_card, "from": "top"})
	return drawn_card

# Draw (remove and return) the bottom card
func draw_bottom() -> CardData:
	if cards.is_empty():
		return null
	
	var drawn_card: CardData = cards[0]
	cards.remove_at(0)
	_emit_change("card_drawn", {"card": drawn_card, "from": "bottom"})
	return drawn_card

# Draw (remove and return) a random card
func draw_random() -> CardData:
	if cards.is_empty():
		return null
	
	var index: int = randi() % cards.size()
	var drawn_card: CardData = cards[index]
	cards.remove_at(index)
	_emit_change("card_drawn", {"card": drawn_card, "from": "random"})
	return drawn_card

# Pile manipulation

# Shuffle the cards in the pile
func shuffle() -> void:
	if cards.size() <= 1:
		return
	
	# Fisher-Yates shuffle
	for i in range(cards.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var temp: CardData = cards[i]
		cards[i] = cards[j]
		cards[j] = temp
	
	_emit_change("pile_shuffled", {})

# Remove all cards from the pile
func clear() -> void:
	if cards.is_empty():
		return
	
	var old_size: int = cards.size()
	cards.clear()
	_emit_change("pile_cleared", {"old_size": old_size})

# Sort cards by energy cost (ascending)
func sort_by_cost() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: return a.energy_cost < b.energy_cost)
	_emit_change("pile_sorted", {"sort_type": "cost"})

# Sort cards by name (alphabetical)
func sort_by_name() -> void:
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: return a.card_name < b.card_name)
	_emit_change("pile_sorted", {"sort_type": "name"})

# Sort cards by type (Lead, Leather, Liquor, Luck)
func sort_by_type() -> void:
	var type_order: Dictionary = {"Lead": 0, "Leather": 1, "Liquor": 2, "Luck": 3}
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: 
		return type_order.get(a.card_type, 99) < type_order.get(b.card_type, 99)
	)
	_emit_change("pile_sorted", {"sort_type": "type"})

# Bulk operations

# Move all cards from this pile to target pile, returns number moved
func move_all_to(target_pile: CardPile) -> int:
	var moved_count: int = 0
	while not cards.is_empty():
		var card: CardData = draw_top()
		if card and target_pile.add_card(card):
			moved_count += 1
		else:
			# If target pile is full, put card back and stop
			if card:
				add_card(card)
			break
	return moved_count

# Move specified number of cards to target pile, returns number actually moved
func move_cards_to(target_pile: CardPile, count: int) -> int:
	var moved_count: int = 0
	for i in range(count):
		if cards.is_empty():
			break
		
		var card: CardData = draw_top()
		if card and target_pile.add_card(card):
			moved_count += 1
		else:
			# If target pile is full, put card back and stop
			if card:
				add_card(card)
			break
	return moved_count

# Copy all cards to target pile (doesn't remove from this pile), returns number copied
func copy_to(target_pile: CardPile) -> int:
	var copied_count: int = 0
	for card in cards:
		if target_pile.add_card(card):
			copied_count += 1
		else:
			break  # Stop if target pile is full
	return copied_count

# Query operations

# Get the number of cards in the pile
func size() -> int:
	return cards.size()

# Check if the pile is empty
func is_empty() -> bool:
	return cards.is_empty()

# Check if the pile is at maximum capacity
func is_full() -> bool:
	return max_size > 0 and cards.size() >= max_size

# Check if the pile contains a specific card
func has_card(card_data: CardData) -> bool:
	return card_data in cards

# Count cards of a specific type
func count_by_type(card_type: String) -> int:
	var count: int = 0
	for card in cards:
		if card.card_type == card_type:
			count += 1
	return count

# Count cards with specific energy cost
func count_by_cost(cost: int) -> int:
	var count: int = 0
	for card in cards:
		if card.energy_cost == cost:
			count += 1
	return count

# Get all cards of a specific type
func get_cards_by_type(card_type: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards:
		if card.card_type == card_type:
			result.append(card)
	return result

# Get all cards with specific energy cost
func get_cards_by_cost(cost: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards:
		if card.energy_cost == cost:
			result.append(card)
	return result

# Get array of all card names in the pile
func get_card_names() -> Array[String]:
	var names: Array[String] = []
	for card in cards:
		names.append(card.card_name)
	return names

# Serialization support

# Get save data dictionary for serialization
func get_save_data() -> Dictionary:
	var card_paths: Array[String] = []
	for card in cards:
		if card.resource_path:
			card_paths.append(card.resource_path)
	
	return {
		"pile_type": pile_type,
		"max_size": max_size,
		"card_paths": card_paths
	}

# Load pile from save data dictionary
func load_from_data(data: Dictionary) -> void:
	pile_type = data.get("pile_type", pile_type)
	max_size = data.get("max_size", max_size)
	
	# Load cards from paths
	cards.clear()
	var card_paths: Array = data.get("card_paths", [])
	for path: String in card_paths:
		var card_data: CardData = load(path) as CardData
		if card_data:
			cards.append(card_data)

# Debug methods

# Print pile contents for debugging
func print_contents() -> void:
	print("=== %s Pile (%d cards) ===" % [pile_type.capitalize(), cards.size()])
	for i in range(cards.size()):
		print("%d. %s (%s, %d energy)" % [i + 1, cards[i].card_name, cards[i].card_type, cards[i].energy_cost])
	print("========================")
