extends Resource
class_name DuelState

# Debug toggle for this file
const DEBUG_ENABLED: bool = true

# DuelState Resource - Complete duel state container using all our other resources
# This replaces the complex serialization logic in the old system

# Core game entities
@export var player_data: PlayerData
@export var enemy_data: EnemyState

# Card collections
@export var hand: CardPile
@export var deck: CardPile
@export var discard_pile: CardPile
@export var removed_pile: CardPile
@export var battlefield: CardPile

# Duel flow state
@export var current_turn: int = 1
@export var is_player_turn: bool = true
@export var duel_active: bool = false
@export var winner: String = ""

# Turn tracking
@export var player_turn_count: int = 0
@export var enemy_turn_count: int = 0

# Change tracking system
var _change_listeners: Array[Callable] = []

func _init():
	# Initialize all resources if they don't exist
	if not player_data:
		player_data = PlayerData.new()
	
	if not enemy_data:
		enemy_data = EnemyState.new()
	
	if not hand:
		hand = CardPile.new("hand", 10)  # Max 10 cards in hand
	
	if not deck:
		deck = CardPile.new("deck")
	
	if not discard_pile:
		discard_pile = CardPile.new("discard")
	
	if not removed_pile:
		removed_pile = CardPile.new("removed")
	
	if not battlefield:
		battlefield = CardPile.new("battlefield")
	
	# Set up change forwarding
	setup_change_forwarding()

func setup_change_forwarding():
	"""Set up change notification forwarding from all sub-resources"""
	if player_data:
		player_data.add_change_listener(_forward_player_change)
	
	if enemy_data:
		enemy_data.add_change_listener(_forward_enemy_change)
	
	if hand:
		hand.add_change_listener(_forward_hand_change)
	
	if deck:
		deck.add_change_listener(_forward_deck_change)
	
	if discard_pile:
		discard_pile.add_change_listener(_forward_discard_change)
	
	if removed_pile:
		removed_pile.add_change_listener(_forward_removed_change)
	
	if battlefield:
		battlefield.add_change_listener(_forward_battlefield_change)

func add_change_listener(callback: Callable):
	"""Add a callback to be notified of duel state changes"""
	if callback not in _change_listeners:
		_change_listeners.append(callback)

func remove_change_listener(callback: Callable):
	"""Remove a callback from change notifications"""
	_change_listeners.erase(callback)

func _emit_change(change_type: String, data: Dictionary = {}):
	"""Emit change notification to all listeners"""
	data["turn"] = current_turn
	data["is_player_turn"] = is_player_turn
	for callback in _change_listeners:
		callback.call(change_type, data)

# Change forwarding methods
func _forward_player_change(change_type: String, old_value, new_value):
	_emit_change("player_" + change_type, {"old_value": old_value, "new_value": new_value})

func _forward_enemy_change(change_type: String, old_value, new_value):
	_emit_change("enemy_" + change_type, {"old_value": old_value, "new_value": new_value})

func _forward_hand_change(change_type: String, data: Dictionary):
	_emit_change("hand_" + change_type, data)

func _forward_deck_change(change_type: String, data: Dictionary):
	_emit_change("deck_" + change_type, data)

func _forward_discard_change(change_type: String, data: Dictionary):
	_emit_change("discard_" + change_type, data)

func _forward_removed_change(change_type: String, data: Dictionary):
	_emit_change("removed_" + change_type, data)

func _forward_battlefield_change(change_type: String, data: Dictionary):
	_emit_change("battlefield_" + change_type, data)

# Duel flow management
func start_duel():
	"""Initialize duel state"""
	duel_active = true
	current_turn = 1
	is_player_turn = true
	player_turn_count = 0
	enemy_turn_count = 0
	winner = ""
	
	# Reset entities for new duel
	if player_data:
		player_data.reset_duel_tracking()
	
	if enemy_data:
		enemy_data.reset_for_new_duel()
	
	_emit_change("duel_started", {})

func end_duel(winning_side: String):
	"""End the duel with specified winner"""
	duel_active = false
	winner = winning_side
	_emit_change("duel_ended", {"winner": winner})

func start_player_turn():
	"""Start a new player turn"""
	is_player_turn = true
	player_turn_count += 1
	
	if player_data:
		player_data.start_new_turn()
	
	# Draw 5 cards at the start of each turn (except turn 1, which already drew initial hand)
	if player_turn_count > 1:
		var cards_to_draw = 5 - hand.size()  # Draw up to 5 cards
		if cards_to_draw > 0:
			var drawn = draw_cards(cards_to_draw)
			GLog.info("Drew %d cards at start of turn %d" % [drawn.size(), player_turn_count])
	
	_emit_change("player_turn_started", {"turn_count": player_turn_count})

func end_player_turn():
	"""End the current player turn"""
	# Resolve any cards left on battlefield
	resolve_battlefield()
	
	# Discard all non-Keep cards from hand
	discard_non_keep_cards()
	
	if player_data:
		player_data.end_turn()
	
	_emit_change("player_turn_ended", {"turn_count": player_turn_count})

func start_enemy_turn():
	"""Start a new enemy turn"""
	is_player_turn = false
	enemy_turn_count += 1
	current_turn += 1
	
	if enemy_data:
		enemy_data.start_turn()
	
	_emit_change("enemy_turn_started", {"turn_count": enemy_turn_count})

func end_enemy_turn():
	"""End the current enemy turn"""
	if enemy_data:
		enemy_data.end_turn()
	
	_emit_change("enemy_turn_ended", {"turn_count": enemy_turn_count})

# Card pile convenience methods
func draw_cards(count: int) -> Array[CardData]:
	"""Draw cards from deck to hand"""
	var drawn_cards: Array[CardData] = []
	
	for i in range(count):
		if deck.is_empty():
			# Shuffle discard pile back into deck if possible
			if not discard_pile.is_empty():
				discard_pile.shuffle()
				discard_pile.move_all_to(deck)
				deck.shuffle()
		
		var card = deck.draw_top()
		if card and hand.add_card(card):
			drawn_cards.append(card)
		else:
			# Hand is full, put card back
			if card:
				deck.add_card(card)
			break
	
	return drawn_cards

func play_card(card_data: CardData):
	"""Move card from hand to battlefield for staging"""
	if not hand.remove_card(card_data):
		GLog.warn("Tried to play card not in hand: %s" % card_data.card_name)
		return  # Card not in hand
	
	GLog.debug("Playing card '%s' to battlefield" % card_data.card_name)
	
	# All played cards go to battlefield first
	battlefield.add_card(card_data)
	GLog.debug("Card '%s' staged on battlefield" % card_data.card_name)

func resolve_battlefield():
	"""Process all cards on the battlefield and move them to final destinations"""
	GLog.info("Resolving battlefield with %d cards" % battlefield.size())
	
	var cards_to_resolve = battlefield.cards.duplicate()  # Copy to avoid modification during iteration
	
	for card_data in cards_to_resolve:
		# Remove from battlefield first
		battlefield.remove_card(card_data)
		
		# Determine final destination based on card handling
		match card_data.card_handling:
			"Standard", "Equipped", "Flash", "Keep":
				# Most cards go to discard pile after resolution
				discard_pile.add_card(card_data)
				GLog.debug("Card '%s' resolved to discard pile" % card_data.card_name)
			"Oneshot":
				# Oneshot cards are removed from the game
				removed_pile.add_card(card_data)
				GLog.debug("Card '%s' resolved and removed from game (Oneshot)" % card_data.card_name)
			_:
				# Default behavior is to discard
				discard_pile.add_card(card_data)
				GLog.warn("Unknown card handling '%s' for card '%s', defaulting to discard" % [card_data.card_handling, card_data.card_name])
	
	GLog.info("Battlefield resolved, %d cards processed" % cards_to_resolve.size())

func discard_card(card_data: CardData):
	"""Move card from hand to discard pile"""
	if hand.remove_card(card_data):
		discard_pile.add_card(card_data)

func remove_card_from_game(card_data: CardData):
	"""Move card from hand to removed pile"""
	if hand.remove_card(card_data):
		removed_pile.add_card(card_data)

func discard_non_keep_cards():
	"""Discard all cards that don't have Keep handling from hand"""
	var cards_to_discard: Array[CardData] = []
	
	# Check each card in hand to see if it should be discarded
	for card in hand.cards:
		# Check if this card has "Keep" handling
		if card.card_handling != "Keep":
			cards_to_discard.append(card)
	
	# Discard the non-keep cards
	for card in cards_to_discard:
		discard_card(card)
		GLog.debug("Discarding card at end of turn: %s" % card.card_name)
	
	if cards_to_discard.size() > 0:
		GLog.info("Discarded %d cards at end of turn" % cards_to_discard.size())

# State queries
func can_play_cards() -> bool:
	"""Check if cards can be played (player turn and not stunned/dead)"""
	if not duel_active or not is_player_turn:
		return false
	
	if not player_data or player_data.is_dead() or player_data.is_insane():
		return false
	
	return true

func can_end_turn() -> bool:
	"""Check if player can end their turn"""
	return can_play_cards()  # Same conditions for now

func is_duel_over() -> bool:
	"""Check if duel should end"""
	if not duel_active:
		return true
	
	# Check win conditions
	if player_data and (player_data.is_dead() or player_data.is_insane()):
		return true
	
	if enemy_data and enemy_data.is_dead():
		return true
	
	return false

func get_winner() -> String:
	"""Determine the winner if duel is over"""
	if not is_duel_over():
		return ""
	
	if player_data and (player_data.is_dead() or player_data.is_insane()):
		return "enemy"
	
	if enemy_data and enemy_data.is_dead():
		return "player"
	
	return "draw"  # Shouldn't happen but just in case

# Serialization support
func get_save_data() -> Dictionary:
	return {
		"player_data": player_data.get_save_data() if player_data else {},
		"enemy_data": enemy_data.get_save_data() if enemy_data else {},
		"hand": hand.get_save_data() if hand else {},
		"deck": deck.get_save_data() if deck else {},
		"discard_pile": discard_pile.get_save_data() if discard_pile else {},
		"battlefield": battlefield.get_save_data() if battlefield else {},
		"removed_pile": removed_pile.get_save_data() if removed_pile else {},
		"current_turn": current_turn,
		"is_player_turn": is_player_turn,
		"duel_active": duel_active,
		"winner": winner,
		"player_turn_count": player_turn_count,
		"enemy_turn_count": enemy_turn_count
	}

func load_from_data(data: Dictionary):
	"""Load duel state from save data"""
	# Initialize resources if needed
	if not player_data:
		player_data = PlayerData.new()
	if not enemy_data:
		enemy_data = EnemyState.new()
	if not hand:
		hand = CardPile.new("hand", 10)
	if not deck:
		deck = CardPile.new("deck")
	if not discard_pile:
		discard_pile = CardPile.new("discard")
	if not battlefield:
		battlefield = CardPile.new("battlefield")
	if not removed_pile:
		removed_pile = CardPile.new("removed")
	
	# Load all sub-resources
	player_data.load_from_data(data.get("player_data", {}))
	enemy_data.load_from_data(data.get("enemy_data", {}))
	hand.load_from_data(data.get("hand", {}))
	deck.load_from_data(data.get("deck", {}))
	discard_pile.load_from_data(data.get("discard_pile", {}))
	battlefield.load_from_data(data.get("battlefield", {}))
	removed_pile.load_from_data(data.get("removed_pile", {}))
	
	# Load duel state
	current_turn = data.get("current_turn", 1)
	is_player_turn = data.get("is_player_turn", true)
	duel_active = data.get("duel_active", false)
	winner = data.get("winner", "")
	player_turn_count = data.get("player_turn_count", 0)
	enemy_turn_count = data.get("enemy_turn_count", 0)
	
	# Re-setup change forwarding
	setup_change_forwarding()

# Debug methods
func print_status():
	"""Print complete duel status for debugging"""
	GLog.debug("=== DUEL STATE ===")
	GLog.debug("Turn %d (%s turn)" % [current_turn, "Player" if is_player_turn else "Enemy"])
	GLog.debug("Active: %s, Winner: %s" % [duel_active, winner if winner else "None"])
	
	if player_data:
		GLog.debug("\n--- PLAYER ---")
		player_data.print_status()
	
	if enemy_data:
		GLog.debug("\n--- ENEMY ---")
		enemy_data.print_status()
	
	GLog.debug("\n--- CARD PILES ---")
	GLog.debug("Hand: %d cards" % (hand.size() if hand else 0))
	GLog.debug("Deck: %d cards" % (deck.size() if deck else 0))
	GLog.debug("Discard: %d cards" % (discard_pile.size() if discard_pile else 0))
	GLog.debug("Battlefield: %d cards" % (battlefield.size() if battlefield else 0))
	GLog.debug("Removed: %d cards" % (removed_pile.size() if removed_pile else 0))
	GLog.debug("==================")

# Convenience accessors for backwards compatibility
func get_player_state() -> PlayerData:
	return player_data

func get_enemy_state() -> EnemyState:
	return enemy_data

func get_hand() -> CardPile:
	return hand

func get_deck() -> CardPile:
	return deck

func get_discard_pile() -> CardPile:
	return discard_pile

func get_battlefield() -> CardPile:
	return battlefield

func get_removed_pile() -> CardPile:
	return removed_pile
