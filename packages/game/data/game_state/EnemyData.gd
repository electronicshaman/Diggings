extends Resource
class_name EnemyState

# EnemyState Resource - Enemy state using Stats resource
# Simpler than PlayerData, focused on combat stats and AI state

# Core stats using our Stats resource
@export var stats: Stats

# Enemy identification
@export var enemy_name: String = ""
@export var description: String = ""

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

# Change tracking system
var _change_listeners: Array[Callable] = []

func _init():
	# Initialize with default stats if none provided
	if not stats:
		stats = Stats.new()
	
	# Forward stats change notifications
	stats.add_change_listener(_forward_stats_change)

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

# Serialization support
func get_save_data() -> Dictionary:
	return {
		"stats": stats.get_save_data() if stats else {},
		"enemy_name": enemy_name,
		"description": description,
		"stun_turns_remaining": stun_turns_remaining,
		"current_pattern_index": current_pattern_index,
		"turns_alive": turns_alive,
		"damage_modifier": damage_modifier,
		"defense_modifier": defense_modifier
	}

func load_from_data(data: Dictionary):
	if not stats:
		stats = Stats.new()
	
	stats.load_from_data(data.get("stats", {}))
	enemy_name = data.get("enemy_name", "")
	description = data.get("description", "")
	stun_turns_remaining = data.get("stun_turns_remaining", 0)
	current_pattern_index = data.get("current_pattern_index", 0)
	turns_alive = data.get("turns_alive", 0)
	damage_modifier = data.get("damage_modifier", 1.0)
	defense_modifier = data.get("defense_modifier", 1.0)

# Debug methods
func print_status():
	"""Print current enemy status for debugging"""
	print("=== %s ===" % enemy_name)
	if stats:
		stats.print_status()
	print("Stun: %d turns remaining" % stun_turns_remaining)
	print("Pattern: %d" % current_pattern_index)
	print("Turns alive: %d" % turns_alive)
	print("Modifiers: %.1fx damage, %.1fx defense" % [damage_modifier, defense_modifier])