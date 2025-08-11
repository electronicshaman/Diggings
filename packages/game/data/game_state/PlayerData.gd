extends Resource
class_name PlayerData

# PlayerData Resource - Complete player state using Stats resource
# Replaces the old PlayerState Node with a more efficient resource-based approach

# Core stats using our Stats resource
@export var stats: Stats

# Character class information
@export var character_class: CharacterClass
@export var character_class_name: String = ""

# Card-specific effects and modifiers
@export var next_card_free: bool = false
@export var attack_cost_reduction: int = 0
@export var attack_cost_reduction_duration: int = 0
@export var grit_cost_reduction: int = 0
@export var grit_cost_reduction_duration: int = 0
@export var grog_cost_reduction: int = 0
@export var grog_cost_reduction_duration: int = 0
@export var gamble_cost_reduction: int = 0
@export var gamble_cost_reduction_duration: int = 0
@export var all_cost_reduction: int = 0
@export var all_cost_reduction_duration: int = 0

# Gambling system
@export var gambling_active: bool = false
@export var gambling_multiplier: float = 1.0
@export var gambling_duration: int = 0

# Duel tracking
@export var cards_drawn_this_turn: int = 0
@export var cards_played_this_turn: int = 0
@export var damage_dealt_this_turn: int = 0
@export var damage_taken_this_turn: int = 0

# HOLD card persistence (cards that persist between turns)
@export var hold_cards: Array[CardData] = []

# Turn-end effects tracking
@export var delayed_damage: int = 0

# Curio system
@export var curios: Array = []  # Array of CurioData resources
@export var curio_stacks: Dictionary = {}  # curio_name -> stack count

# Change tracking system
var _change_listeners: Array[Callable] = []

func _init():
	# Initialize with default stats if none provided
	if not stats:
		stats = Stats.new()
	
	# Forward stats change notifications
	stats.add_change_listener(_forward_stats_change)

func add_change_listener(callback: Callable):
	"""Add a callback to be notified of player data changes"""
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

# Character class methods
func set_character_class(new_class: CharacterClass):
	"""Set the player's character class"""
	if character_class != new_class:
		character_class = new_class
		if new_class:
			character_class_name = new_class.character_class_name
			# Note: Character base stats are applied directly in GameController
			# This method just sets the class reference for card affinity checks
		_emit_change("character_class_changed", null, new_class)

func get_display_name() -> String:
	"""Get the display name for the character class"""
	if character_class:
		return character_class.get_display_name()
	return character_class_name if character_class_name else "Gunslinger"

# Stats convenience methods (forward to Stats resource)
func is_alive() -> bool:
	return stats.is_alive()

func is_dead() -> bool:
	return stats.is_dead()

func is_sane() -> bool:
	return stats.is_sane()

func is_insane() -> bool:
	return stats.is_insane()

func take_damage(amount: int) -> int:
	damage_taken_this_turn += amount
	return stats.take_damage(amount)

func heal(amount: int):
	stats.heal(amount)

func gain_defense(amount: int):
	stats.gain_defense(amount)

func spend_energy(amount: int) -> bool:
	return stats.spend_energy(amount)

func restore_energy(amount: int):
	stats.restore_energy(amount)

func restore_energy_amount(amount: int):
	"""Alias for restore_energy for compatibility"""
	restore_energy(amount)

func lose_sanity(amount: int):
	stats.lose_sanity(amount)

func restore_sanity(amount: int):
	stats.restore_sanity(amount)

func pay_energy(amount: int):
	"""Pay energy cost (doesn't check if affordable)"""
	stats.current_energy = max(0, stats.current_energy - amount)

func pay_sanity(amount: int):
	"""Pay sanity cost (doesn't check if affordable)"""
	stats.current_sanity = max(0, stats.current_sanity - amount)

func modify_max_health(change: int):
	stats.modify_max_health(change)

func modify_max_energy(change: int):
	stats.modify_max_energy(change)

func modify_max_sanity(change: int):
	stats.modify_max_sanity(change)

# Cost reduction system
func activate_next_card_free():
	"""Make the next card cost 0 energy"""
	next_card_free = true
	_emit_change("next_card_free_activated", false, true)

func set_attack_cost_reduction(reduction: int, duration: int):
	attack_cost_reduction = reduction
	attack_cost_reduction_duration = duration

func set_grit_cost_reduction(reduction: int, duration: int):
	grit_cost_reduction = reduction
	grit_cost_reduction_duration = duration

func set_grog_cost_reduction(reduction: int, duration: int):
	grog_cost_reduction = reduction
	grog_cost_reduction_duration = duration

func set_gamble_cost_reduction(reduction: int, duration: int):
	gamble_cost_reduction = reduction
	gamble_cost_reduction_duration = duration

func set_all_cost_reduction(reduction: int, duration: int):
	all_cost_reduction = reduction
	all_cost_reduction_duration = duration

func get_actual_energy_cost(base_cost: int, card_type: String) -> int:
	"""Calculate actual energy cost after reductions"""
	if next_card_free:
		return 0
	
	var final_cost = base_cost
	
	# Apply all cost reduction
	if all_cost_reduction_duration > 0:
		final_cost -= all_cost_reduction
	
	# Apply type-specific reductions
	match card_type:
		"Gold":
			if attack_cost_reduction_duration > 0:
				final_cost -= attack_cost_reduction
		"Grit":
			if grit_cost_reduction_duration > 0:
				final_cost -= grit_cost_reduction
		"Grog":
			if grog_cost_reduction_duration > 0:
				final_cost -= grog_cost_reduction
		"Gamble":
			if gamble_cost_reduction_duration > 0:
				final_cost -= gamble_cost_reduction
	
	return max(0, final_cost)

func can_afford_card(energy_cost: int, sanity_cost: int) -> bool:
	"""Check if player can afford to play a card"""
	return stats.current_energy >= energy_cost and stats.current_sanity >= sanity_cost

func apply_card_cost_reductions():
	"""Apply cost reduction decrements after playing a card"""
	if next_card_free:
		next_card_free = false
		_emit_change("next_card_free_used", true, false)
	
	if all_cost_reduction_duration > 0:
		all_cost_reduction_duration -= 1
		if all_cost_reduction_duration <= 0:
			all_cost_reduction = 0
	
	if attack_cost_reduction_duration > 0:
		attack_cost_reduction_duration -= 1
		if attack_cost_reduction_duration <= 0:
			attack_cost_reduction = 0
	
	if grit_cost_reduction_duration > 0:
		grit_cost_reduction_duration -= 1
		if grit_cost_reduction_duration <= 0:
			grit_cost_reduction = 0
	
	if grog_cost_reduction_duration > 0:
		grog_cost_reduction_duration -= 1
		if grog_cost_reduction_duration <= 0:
			grog_cost_reduction = 0
	
	if gamble_cost_reduction_duration > 0:
		gamble_cost_reduction_duration -= 1
		if gamble_cost_reduction_duration <= 0:
			gamble_cost_reduction = 0

# Gambling system
func set_gambling_state(multiplier: float, duration: int):
	gambling_active = true
	gambling_multiplier = multiplier
	gambling_duration = duration
	_emit_change("gambling_activated", false, true)

func check_and_apply_gambling() -> Dictionary:
	"""Check if gambling is active and return result"""
	if not gambling_active or gambling_duration <= 0:
		return {"active": false}
	
	gambling_duration -= 1
	if gambling_duration <= 0:
		gambling_active = false
		_emit_change("gambling_deactivated", true, false)
	
	return {
		"active": true,
		"multiplier": gambling_multiplier
	}

# Turn management
func start_new_turn():
	"""Reset per-turn tracking and restore energy"""
	cards_played_this_turn = 0
	damage_dealt_this_turn = 0
	damage_taken_this_turn = 0
	stats.reset_energy()
	_emit_change("turn_started", null, null)

func end_turn():
	"""Handle end of turn effects"""
	# Process delayed damage
	if delayed_damage > 0:
		stats.take_damage(delayed_damage)
		delayed_damage = 0
		_emit_change("delayed_damage_applied", null, delayed_damage)
	
	_emit_change("turn_ended", null, null)

func reset_duel_tracking():
	"""Reset all duel-specific tracking"""
	cards_played_this_turn = 0
	damage_dealt_this_turn = 0
	damage_taken_this_turn = 0
	delayed_damage = 0
	gambling_active = false
	gambling_multiplier = 1.0
	gambling_duration = 0
	next_card_free = false
	# Reset all cost reductions
	attack_cost_reduction = 0
	attack_cost_reduction_duration = 0
	grit_cost_reduction = 0
	grit_cost_reduction_duration = 0
	grog_cost_reduction = 0
	grog_cost_reduction_duration = 0
	gamble_cost_reduction = 0
	gamble_cost_reduction_duration = 0
	all_cost_reduction = 0
	all_cost_reduction_duration = 0
	hold_cards.clear()

# HOLD card management
func add_hold_card(card_data: CardData):
	"""Add a card to persistent HOLD cards"""
	if card_data not in hold_cards:
		hold_cards.append(card_data)

func remove_hold_card(card_data: CardData):
	"""Remove a card from persistent HOLD cards"""
	hold_cards.erase(card_data)

func get_hold_cards() -> Array[CardData]:
	"""Get all persistent HOLD cards"""
	return hold_cards.duplicate()

func clear_hold_cards():
	"""Clear all HOLD cards"""
	hold_cards.clear()

# Curio management
func add_curio(curio: Resource) -> void:
	"""Add a curio to the player's collection"""
	if curio and curio not in curios:
		curios.append(curio)
		if curio.stackable if curio.has("stackable") else false:
			var curio_name = curio.curio_name if curio.has("curio_name") else ""
			var current = curio_stacks.get(curio_name, 0)
			curio_stacks[curio_name] = current + 1
		_emit_change("curio_added", null, curio)

func remove_curio(curio: Resource) -> void:
	"""Remove a curio from the player's collection"""
	if curio and curio in curios:
		curios.erase(curio)
		var curio_name = curio.curio_name if curio.has("curio_name") else ""
		if curio_stacks.has(curio_name):
			curio_stacks.erase(curio_name)
		_emit_change("curio_removed", curio, null)

func has_curio(curio_name: String) -> bool:
	"""Check if player has a specific curio"""
	for curio in curios:
		var check_name = curio.curio_name if curio.has("curio_name") else ""
		if check_name == curio_name:
			return true
	return false

func get_curio_stack_count(curio_name: String) -> int:
	"""Get the stack count for a stackable curio"""
	return curio_stacks.get(curio_name, 0)

func get_curio_stat_modifier(stat_name: String) -> float:
	"""Calculate cumulative stat modifiers from all curios"""
	var total = 0.0
	# This will be handled by CurioManager in practice
	return total

# Convenience property accessors for compatibility
var current_health: int:
	get: return stats.current_health if stats else 0
	set(value): if stats: stats.current_health = value

var max_health: int:
	get: return stats.max_health if stats else 0
	set(value): if stats: stats.max_health = value

var current_energy: int:
	get: return stats.current_energy if stats else 0
	set(value): if stats: stats.current_energy = value

var max_energy: int:
	get: return stats.max_energy if stats else 0
	set(value): if stats: stats.max_energy = value

var current_sanity: int:
	get: return stats.current_sanity if stats else 0
	set(value): if stats: stats.current_sanity = value

var max_sanity: int:
	get: return stats.max_sanity if stats else 0
	set(value): if stats: stats.max_sanity = value

var defense: int:
	get: return stats.defense if stats else 0
	set(value): if stats: stats.defense = value

func get_health_percentage() -> float:
	return stats.get_health_percentage() if stats else 0.0

func get_energy_percentage() -> float:
	return stats.get_energy_percentage() if stats else 0.0

func get_sanity_percentage() -> float:
	return stats.get_sanity_percentage() if stats else 0.0

func get_missing_health_percentage() -> float:
	return stats.get_missing_health_percentage() if stats else 0.0

func get_damage_taken_this_duel() -> int:
	return damage_taken_this_turn

# Serialization support
func get_save_data() -> Dictionary:
	var data = {
		"stats": stats.get_save_data() if stats else {},
		"character_class_name": character_class_name,
		"next_card_free": next_card_free,
		"attack_cost_reduction": attack_cost_reduction,
		"attack_cost_reduction_duration": attack_cost_reduction_duration,
		"grit_cost_reduction": grit_cost_reduction,
		"grit_cost_reduction_duration": grit_cost_reduction_duration,
		"grog_cost_reduction": grog_cost_reduction,
		"grog_cost_reduction_duration": grog_cost_reduction_duration,
		"gamble_cost_reduction": gamble_cost_reduction,
		"gamble_cost_reduction_duration": gamble_cost_reduction_duration,
		"all_cost_reduction": all_cost_reduction,
		"all_cost_reduction_duration": all_cost_reduction_duration,
		"gambling_active": gambling_active,
		"gambling_multiplier": gambling_multiplier,
		"gambling_duration": gambling_duration,
		"cards_played_this_turn": cards_played_this_turn,
		"damage_dealt_this_turn": damage_dealt_this_turn,
		"damage_taken_this_turn": damage_taken_this_turn,
		"curio_stacks": curio_stacks.duplicate()
	}
	
	# Save HOLD cards
	var hold_card_paths: Array[String] = []
	for card in hold_cards:
		if card.resource_path:
			hold_card_paths.append(card.resource_path)
	data["hold_card_paths"] = hold_card_paths
	
	# Save curios
	var curio_paths: Array[String] = []
	for curio in curios:
		if curio.resource_path:
			curio_paths.append(curio.resource_path)
	data["curio_paths"] = curio_paths
	
	return data

func load_from_data(data: Dictionary):
	if not stats:
		stats = Stats.new()
	
	stats.load_from_data(data.get("stats", {}))
	character_class_name = data.get("character_class_name", "")
	next_card_free = data.get("next_card_free", false)
	attack_cost_reduction = data.get("attack_cost_reduction", 0)
	attack_cost_reduction_duration = data.get("attack_cost_reduction_duration", 0)
	grit_cost_reduction = data.get("grit_cost_reduction", 0)
	grit_cost_reduction_duration = data.get("grit_cost_reduction_duration", 0)
	grog_cost_reduction = data.get("grog_cost_reduction", 0)
	grog_cost_reduction_duration = data.get("grog_cost_reduction_duration", 0)
	gamble_cost_reduction = data.get("gamble_cost_reduction", 0)
	gamble_cost_reduction_duration = data.get("gamble_cost_reduction_duration", 0)
	all_cost_reduction = data.get("all_cost_reduction", 0)
	all_cost_reduction_duration = data.get("all_cost_reduction_duration", 0)
	gambling_active = data.get("gambling_active", false)
	gambling_multiplier = data.get("gambling_multiplier", 1.0)
	gambling_duration = data.get("gambling_duration", 0)
	cards_played_this_turn = data.get("cards_played_this_turn", 0)
	damage_dealt_this_turn = data.get("damage_dealt_this_turn", 0)
	damage_taken_this_turn = data.get("damage_taken_this_turn", 0)
	
	# Load HOLD cards
	hold_cards.clear()
	var hold_card_paths = data.get("hold_card_paths", [])
	for path in hold_card_paths:
		var card_data = load(path) as CardData
		if card_data:
			hold_cards.append(card_data)
	
	# Load curios
	curios.clear()
	var curio_paths = data.get("curio_paths", [])
	for path in curio_paths:
		var curio_data = load(path)
		if curio_data:
			curios.append(curio_data)
	
	# Load curio stacks
	curio_stacks = data.get("curio_stacks", {}).duplicate()

# Debug methods
func print_status():
	"""Print current player status for debugging"""
	if stats:
		stats.print_status()
	print("Class: %s" % get_display_name())
	print("Cards played this turn: %d" % cards_played_this_turn)
	print("HOLD cards: %d" % hold_cards.size())
