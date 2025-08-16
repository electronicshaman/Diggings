extends Resource
class_name CardPile

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED = true

# CardPile Resource - Generic card collection for hand, deck, discard, and removed piles
# Part of the resource-based architecture migration for better performance and reusability

# Card storage
@export var cards: Array[CardInstance] = []
@export var pile_type: String = "generic"  # "hand", "deck", "discard", "removed"
@export var max_size: int = -1  # -1 for unlimited

# Change tracking system - since Resources don't have signals, we use a callback system
var _change_listeners: Array[Callable] = []

func _init(type: String = "generic", maximum_size: int = -1) -> void:
	GLog.debug("Initializing pile: type='%s', max_size=%d" % [type, maximum_size])
	pile_type = type
	max_size = maximum_size
	GLog.debug("Pile initialized: %s" % pile_type)

# Add a callback to be notified of pile changes
func add_change_listener(callback: Callable) -> void:
	GLog.debug("Adding change listener to %s pile" % pile_type)
	if callback not in _change_listeners:
		_change_listeners.append(callback)
		GLog.debug("Change listener added. Total listeners: %d" % _change_listeners.size())
	else:
		GLog.debug("Change listener already exists, not adding duplicate")

# Remove a callback from change notifications
func remove_change_listener(callback: Callable) -> void:
	GLog.debug("Removing change listener from %s pile" % pile_type)
	var old_size = _change_listeners.size()
	_change_listeners.erase(callback)
	GLog.debug("Change listener removed. Listeners: %d -> %d" % [old_size, _change_listeners.size()])

# Emit change notification to all listeners
func _emit_change(change_type: String, data: Dictionary = {}) -> void:
	GLog.trace("Emitting change '%s' for %s pile to %d listeners" % [change_type, pile_type, _change_listeners.size()])
	data["pile_type"] = pile_type
	data["pile_size"] = cards.size()
	GLog.trace("Change data: %s" % str(data))
	for callback in _change_listeners:
		GLog.trace("Calling listener callback...")
		callback.call(change_type, data)

# Basic pile operations

# Add a card to the pile, returns true if successful
func add_card(card_instance: CardInstance) -> bool:
	GLog.debug("add_card() called on %s pile" % pile_type)
	if not card_instance:
		GLog.error("Attempted to add null card")
		return false
	
	GLog.debug("Adding card: '%s' (type: %s, cost: %d)" % [card_instance.get_card_name(), card_instance.get_card_type(), card_instance.get_energy_cost()])
	GLog.trace("Current pile size: %d, max_size: %d" % [cards.size(), max_size])
	
	# Check size limit
	if max_size > 0 and cards.size() >= max_size:
		GLog.warn("Pile is full, cannot add card")
		return false
	
	cards.append(card_instance)
	GLog.debug("Card added successfully. New pile size: %d" % cards.size())
	_emit_change("card_added", {"card": card_instance})
	return true

# Add multiple cards to the pile, returns number of cards actually added
func add_cards(card_list: Array[CardInstance]) -> int:
	GLog.debug("add_cards() called with %d cards for %s pile" % [card_list.size(), pile_type])
	var added_count: int = 0
	for i in range(card_list.size()):
		var card_instance = card_list[i]
		GLog.trace("Adding card %d/%d: '%s'" % [i + 1, card_list.size(), card_instance.get_card_name() if card_instance else "null"])
		if add_card(card_instance):
			added_count += 1
		else:
			GLog.debug("Failed to add card, stopping bulk add")
			break  # Stop if we hit size limit
	GLog.debug("add_cards() completed: %d/%d cards added" % [added_count, card_list.size()])
	return added_count

# Remove a specific card from the pile, returns true if found and removed
func remove_card(card_instance: CardInstance) -> bool:
	GLog.debug("remove_card() called for '%s' from %s pile" % [card_instance.get_card_name() if card_instance else "null", pile_type])
	var index: int = cards.find(card_instance)
	GLog.trace("Card found at index: %d" % index)
	if index >= 0:
		cards.remove_at(index)
		GLog.debug("Card removed successfully. New pile size: %d" % cards.size())
		_emit_change("card_removed", {"card": card_instance})
		return true
	GLog.debug("Card not found in pile")
	return false

# Remove card at specific index, returns the removed card or null
func remove_card_at(index: int) -> CardInstance:
	GLog.debug("remove_card_at() called with index %d for %s pile (size: %d)" % [index, pile_type, cards.size()])
	if index < 0 or index >= cards.size():
		GLog.error("Index out of bounds")
		return null
	
	var removed_card: CardInstance = cards[index]
	GLog.debug("Removing card: '%s'" % removed_card.get_card_name())
	cards.remove_at(index)
	GLog.debug("Card removed successfully. New pile size: %d" % cards.size())
	_emit_change("card_removed", {"card": removed_card, "index": index})
	return removed_card

# Get card at specific index without removing it
func get_card_at(index: int) -> CardInstance:
	GLog.trace("get_card_at() called with index %d for %s pile (size: %d)" % [index, pile_type, cards.size()])
	if index < 0 or index >= cards.size():
		GLog.error("Index out of bounds")
		return null
	var card = cards[index]
	GLog.trace("Retrieved card: '%s'" % card.get_card_name())
	return card

# Peek at the top card without removing it
func peek_top() -> CardInstance:
	GLog.trace("peek_top() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.trace("Pile is empty, returning null")
		return null
	var card = cards[cards.size() - 1]
	GLog.trace("Top card: '%s'" % card.get_card_name())
	return card

# Peek at the bottom card without removing it
func peek_bottom() -> CardInstance:
	GLog.trace("peek_bottom() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.trace("Pile is empty, returning null")
		return null
	var card = cards[0]
	GLog.trace("Bottom card: '%s'" % card.get_card_name())
	return card

# Draw (remove and return) the top card
func draw_top() -> CardInstance:
	GLog.debug("draw_top() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.warn("Pile is empty, cannot draw")
		return null
	
	var drawn_card: CardInstance = cards[cards.size() - 1]
	GLog.debug("Drawing top card: '%s'" % drawn_card.get_card_name())
	cards.remove_at(cards.size() - 1)
	GLog.debug("Card drawn successfully. New pile size: %d" % cards.size())
	_emit_change("card_drawn", {"card": drawn_card, "from": "top"})
	return drawn_card

# Draw (remove and return) the bottom card
func draw_bottom() -> CardInstance:
	GLog.debug("draw_bottom() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.warn("Pile is empty, cannot draw")
		return null
	
	var drawn_card: CardInstance = cards[0]
	GLog.debug("Drawing bottom card: '%s'" % drawn_card.get_card_name())
	cards.remove_at(0)
	GLog.debug("Card drawn successfully. New pile size: %d" % cards.size())
	_emit_change("card_drawn", {"card": drawn_card, "from": "bottom"})
	return drawn_card

# Draw (remove and return) a random card
func draw_random() -> CardInstance:
	GLog.debug("draw_random() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.warn("Pile is empty, cannot draw")
		return null
	
	var index: int = randi() % cards.size()
	var drawn_card: CardInstance = cards[index]
	GLog.debug("Drawing random card at index %d: '%s'" % [index, drawn_card.get_card_name()])
	cards.remove_at(index)
	GLog.debug("Card drawn successfully. New pile size: %d" % cards.size())
	_emit_change("card_drawn", {"card": drawn_card, "from": "random"})
	return drawn_card

# Pile manipulation

# Shuffle the cards in the pile
func shuffle() -> void:
	GLog.debug("shuffle() called for %s pile (size: %d)" % [pile_type, cards.size()])
	if cards.size() <= 1:
		GLog.debug("Pile has %d cards, no shuffle needed" % cards.size())
		return
	
	GLog.trace("Shuffling pile using Fisher-Yates algorithm...")
	# Fisher-Yates shuffle
	for i in range(cards.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var temp: CardInstance = cards[i]
		cards[i] = cards[j]
		cards[j] = temp
	
	GLog.debug("Pile shuffled successfully")
	_emit_change("pile_shuffled", {})

# Remove all cards from the pile
func clear() -> void:
	GLog.debug("clear() called for %s pile (current size: %d)" % [pile_type, cards.size()])
	if cards.is_empty():
		GLog.debug("Pile already empty, nothing to clear")
		return
	
	var old_size: int = cards.size()
	cards.clear()
	GLog.debug("Pile cleared: %d -> 0 cards" % old_size)
	_emit_change("pile_cleared", {"old_size": old_size})

# Sort cards by energy cost (ascending)
func sort_by_cost() -> void:
	GLog.debug("sort_by_cost() called for %s pile (size: %d)" % [pile_type, cards.size()])
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.get_energy_cost() < b.get_energy_cost())
	GLog.debug("Pile sorted by cost")
	_emit_change("pile_sorted", {"sort_type": "cost"})

# Sort cards by name (alphabetical)
func sort_by_name() -> void:
	GLog.debug("sort_by_name() called for %s pile (size: %d)" % [pile_type, cards.size()])
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: return a.get_card_name() < b.get_card_name())
	GLog.debug("Pile sorted by name")
	_emit_change("pile_sorted", {"sort_type": "name"})

# Sort cards by type (Lead, Leather, Liquor, Luck)
func sort_by_type() -> void:
	GLog.debug("sort_by_type() called for %s pile (size: %d)" % [pile_type, cards.size()])
	var type_order: Dictionary = {"Lead": 0, "Leather": 1, "Liquor": 2, "Luck": 3}
	cards.sort_custom(func(a: CardInstance, b: CardInstance) -> bool: 
		return type_order.get(a.get_card_type(), 99) < type_order.get(b.get_card_type(), 99)
	)
	GLog.debug("Pile sorted by type")
	_emit_change("pile_sorted", {"sort_type": "type"})

# Bulk operations

# Move all cards from this pile to target pile, returns number moved
func move_all_to(target_pile: CardPile) -> int:
	GLog.debug("move_all_to() called: %s -> %s (%d cards to move)" % [pile_type, target_pile.pile_type, cards.size()])
	var moved_count: int = 0
	var initial_size = cards.size()
	while not cards.is_empty():
		var card: CardInstance = draw_top()
		if card and target_pile.add_card(card):
			moved_count += 1
			GLog.trace("Moved card %d/%d: '%s'" % [moved_count, initial_size, card.card_name])
		else:
			# If target pile is full, put card back and stop
			if card:
				add_card(card)
				GLog.warn("Target pile full, putting card back and stopping")
			break
	GLog.debug("move_all_to() completed: %d cards moved" % moved_count)
	return moved_count

# Move specified number of cards to target pile, returns number actually moved
func move_cards_to(target_pile: CardPile, count: int) -> int:
	GLog.debug("move_cards_to() called: %s -> %s (%d cards requested)" % [pile_type, target_pile.pile_type, count])
	var moved_count: int = 0
	for i in range(count):
		if cards.is_empty():
			GLog.debug("Source pile empty, stopping at %d cards moved" % moved_count)
			break
		
		var card: CardInstance = draw_top()
		if card and target_pile.add_card(card):
			moved_count += 1
			GLog.trace("Moved card %d/%d: '%s'" % [moved_count, count, card.card_name])
		else:
			# If target pile is full, put card back and stop
			if card:
				add_card(card)
				GLog.warn("Target pile full, putting card back and stopping")
			break
	GLog.debug("move_cards_to() completed: %d/%d cards moved" % [moved_count, count])
	return moved_count

# Copy all cards to target pile (doesn't remove from this pile), returns number copied
func copy_to(target_pile: CardPile) -> int:
	GLog.debug("copy_to() called: %s -> %s (%d cards to copy)" % [pile_type, target_pile.pile_type, cards.size()])
	var copied_count: int = 0
	for i in range(cards.size()):
		var card = cards[i]
		if target_pile.add_card(card):
			copied_count += 1
			GLog.trace("Copied card %d/%d: '%s'" % [copied_count, cards.size(), card.card_name])
		else:
			GLog.warn("Target pile full, stopping copy operation")
			break  # Stop if target pile is full
	GLog.debug("copy_to() completed: %d/%d cards copied" % [copied_count, cards.size()])
	return copied_count

# Query operations

# Get the number of cards in the pile
func size() -> int:
	var pile_size = cards.size()
	GLog.trace("size() called for %s pile: %d cards" % [pile_type, pile_size])
	return pile_size

# Check if the pile is empty
func is_empty() -> bool:
	var empty = cards.is_empty()
	GLog.trace("is_empty() called for %s pile: %s" % [pile_type, "true" if empty else "false"])
	return empty

# Check if the pile is at maximum capacity
func is_full() -> bool:
	var full = max_size > 0 and cards.size() >= max_size
	GLog.trace("is_full() called for %s pile: %s (size: %d, max: %d)" % [pile_type, "true" if full else "false", cards.size(), max_size])
	return full

# Check if the pile contains a specific card
func has_card(card_instance: CardInstance) -> bool:
	var contains = card_instance in cards
	GLog.trace("has_card() called for '%s' in %s pile: %s" % [card_instance.get_card_name() if card_instance else "null", pile_type, "true" if contains else "false"])
	return contains

# Count cards of a specific type
func count_by_type(card_type: String) -> int:
	GLog.trace("count_by_type() called for type '%s' in %s pile" % [card_type, pile_type])
	var count: int = 0
	for card in cards:
		if card.get_card_type() == card_type:
			count += 1
	GLog.trace("Found %d cards of type '%s'" % [count, card_type])
	return count

# Count cards with specific energy cost
func count_by_cost(cost: int) -> int:
	GLog.trace("count_by_cost() called for cost %d in %s pile" % [cost, pile_type])
	var count: int = 0
	for card in cards:
		if card.get_energy_cost() == cost:
			count += 1
	GLog.trace("Found %d cards with cost %d" % [count, cost])
	return count

# Get all cards of a specific type
func get_cards_by_type(card_type: String) -> Array[CardInstance]:
	GLog.trace("get_cards_by_type() called for type '%s' in %s pile" % [card_type, pile_type])
	var result: Array[CardInstance] = []
	for card in cards:
		if card.get_card_type() == card_type:
			result.append(card)
	GLog.trace("Found %d cards of type '%s'" % [result.size(), card_type])
	return result

# Get all cards with specific energy cost
func get_cards_by_cost(cost: int) -> Array[CardInstance]:
	GLog.trace("get_cards_by_cost() called for cost %d in %s pile" % [cost, pile_type])
	var result: Array[CardInstance] = []
	for card in cards:
		if card.get_energy_cost() == cost:
			result.append(card)
	GLog.trace("Found %d cards with cost %d" % [result.size(), cost])
	return result

# Get array of all card names in the pile
func get_card_names() -> Array[String]:
	GLog.trace("get_card_names() called for %s pile" % pile_type)
	var names: Array[String] = []
	for card in cards:
		names.append(card.get_card_name())
	GLog.trace("Retrieved %d card names" % names.size())
	return names

# Serialization support

# Get save data dictionary for serialization
func get_save_data() -> Dictionary:
	GLog.debug("get_save_data() called for %s pile" % pile_type)
	var card_data_list: Array[Dictionary] = []
	for card in cards:
		card_data_list.append(card.get_save_data())
	
	var save_data = {
		"pile_type": pile_type,
		"max_size": max_size,
		"card_instances": card_data_list
	}
	GLog.debug("Save data prepared: %d cards, type='%s'" % [card_data_list.size(), pile_type])
	return save_data

# Load pile from save data dictionary
func load_from_data(data: Dictionary) -> void:
	GLog.debug("load_from_data() called")
	GLog.trace("Loading data: %s" % str(data))
	pile_type = data.get("pile_type", pile_type)
	max_size = data.get("max_size", max_size)
	
	# Load card instances from save data
	cards.clear()
	var card_instances_data: Array = data.get("card_instances", [])
	GLog.debug("Loading %d card instances..." % card_instances_data.size())
	var loaded_count = 0
	for instance_data in card_instances_data:
		var card_instance = CardInstance.new()
		card_instance.load_from_save_data(instance_data)
		if card_instance.card_data:
			cards.append(card_instance)
			loaded_count += 1
			GLog.trace("Loaded card instance %d/%d: '%s'" % [loaded_count, card_instances_data.size(), card_instance.get_card_name()])
		else:
			GLog.error("Failed to load card instance: %s" % str(instance_data))
	GLog.debug("Load completed: %d/%d card instances loaded successfully" % [loaded_count, card_instances_data.size()])

# Debug methods

# Print pile contents for debugging
func print_contents() -> void:
	GLog.info("=== %s Pile (%d cards) ===" % [pile_type.capitalize(), cards.size()])
	for i in range(cards.size()):
		GLog.info("%d. %s (%s, %d energy, held: %d)" % [i + 1, cards[i].get_card_name(), cards[i].get_card_type(), cards[i].get_energy_cost(), cards[i].turns_held])
	GLog.info("========================")

# Utility methods for compatibility with existing CardData-based code

# Create and add a CardInstance from CardData
func add_card_data(card_data: CardData) -> bool:
	if not card_data:
		return false
	var card_instance = CardInstance.new(card_data)
	return add_card(card_instance)

# Create and add multiple CardInstances from CardData array
func add_card_data_array(card_data_array: Array[CardData]) -> int:
	var added_count = 0
	for card_data in card_data_array:
		if add_card_data(card_data):
			added_count += 1
	return added_count

# Get all CardData references (for compatibility)
func get_card_data_array() -> Array[CardData]:
	var result: Array[CardData] = []
	for card_instance in cards:
		result.append(card_instance.card_data)
	return result

# Find a CardInstance by its underlying CardData (compatibility helper)
func find_instance_by_card_data(card_data: CardData) -> CardInstance:
	if not card_data:
		return null
	for inst in cards:
		if inst and inst.card_data == card_data:
			return inst
		# Fallback: match by resource path if references differ
		if inst and inst.card_data and card_data and inst.card_data.resource_path == card_data.resource_path and card_data.resource_path != "":
			return inst
	return null

# Remove by CardData for legacy call sites
func remove_card_data(card_data: CardData) -> bool:
	var inst := find_instance_by_card_data(card_data)
	if inst:
		return remove_card(inst)
	return false
