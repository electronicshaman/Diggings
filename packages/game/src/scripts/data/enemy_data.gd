extends Resource
class_name EnemyState

## EnemyState Resource - Enemy state using Stats resource
## Refactored: Card management delegated to EnemyCardManager (SRP)

## Intent types for enemy actions
enum IntentType {UNKNOWN, ATTACK, DEFEND, SPECIAL, BUFF, DEBUFF}

# Core stats using our Stats resource
@export var stats: Stats

# Card management (delegated to EnemyCardManager)
@export var card_manager: EnemyCardManager

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

# Enemy intent system (now using enum)
@export var current_intent: IntentType = IntentType.UNKNOWN
@export var intent_value: int = 0
@export var intent_revealed: bool = false

# Enemy-specific modifiers
@export var damage_modifier: float = 1.0
@export var defense_modifier: float = 1.0

# AI configuration
@export var ai_type: String = "aggressive" # aggressive, defensive, balanced, cunning

# Memory system for tracking player patterns
@export var player_card_history: Array[String] = []
@export var player_pattern_memory_size: int = 3

# Change tracking system
var _change_listeners: Array[Callable] = []


func _init() -> void:
	# Initialize with default stats if none provided
	if not stats:
		stats = Stats.new()
		GLog.debug("EnemyState._init(): Created new default Stats")
	else:
		GLog.debug("EnemyState._init(): Using existing Stats - HP: %d/%d" % [stats.current_health, stats.max_health])
	
	# Initialize card manager if none provided
	if not card_manager:
		card_manager = EnemyCardManager.new()
	
	# Forward stats change notifications
	stats.add_change_listener(_forward_stats_change)
	
	# Forward card manager change notifications
	card_manager.add_change_listener(_forward_card_manager_change)


## Change Listener System

func add_change_listener(callback: Callable) -> void:
	"""Add a callback to be notified of enemy data changes"""
	if callback not in _change_listeners:
		_change_listeners.append(callback)


func remove_change_listener(callback: Callable) -> void:
	"""Remove a callback from change notifications"""
	_change_listeners.erase(callback)


func _emit_change(change_type: String, old_value: Variant = null, new_value: Variant = null) -> void:
	"""Emit change notification to all listeners"""
	for callback in _change_listeners:
		callback.call(change_type, old_value, new_value)


func _forward_stats_change(change_type: String, old_value: Variant, new_value: Variant) -> void:
	"""Forward stats changes to our listeners"""
	_emit_change(change_type, old_value, new_value)


func _forward_card_manager_change(change_type: String, data: Dictionary) -> void:
	"""Forward card manager changes to our listeners"""
	_emit_change("enemy_" + change_type, null, data)


## Stats Convenience Methods (forward to Stats resource)

func is_alive() -> bool:
	return stats.is_alive()


func is_dead() -> bool:
	return stats.is_dead()


func take_damage(amount: int, ignore_defense: bool = false) -> int:
	"""Take damage with enemy-specific modifiers"""
	var modified_amount := int(amount * defense_modifier)
	
	if ignore_defense:
		# Bypass defense system
		var old_defense := stats.defense
		stats.defense = 0
		var damage_taken := stats.take_damage(modified_amount)
		stats.defense = old_defense # Restore defense after damage
		return damage_taken
	else:
		return stats.take_damage(modified_amount)


func heal(amount: int) -> void:
	stats.heal(amount)


func gain_defense(amount: int) -> void:
	stats.gain_defense(amount)


func lose_defense(amount: int) -> void:
	stats.lose_defense(amount)


## Stun Management

func apply_stun(turns: int) -> void:
	"""Apply stun effect"""
	var old_stun := stun_turns_remaining
	stun_turns_remaining = max(stun_turns_remaining, turns) # Take highest stun value
	_emit_change("stun_applied", old_stun, stun_turns_remaining)


func apply_direct_stun(turns: int) -> void:
	"""Apply stun effect directly (adds to existing stun)"""
	var old_stun := stun_turns_remaining
	stun_turns_remaining += turns
	_emit_change("stun_applied", old_stun, stun_turns_remaining)


func reduce_stun() -> void:
	"""Reduce stun by 1 turn (called at start of enemy turn)"""
	if stun_turns_remaining > 0:
		var old_stun := stun_turns_remaining
		stun_turns_remaining -= 1
		_emit_change("stun_reduced", old_stun, stun_turns_remaining)


func is_stunned() -> bool:
	"""Check if enemy is currently stunned"""
	return stun_turns_remaining > 0


## AI Pattern Management

func advance_pattern() -> void:
	"""Move to next pattern in sequence"""
	var old_index := current_pattern_index
	current_pattern_index += 1
	_emit_change("pattern_advanced", old_index, current_pattern_index)


func set_pattern_index(index: int) -> void:
	"""Set specific pattern index"""
	var old_index := current_pattern_index
	current_pattern_index = index
	_emit_change("pattern_set", old_index, current_pattern_index)


func get_pattern_index() -> int:
	"""Get current pattern index"""
	return current_pattern_index


## Turn Management

func start_turn() -> void:
	"""Called at the start of enemy turn"""
	turns_alive += 1
	_emit_change("turn_started", turns_alive - 1, turns_alive)


func end_turn() -> void:
	"""Called at the end of enemy turn"""
	_emit_change("turn_ended", null, null)


## Enemy-specific Modifiers

func set_damage_modifier(modifier: float) -> void:
	"""Set damage output modifier"""
	var old_modifier := damage_modifier
	damage_modifier = modifier
	_emit_change("damage_modifier_changed", old_modifier, damage_modifier)


func set_defense_modifier(modifier: float) -> void:
	"""Set damage resistance modifier"""
	var old_modifier := defense_modifier
	defense_modifier = modifier
	_emit_change("defense_modifier_changed", old_modifier, defense_modifier)


func get_modified_damage(base_damage: int) -> int:
	"""Calculate damage output with modifier"""
	return int(base_damage * damage_modifier)


## Intent Management (now using IntentType enum)

func set_intent(intent_type: IntentType, value: int = 0) -> void:
	"""Set enemy's current intent"""
	var old_intent := current_intent
	current_intent = intent_type
	intent_value = value
	intent_revealed = false # Reset revealed status when intent changes
	_emit_change("intent_set", old_intent, current_intent)


func reveal_intent() -> void:
	"""Reveal the enemy's current intent to the player"""
	if not intent_revealed:
		intent_revealed = true
		_emit_change("intent_revealed", false, true)


func get_intent_display() -> String:
	"""Get formatted intent string for display"""
	if not intent_revealed:
		return "Unknown"
	
	match current_intent:
		IntentType.ATTACK:
			return "Attack (%d)" % intent_value
		IntentType.DEFEND:
			return "Defend (%d)" % intent_value
		IntentType.SPECIAL:
			return "Special"
		IntentType.BUFF:
			return "Buff"
		IntentType.DEBUFF:
			return "Debuff"
		_:
			return "Unknown"


func is_intent_attack() -> bool:
	"""Check if current intent is an attack"""
	return current_intent == IntentType.ATTACK


func is_intent_defend() -> bool:
	"""Check if current intent is defend"""
	return current_intent == IntentType.DEFEND


func is_intent_revealed() -> bool:
	"""Check if intent has been revealed to player"""
	return intent_revealed


## Convenience Property Accessors for Compatibility

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


## Card Manager Delegation (backwards-compatible API)
## These methods delegate to EnemyCardManager for compatibility with existing code

var enemy_hand: CardPile:
	get: return card_manager.hand if card_manager else null

var enemy_deck: CardPile:
	get: return card_manager.deck if card_manager else null

var enemy_discard: CardPile:
	get: return card_manager.discard if card_manager else null

var enemy_deck_data: DeckData:
	get: return card_manager.deck_data if card_manager else null
	set(value): if card_manager: card_manager.deck_data = value

var hand_size_limit: int:
	get: return card_manager.hand_size_limit if card_manager else 7
	set(value): if card_manager: card_manager.hand_size_limit = value

var cards_per_turn: int:
	get: return card_manager.cards_per_turn if card_manager else 5
	set(value): if card_manager: card_manager.cards_per_turn = value


func draw_cards(count: int) -> Array[CardData]:
	"""Draw cards from deck to hand (delegates to card_manager)"""
	return card_manager.draw_cards(count) if card_manager else []


func play_card(card_data: CardData) -> void:
	"""Move card from hand to discard (delegates to card_manager)"""
	if card_manager:
		card_manager.play_card(card_data)


func discard_card(card_data: CardData) -> void:
	"""Discard a card from hand (delegates to card_manager)"""
	if card_manager:
		card_manager.discard_card(card_data)


func initialize_deck_from_data() -> void:
	"""Load deck cards from DeckData resource (delegates to card_manager)"""
	if card_manager:
		card_manager.initialize_from_deck_data(enemy_name)


func get_deck_strategy() -> String:
	"""Get enemy's preferred strategy from deck data"""
	if card_manager:
		return card_manager.get_strategy()
	return ai_type


func get_deck_theme() -> String:
	"""Get enemy's deck theme"""
	return card_manager.get_theme() if card_manager else "unknown"


func get_deck_difficulty() -> int:
	"""Get enemy's deck difficulty level"""
	return card_manager.get_difficulty() if card_manager else 1


## Player Pattern Memory

func add_to_player_memory(card_name: String) -> void:
	"""Track cards played by the player"""
	player_card_history.append(card_name)
	if player_card_history.size() > player_pattern_memory_size:
		player_card_history.pop_front()


func get_player_most_played_card() -> String:
	"""Get the most frequently played card by player from memory"""
	if player_card_history.is_empty():
		return ""
	
	var card_counts: Dictionary = {}
	for card_name in player_card_history:
		if card_name in card_counts:
			card_counts[card_name] += 1
		else:
			card_counts[card_name] = 1
	
	var most_played := ""
	var max_count := 0
	for card_name in card_counts:
		if card_counts[card_name] > max_count:
			max_count = card_counts[card_name]
			most_played = card_name
	
	return most_played


## Reset Methods

func reset_for_new_duel() -> void:
	"""Reset enemy state for a new duel"""
	if stats:
		stats.reset_to_max()
	stun_turns_remaining = 0
	current_pattern_index = 0
	turns_alive = 0
	damage_modifier = 1.0
	defense_modifier = 1.0
	
	# Clear card piles via card manager
	if card_manager:
		card_manager.clear_all()
	
	# Clear player pattern memory
	player_card_history.clear()


## Serialization Support

func get_save_data() -> Dictionary:
	return {
		"stats": stats.get_save_data() if stats else {},
		"card_manager": card_manager.get_save_data() if card_manager else {},
		"enemy_name": enemy_name,
		"description": description,
		"is_boss": is_boss,
		"is_elite": is_elite,
		"stun_turns_remaining": stun_turns_remaining,
		"current_pattern_index": current_pattern_index,
		"turns_alive": turns_alive,
		"current_intent": current_intent,
		"intent_value": intent_value,
		"intent_revealed": intent_revealed,
		"damage_modifier": damage_modifier,
		"defense_modifier": defense_modifier,
		"ai_type": ai_type,
		"player_card_history": player_card_history
	}


func load_from_data(data: Dictionary) -> void:
	if not stats:
		stats = Stats.new()
	if not card_manager:
		card_manager = EnemyCardManager.new()
	
	stats.load_from_data(data.get("stats", {}))
	card_manager.load_from_data(data.get("card_manager", {}))
	
	enemy_name = data.get("enemy_name", "")
	description = data.get("description", "")
	is_boss = data.get("is_boss", false)
	is_elite = data.get("is_elite", false)
	stun_turns_remaining = data.get("stun_turns_remaining", 0)
	current_pattern_index = data.get("current_pattern_index", 0)
	turns_alive = data.get("turns_alive", 0)
	current_intent = data.get("current_intent", IntentType.UNKNOWN)
	intent_value = data.get("intent_value", 0)
	intent_revealed = data.get("intent_revealed", false)
	damage_modifier = data.get("damage_modifier", 1.0)
	defense_modifier = data.get("defense_modifier", 1.0)
	ai_type = data.get("ai_type", "aggressive")
	player_card_history = data.get("player_card_history", [])


## Debug Methods

func print_status() -> void:
	"""Print current enemy status for debugging"""
	GLog.debug("=== %s ===" % enemy_name)
	if stats:
		stats.print_status()
	GLog.debug("Stun: %d turns remaining" % stun_turns_remaining)
	GLog.debug("Pattern: %d" % current_pattern_index)
	GLog.debug("Turns alive: %d" % turns_alive)
	GLog.debug("Modifiers: %.1fx damage, %.1fx defense" % [damage_modifier, defense_modifier])
	GLog.debug("AI Type: %s" % ai_type)
	if card_manager:
		card_manager.print_status(enemy_name)
	GLog.debug("Player memory: %s" % str(player_card_history))
