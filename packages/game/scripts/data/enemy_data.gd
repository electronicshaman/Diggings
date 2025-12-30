extends Resource
class_name EnemyState

const DEBUG_ENABLED: bool = true

# EnemyState Resource - Enemy state using Stats resource
# Simpler than PlayerData, focused on combat stats and AI state

# Core stats using our Stats resource
@export var stats: Stats

# Card collections for enemy dueling
@export var enemy_hand: CardPile
@export var enemy_deck: CardPile
@export var enemy_discard: CardPile

# Enemy identification
@export var enemy_name: String = ""
@export var description: String = ""

# Enemy tier (for rewards and difficulty)
@export var is_boss: bool = false
@export var is_elite: bool = false

# AI and combat state
@export var stun_turns_remaining: int = 0
@export var current_pattern_index: int = 0
@export var turns_alive: int = 0

# Enemy intent system
@export var current_intent: String = "Unknown"  # Attack, Defend, Special, Unknown
@export var intent_value: int = 0  # Damage amount, defense amount, etc.
@export var intent_revealed: bool = false

# Enemy-specific modifiers
@export var damage_modifier: float = 1.0
@export var defense_modifier: float = 1.0

# Enemy deck configuration
@export var enemy_deck_data: DeckData  # Deck resource containing cards and strategy info
@export var enemy_deck_paths: Array[String] = []  # DEPRECATED: Legacy card paths (use enemy_deck_data instead)
@export var ai_type: String = "aggressive"  # aggressive, defensive, balanced, cunning
@export var hand_size_limit: int = 7
@export var cards_per_turn: int = 5  # Cards to draw each turn

# Memory system for tracking player patterns
@export var player_card_history: Array[String] = []  # Track last N cards played by player
@export var player_pattern_memory_size: int = 3

# Change tracking system
var _change_listeners: Array[Callable] = []

func _init():
	# Initialize with default stats if none provided
	if not stats:
		stats = Stats.new()
		if DEBUG_ENABLED:
			GLog.debug("EnemyState._init(): Created new default Stats")
	else:
		if DEBUG_ENABLED:
			GLog.debug("EnemyState._init(): Using existing Stats - HP: %d/%d" % [stats.current_health, stats.max_health])
	
	# Initialize card piles
	if not enemy_hand:
		enemy_hand = CardPile.new("enemy_hand", hand_size_limit)
	
	if not enemy_deck:
		enemy_deck = CardPile.new("enemy_deck")
	
	if not enemy_discard:
		enemy_discard = CardPile.new("enemy_discard")
	
	# Forward stats change notifications
	stats.add_change_listener(_forward_stats_change)
	
	# Forward card pile change notifications
	enemy_hand.add_change_listener(_forward_hand_change)
	enemy_deck.add_change_listener(_forward_deck_change)
	enemy_discard.add_change_listener(_forward_discard_change)

func add_change_listener(callback: Callable):
	"""Add a callback to be notified of enemy data changes"""
	if callback not in _change_listeners:
		_change_listeners.append(callback)

func remove_change_listener(callback: Callable):
	"""Remove a callback from change notifications"""
	_change_listeners.erase(callback)

func _emit_change(change_type: String, old_value = null, new_value = null):
	"""Emit change notification to all listeners"""
	for callback in _change_listeners:
		callback.call(change_type, old_value, new_value)

func _forward_stats_change(change_type: String, old_value, new_value):
	"""Forward stats changes to our listeners"""
	_emit_change(change_type, old_value, new_value)

func _forward_hand_change(change_type: String, data: Dictionary):
	"""Forward hand changes to our listeners"""
	_emit_change("enemy_hand_" + change_type, null, data)

func _forward_deck_change(change_type: String, data: Dictionary):
	"""Forward deck changes to our listeners"""
	_emit_change("enemy_deck_" + change_type, null, data)

func _forward_discard_change(change_type: String, data: Dictionary):
	"""Forward discard changes to our listeners"""
	_emit_change("enemy_discard_" + change_type, null, data)

# Stats convenience methods (forward to Stats resource)
func is_alive() -> bool:
	return stats.is_alive()

func is_dead() -> bool:
	return stats.is_dead()

func take_damage(amount: int, ignore_defense: bool = false) -> int:
	"""Take damage with enemy-specific modifiers"""
	var modified_amount = int(amount * defense_modifier)
	
	if ignore_defense:
		# Bypass defense system
		var old_defense = stats.defense
		stats.defense = 0
		var damage_taken = stats.take_damage(modified_amount)
		stats.defense = old_defense  # Restore defense after damage
		return damage_taken
	else:
		return stats.take_damage(modified_amount)

func heal(amount: int):
	stats.heal(amount)

func gain_defense(amount: int):
	stats.gain_defense(amount)

func lose_defense(amount: int):
	stats.lose_defense(amount)

# Stun management
func apply_stun(turns: int):
	"""Apply stun effect"""
	var old_stun = stun_turns_remaining
	stun_turns_remaining = max(stun_turns_remaining, turns)  # Take highest stun value
	_emit_change("stun_applied", old_stun, stun_turns_remaining)

func apply_direct_stun(turns: int):
	"""Apply stun effect directly (adds to existing stun)"""
	var old_stun = stun_turns_remaining
	stun_turns_remaining += turns
	_emit_change("stun_applied", old_stun, stun_turns_remaining)

func reduce_stun():
	"""Reduce stun by 1 turn (called at start of enemy turn)"""
	if stun_turns_remaining > 0:
		var old_stun = stun_turns_remaining
		stun_turns_remaining -= 1
		_emit_change("stun_reduced", old_stun, stun_turns_remaining)

func is_stunned() -> bool:
	"""Check if enemy is currently stunned"""
	return stun_turns_remaining > 0

# AI pattern management
func advance_pattern():
	"""Move to next pattern in sequence"""
	var old_index = current_pattern_index
	current_pattern_index += 1
	_emit_change("pattern_advanced", old_index, current_pattern_index)

func set_pattern_index(index: int):
	"""Set specific pattern index"""
	var old_index = current_pattern_index
	current_pattern_index = index
	_emit_change("pattern_set", old_index, current_pattern_index)

func get_pattern_index() -> int:
	"""Get current pattern index"""
	return current_pattern_index

# Turn management
func start_turn():
	"""Called at the start of enemy turn"""
	turns_alive += 1
	reduce_stun()
	_emit_change("turn_started", turns_alive - 1, turns_alive)

func end_turn():
	"""Called at the end of enemy turn"""
	_emit_change("turn_ended", null, null)

# Enemy-specific modifiers
func set_damage_modifier(modifier: float):
	"""Set damage output modifier"""
	var old_modifier = damage_modifier
	damage_modifier = modifier
	_emit_change("damage_modifier_changed", old_modifier, damage_modifier)

func set_defense_modifier(modifier: float):
	"""Set damage resistance modifier"""
	var old_modifier = defense_modifier
	defense_modifier = modifier
	_emit_change("defense_modifier_changed", old_modifier, defense_modifier)

func get_modified_damage(base_damage: int) -> int:
	"""Calculate damage output with modifier"""
	return int(base_damage * damage_modifier)

# Intent management
func set_intent(intent_type: String, value: int = 0):
	"""Set enemy's current intent"""
	var old_intent = current_intent
	current_intent = intent_type
	intent_value = value
	intent_revealed = false  # Reset revealed status when intent changes
	_emit_change("intent_set", old_intent, current_intent)

func reveal_intent():
	"""Reveal the enemy's current intent to the player"""
	if not intent_revealed:
		intent_revealed = true
		_emit_change("intent_revealed", false, true)

func get_intent_display() -> String:
	"""Get formatted intent string for display"""
	if not intent_revealed:
		return "Unknown"
	
	match current_intent:
		"Attack":
			return "Attack (%d)" % intent_value
		"Defend":
			return "Defend (%d)" % intent_value
		"Special":
			return "Special"
		_:
			return current_intent

func is_intent_attack() -> bool:
	"""Check if current intent is an attack"""
	return current_intent == "Attack"

func is_intent_defend() -> bool:
	"""Check if current intent is defend"""
	return current_intent == "Defend"

func is_intent_revealed() -> bool:
	"""Check if intent has been revealed to player"""
	return intent_revealed

# Convenience property accessors for compatibility
var current_health: int:
	get: return stats.current_health if stats else 0
	set(value): if stats: stats.current_health = value

var max_health: int:
	get: return stats.max_health if stats else 0
	set(value): if stats: stats.max_health = value

var defense: int:
	get: return stats.defense if stats else 0
	set(value): if stats: stats.defense = value

func get_health_percentage() -> float:
	return stats.get_health_percentage() if stats else 0.0

# Reset methods
func reset_for_new_duel():
	"""Reset enemy state for a new duel"""
	if stats:
		stats.reset_to_max()
	stun_turns_remaining = 0
	current_pattern_index = 0
	turns_alive = 0
	damage_modifier = 1.0
	defense_modifier = 1.0
	
	# Clear card piles
	if enemy_hand:
		enemy_hand.clear()
	if enemy_deck:
		enemy_deck.clear()
	if enemy_discard:
		enemy_discard.clear()
	
	# Clear player pattern memory
	player_card_history.clear()

# Card management methods
func draw_cards(count: int) -> Array[CardData]:
	"""Draw cards from deck to hand"""
	var drawn_cards: Array[CardData] = []
	
	for i in range(count):
		if enemy_deck.is_empty():
			# Shuffle discard back into deck
			if not enemy_discard.is_empty():
				enemy_discard.shuffle()
				enemy_discard.move_all_to(enemy_deck)
				enemy_deck.shuffle()
		
		var card = enemy_deck.draw_top()
		if card and enemy_hand.add_card(card):
			# Return CardData elements for callers; piles hold CardInstance
			drawn_cards.append(card.card_data)
		else:
			# Hand is full, put card back
			if card:
				enemy_deck.add_card(card)
			break
	
	return drawn_cards

func play_card(card_data: CardData):
	"""Move card from hand to discard"""
	if enemy_hand.remove_card_data(card_data):
		enemy_discard.add_card_data(card_data)

func discard_card(card_data: CardData):
	"""Discard a card from hand"""
	if enemy_hand.remove_card_data(card_data):
		enemy_discard.add_card_data(card_data)

func add_to_player_memory(card_name: String):
	"""Track cards played by the player"""
	player_card_history.append(card_name)
	if player_card_history.size() > player_pattern_memory_size:
		player_card_history.pop_front()

func get_player_most_played_card() -> String:
	"""Get the most frequently played card by player from memory"""
	if player_card_history.is_empty():
		return ""
	
	var card_counts = {}
	for card_name in player_card_history:
		if card_name in card_counts:
			card_counts[card_name] += 1
		else:
			card_counts[card_name] = 1
	
	var most_played = ""
	var max_count = 0
	for card_name in card_counts:
		if card_counts[card_name] > max_count:
			max_count = card_counts[card_name]
			most_played = card_name
	
	return most_played

# Serialization support
func get_save_data() -> Dictionary:
	return {
		"stats": stats.get_save_data() if stats else {},
		"enemy_name": enemy_name,
		"description": description,
		"is_boss": is_boss,
		"is_elite": is_elite,
		"stun_turns_remaining": stun_turns_remaining,
		"current_pattern_index": current_pattern_index,
		"turns_alive": turns_alive,
		"damage_modifier": damage_modifier,
		"defense_modifier": defense_modifier,
		"enemy_hand": enemy_hand.get_save_data() if enemy_hand else {},
		"enemy_deck": enemy_deck.get_save_data() if enemy_deck else {},
		"enemy_discard": enemy_discard.get_save_data() if enemy_discard else {},
		"enemy_deck_data_path": enemy_deck_data.resource_path if enemy_deck_data else "",
		"enemy_deck_paths": enemy_deck_paths,
		"ai_type": ai_type,
		"player_card_history": player_card_history
	}

func load_from_data(data: Dictionary):
	if not stats:
		stats = Stats.new()
	if not enemy_hand:
		enemy_hand = CardPile.new("enemy_hand", hand_size_limit)
	if not enemy_deck:
		enemy_deck = CardPile.new("enemy_deck")
	if not enemy_discard:
		enemy_discard = CardPile.new("enemy_discard")
	
	stats.load_from_data(data.get("stats", {}))
	enemy_name = data.get("enemy_name", "")
	description = data.get("description", "")
	is_boss = data.get("is_boss", false)
	is_elite = data.get("is_elite", false)
	stun_turns_remaining = data.get("stun_turns_remaining", 0)
	current_pattern_index = data.get("current_pattern_index", 0)
	turns_alive = data.get("turns_alive", 0)
	damage_modifier = data.get("damage_modifier", 1.0)
	defense_modifier = data.get("defense_modifier", 1.0)
	
	enemy_hand.load_from_data(data.get("enemy_hand", {}))
	enemy_deck.load_from_data(data.get("enemy_deck", {}))
	enemy_discard.load_from_data(data.get("enemy_discard", {}))
	# Load deck data
	var deck_data_path = data.get("enemy_deck_data_path", "")
	if deck_data_path != "":
		enemy_deck_data = load(deck_data_path) as DeckData
	
	enemy_deck_paths = data.get("enemy_deck_paths", [])
	ai_type = data.get("ai_type", "aggressive")
	player_card_history = data.get("player_card_history", [])

# Deck loading helper methods
func initialize_deck_from_data():
	"""Load deck cards from DeckData resource or fallback to legacy paths"""
	if not enemy_deck:
		enemy_deck = CardPile.new("enemy_deck")
	else:
		enemy_deck.clear()
	
	# Try to load from DeckData resource first
	if enemy_deck_data:
		if DEBUG_ENABLED:
			GLog.debug("Loading enemy deck from DeckData resource: %s" % enemy_deck_data.deck_name)
		var deck_pile = enemy_deck_data.to_card_pile()
		deck_pile.move_all_to(enemy_deck)
		if DEBUG_ENABLED:
			GLog.debug("Loaded %d cards from DeckData" % enemy_deck.size())
		return
	
	# Fallback to legacy enemy_deck_paths
	if not enemy_deck_paths.is_empty():
		if DEBUG_ENABLED:
			GLog.debug("Loading enemy deck from legacy paths (%d cards)" % enemy_deck_paths.size())
		var loaded_count = 0
		for path in enemy_deck_paths:
			var card_data: CardData = load(path) as CardData
			if card_data:
				enemy_deck.add_card_data(card_data)
				loaded_count += 1
			else:
				GLog.error("Failed to load card from legacy path: %s" % path)
		if DEBUG_ENABLED:
			GLog.debug("Loaded %d/%d cards from legacy paths" % [loaded_count, enemy_deck_paths.size()])
	else:
		GLog.warn("No deck data or legacy paths found for enemy: %s" % enemy_name)

func get_deck_strategy() -> String:
	"""Get enemy's preferred strategy from deck data or AI type"""
	if enemy_deck_data and enemy_deck_data.preferred_strategy:
		return enemy_deck_data.preferred_strategy
	else:
		return ai_type  # fallback to AI type

func get_deck_theme() -> String:
	"""Get enemy's deck theme"""
	if enemy_deck_data:
		return enemy_deck_data.deck_theme
	else:
		return "unknown"

func get_deck_difficulty() -> int:
	"""Get enemy's deck difficulty level"""
	if enemy_deck_data:
		return enemy_deck_data.difficulty_level
	else:
		return 1  # default difficulty

# Debug methods
func print_status():
	"""Print current enemy status for debugging"""
	GLog.debug("=== %s ===" % enemy_name)
	if stats:
		stats.print_status()
	GLog.debug("Stun: %d turns remaining" % stun_turns_remaining)
	GLog.debug("Pattern: %d" % current_pattern_index)
	GLog.debug("Turns alive: %d" % turns_alive)
	GLog.debug("Modifiers: %.1fx damage, %.1fx defense" % [damage_modifier, defense_modifier])
	GLog.debug("AI Type: %s" % ai_type)
	if enemy_deck_data:
		GLog.debug("Deck: %s (%s theme, difficulty %d)" % [enemy_deck_data.deck_name, enemy_deck_data.deck_theme, enemy_deck_data.difficulty_level])
	GLog.debug("Hand: %d cards" % (enemy_hand.size() if enemy_hand else 0))
	GLog.debug("Deck: %d cards" % (enemy_deck.size() if enemy_deck else 0))
	GLog.debug("Discard: %d cards" % (enemy_discard.size() if enemy_discard else 0))
	GLog.debug("Player memory: %s" % str(player_card_history))
