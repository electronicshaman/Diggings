extends Node

const DEBUG_ENABLED: bool = true

# Master seed that drives all randomization in the game
var master_seed: int = 0

# Individual RNG instances for different game systems
var map_rng: RandomNumberGenerator
var combat_rng: RandomNumberGenerator
var loot_rng: RandomNumberGenerator
var character_rng: RandomNumberGenerator
var event_rng: RandomNumberGenerator

# State tracking
var is_initialized: bool = false
var current_run_active: bool = false

signal seed_changed(new_seed: int)

func _ready() -> void:
	name = "SeedManager"
	GLog.debug("SeedManager initialized - Deterministic randomness established")
	initialize_rng_instances()

func initialize_rng_instances() -> void:
	"""Create all RNG instances. Seeds will be set when a run starts."""
	map_rng = RandomNumberGenerator.new()
	combat_rng = RandomNumberGenerator.new()
	loot_rng = RandomNumberGenerator.new()
	character_rng = RandomNumberGenerator.new()
	event_rng = RandomNumberGenerator.new()
	
	is_initialized = true
	GLog.debug("All RNG instances created")

func set_master_seed(seed_input: Variant = null) -> int:
	"""Set the master seed from user input or generate one.
	
	Args:
		seed_input: Can be int, string, or null (auto-generate)
	
	Returns:
		The final master seed used
	"""
	if seed_input == null:
		# Auto-generate seed
		master_seed = Time.get_ticks_msec() % 2147483647  # Keep within int range
	elif seed_input is String:
		# Convert string to deterministic seed
		if seed_input.strip_edges().is_empty():
			master_seed = Time.get_ticks_msec() % 2147483647
		else:
			master_seed = abs(seed_input.hash()) % 2147483647
	elif seed_input is int:
		# Use provided integer seed
		master_seed = abs(seed_input) % 2147483647
	else:
		# Fallback - convert to string then hash
		master_seed = abs(str(seed_input).hash()) % 2147483647
	
	# Initialize all sub-systems with deterministic seeds
	setup_subsystem_seeds()
	
	seed_changed.emit(master_seed)
	GLog.info("Master seed set: " + str(master_seed))
	
	return master_seed

func setup_subsystem_seeds() -> void:
	"""Generate deterministic seeds for each game subsystem."""
	if not is_initialized:
		push_error("SeedManager not initialized - call initialize_rng_instances first")
		return
	
	# Generate sub-seeds using master seed + system identifier
	map_rng.seed = generate_subseed("map")
	combat_rng.seed = generate_subseed("combat") 
	loot_rng.seed = generate_subseed("loot")
	character_rng.seed = generate_subseed("character")
	event_rng.seed = generate_subseed("event")
	
	GLog.debug("All subsystem seeds configured")
	GLog.debug("Map seed: " + str(map_rng.seed))
	GLog.debug("Combat seed: " + str(combat_rng.seed))
	GLog.debug("Loot seed: " + str(loot_rng.seed))

func generate_subseed(system_name: String) -> int:
	"""Generate a deterministic sub-seed for a specific system.
	
	Args:
		system_name: Identifier for the game system
		
	Returns:
		Deterministic seed for that system
	"""
	return master_seed ^ system_name.hash()

# Convenience methods for each system
func get_map_random_int(from: int, to: int) -> int:
	"""Get a random integer for map generation."""
	return map_rng.randi_range(from, to)

func get_map_random_float() -> float:
	"""Get a random float for map generation."""
	return map_rng.randf()

func get_combat_random_int(from: int, to: int) -> int:
	"""Get a random integer for combat."""
	return combat_rng.randi_range(from, to)

func get_combat_random_float() -> float:
	"""Get a random float for combat."""
	return combat_rng.randf()

func get_loot_random_int(from: int, to: int) -> int:
	"""Get a random integer for loot generation."""
	return loot_rng.randi_range(from, to)

func get_loot_random_float() -> float:
	"""Get a random float for loot generation."""
	return loot_rng.randf()

func get_character_random_int(from: int, to: int) -> int:
	"""Get a random integer for character generation."""
	return character_rng.randi_range(from, to)

func get_character_random_float() -> float:
	"""Get a random float for character generation."""
	return character_rng.randf()

func get_event_random_int(from: int, to: int) -> int:
	"""Get a random integer for event generation."""
	return event_rng.randi_range(from, to)

func get_event_random_float() -> float:
	"""Get a random float for event generation."""
	return event_rng.randf()

# Array shuffling methods for each system
func shuffle_array_map(array: Array) -> void:
	"""Shuffle an array using map RNG."""
	for i in range(array.size() - 1, 0, -1):
		var j = map_rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

func shuffle_array_combat(array: Array) -> void:
	"""Shuffle an array using combat RNG."""
	for i in range(array.size() - 1, 0, -1):
		var j = combat_rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

func shuffle_array_loot(array: Array) -> void:
	"""Shuffle an array using loot RNG."""
	for i in range(array.size() - 1, 0, -1):
		var j = loot_rng.randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

# Save/Load RNG state for persistence
func get_rng_state() -> Dictionary:
	"""Get the current state of all RNG instances for saving."""
	return {
		"master_seed": master_seed,
		"map_state": map_rng.state,
		"combat_state": combat_rng.state,
		"loot_state": loot_rng.state,
		"character_state": character_rng.state,
		"event_state": event_rng.state
	}

func set_rng_state(state_data: Dictionary) -> void:
	"""Restore RNG state from saved data."""
	if state_data.has("master_seed"):
		master_seed = state_data.master_seed
	
	if state_data.has("map_state"):
		map_rng.state = state_data.map_state
	if state_data.has("combat_state"):
		combat_rng.state = state_data.combat_state
	if state_data.has("loot_state"):
		loot_rng.state = state_data.loot_state
	if state_data.has("character_state"):
		character_rng.state = state_data.character_state
	if state_data.has("event_state"):
		event_rng.state = state_data.event_state
	
	GLog.debug("RNG state restored from save data")

# Utility functions
func get_seed_string() -> String:
	"""Get the master seed as a string for display/sharing."""
	return str(master_seed)

func validate_seed_input(input: String) -> bool:
	"""Validate that a seed input is acceptable."""
	# Empty string is valid (auto-generate)
	if input.strip_edges().is_empty():
		return true
	
	# Check if it's a valid integer
	if input.strip_edges().is_valid_int():
		return true
	
	# Any non-empty string is valid (will be hashed)
	return input.length() > 0

func start_run(seed_input: Variant = null) -> void:
	"""Initialize seeding for a new run."""
	set_master_seed(seed_input)
	current_run_active = true
	GLog.info("New run started with seed: " + str(master_seed))

func end_run() -> void:
	"""Clean up after a run ends."""
	current_run_active = false
	GLog.info("Run ended, seed system reset")

func is_run_active() -> bool:
	"""Check if a seeded run is currently active."""
	return current_run_active