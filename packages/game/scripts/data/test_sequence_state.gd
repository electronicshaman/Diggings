extends Resource
class_name TestSequenceState

const DEBUG_ENABLED: bool = true

# Sequence configuration
var enemy_queue: Array[Resource] = []
var current_enemy_index: int = 0
var total_enemies: int = 0

# Persistent stats between battles
var persistent_health: int = 0
var persistent_energy: int = 0

# Test configuration preserved across battles
var selected_character: Resource = null
var selected_deck: Resource = null
var selected_curios: Array[Resource] = []

# Display and behavior options
var show_rewards: bool = false
var is_active: bool = false

func reset() -> void:
	"""Clear all sequence state"""
	enemy_queue.clear()
	current_enemy_index = 0
	total_enemies = 0
	persistent_health = 0
	persistent_energy = 0
	selected_character = null
	selected_deck = null
	selected_curios.clear()
	show_rewards = false
	is_active = false
	GLog.debug("Test sequence state reset", "test_sequence")

func is_sequence_complete() -> bool:
	"""Check if all enemies have been defeated"""
	return current_enemy_index >= total_enemies

func get_next_enemy() -> Resource:
	"""Get the current enemy to fight"""
	if is_sequence_complete():
		GLog.warn("Sequence complete, no more enemies", "test_sequence")
		return null

	if current_enemy_index < 0 or current_enemy_index >= enemy_queue.size():
		GLog.error("Invalid enemy index: %d / %d" % [current_enemy_index, enemy_queue.size()], "test_sequence")
		return null

	return enemy_queue[current_enemy_index]

func advance_to_next_enemy() -> void:
	"""Move to the next enemy in the queue"""
	current_enemy_index += 1
	GLog.debug("Advanced to enemy %d/%d" % [current_enemy_index + 1, total_enemies], "test_sequence")

func initialize(enemies: Array[Resource], character: Resource, deck: Resource, curios: Array[Resource], health: int, energy: int, rewards: bool) -> void:
	"""Initialize sequence state with test configuration"""
	reset()

	enemy_queue = enemies.duplicate()
	total_enemies = enemies.size()
	current_enemy_index = 0

	selected_character = character
	selected_deck = deck
	selected_curios = curios.duplicate()

	persistent_health = health
	persistent_energy = energy

	show_rewards = rewards
	is_active = true

	GLog.info("Test sequence initialized: %d enemies, HP=%d, Energy=%d, Rewards=%s" % [
		total_enemies, persistent_health, persistent_energy, "ON" if show_rewards else "OFF"
	], "test_sequence")

func get_progress_text() -> String:
	"""Get progress display text (e.g. 'Battle 2/5')"""
	if not is_active:
		return ""
	return "Battle %d/%d" % [current_enemy_index + 1, total_enemies]
