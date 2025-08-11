extends Node

const DEBUG_ENABLED: bool = true

# Thematic word lists for rare seed generation (1% chance)
const THEMATIC_WORDS = {
	# Short words (3-4 chars) - Common tier (70% of word seeds)
	"common": [
		"GOLD", "MINE", "FEAR", "DARK", "DEEP", "VOID", "CULT", "DOOM", 
		"RUIN", "DEAD", "GODS", "DUST", "CAMP", "BUSH", "MAD", "OLD"
	],
	# Medium words (5-7 chars) - Uncommon tier (25% of word seeds)  
	"uncommon": [
		"ELDER", "DREAM", "SHADOW", "HORROR", "CURSED", "COSMIC", "ARCANE",
		"DIGGER", "CLAIM", "NUGGET", "RANGE", "TRACK", "RIDGE", "CREEK"
	],
	# Long words (7+ chars) - Rare tier (5% of word seeds)
	"rare": [
		"CTHULHU", "ELDRITCH", "MADNESS", "WHISPER", "ANCIENT", "NIGHTMARE",
		"STRANGE", "GOLDMINE", "PROSPECTOR"
	]
}

# Master seed that drives all randomization in the game
var master_seed: int = 0

# Hash seed for user-friendly display and sharing (10 characters)
var master_hash_seed: String = ""

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
signal hash_seed_changed(new_hash_seed: String)

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
	var seed_source: String = ""
	var input_type: String = "null"
	
	if seed_input == null:
		# Auto-generate seed using multiple sources for better randomness
		randomize()  # Initialize Godot's random number generator with system time
		var time_component = Time.get_ticks_msec()
		var random_component = randi() % 1000000
		var unix_component = int(Time.get_unix_time_from_system()) % 1000000
		master_seed = abs((time_component + random_component * 31 + unix_component * 17)) % 2147483647
		seed_source = str(master_seed)
		input_type = "auto-generated"
		GLog.debug("Auto-generating seed: " + str(master_seed) + " (time: " + str(time_component) + ", random: " + str(random_component) + ", unix: " + str(unix_component) + ")")
	elif seed_input is String:
		input_type = "string"
		# Check if it's a hash seed first
		if validate_hash_seed(seed_input.strip_edges().to_upper()):
			master_hash_seed = seed_input.strip_edges().to_upper()
			master_seed = hash_to_seed(master_hash_seed)
			seed_source = master_hash_seed
			input_type = "hash_seed"
			GLog.debug("Using provided hash seed: " + master_hash_seed + " -> integer: " + str(master_seed))
		elif seed_input.strip_edges().is_empty():
			# Empty string - auto-generate with better randomness
			randomize()
			var time_component = Time.get_ticks_msec()
			var random_component = randi() % 1000000
			var unix_component = int(Time.get_unix_time_from_system()) % 1000000
			master_seed = abs((time_component + random_component * 31 + unix_component * 17)) % 2147483647
			seed_source = str(master_seed)
			input_type = "empty_string_auto_gen"
			GLog.debug("Empty string provided, auto-generating: " + str(master_seed))
		else:
			# Regular string - hash it
			master_seed = abs(seed_input.hash()) % 2147483647
			seed_source = seed_input
			input_type = "hashed_string"
			GLog.debug("Hashing string '" + seed_input + "' -> " + str(master_seed))
	elif seed_input is int:
		# Use provided integer seed
		master_seed = abs(seed_input) % 2147483647
		seed_source = str(master_seed)
		input_type = "integer"
		GLog.debug("Using provided integer seed: " + str(master_seed))
	else:
		# Fallback - convert to string then hash
		master_seed = abs(str(seed_input).hash()) % 2147483647
		seed_source = str(seed_input)
		input_type = "fallback_conversion"
		GLog.debug("Converting " + str(type_string(typeof(seed_input))) + " to seed: " + str(master_seed))
	
	# Always generate a fresh hash seed (unless we're using a provided hash seed)
	if not (seed_input is String and validate_hash_seed(seed_input.strip_edges().to_upper())):
		var old_hash_seed = master_hash_seed
		master_hash_seed = generate_hash_seed(seed_source)
		GLog.debug("Generated new hash seed: " + master_hash_seed + " (was: " + old_hash_seed + ")")
	
	# Validation: Ensure both seeds are set
	if master_seed == 0:
		GLog.error("Master seed is 0 after setting! Input: " + str(seed_input) + " Type: " + input_type)
	if master_hash_seed.is_empty():
		GLog.error("Master hash seed is empty after setting! Input: " + str(seed_input) + " Type: " + input_type)
	
	# Initialize all sub-systems with deterministic seeds
	setup_subsystem_seeds()
	
	seed_changed.emit(master_seed)
	hash_seed_changed.emit(master_hash_seed)
	GLog.info("Master seed set: " + str(master_seed) + " (Hash: " + master_hash_seed + ") [Input type: " + input_type + "]")
	
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

func generate_hash_seed(input: Variant = null) -> String:
	"""Generate a 10-character seed with dual generation system.
	
	99% chance: Standard alphanumeric hex (0-9, A-F)
	1% chance: Thematic word-based seed (CTHULHU999, GOLDMINE42)
	
	Args:
		input: Input to hash. If null, uses current timestamp
		
	Returns:
		10-character uppercase seed string
	"""
	var seed_input: String
	
	if input == null:
		seed_input = str(Time.get_ticks_msec())
	else:
		seed_input = str(input)
	
	var base_hash = abs(seed_input.hash())
	
	# Determine if we generate a thematic word seed (1% chance)
	var rarity_roll = base_hash % 100  # 0-99 range
	
	if rarity_roll == 0:  # Exactly 1% chance when remainder is 0
		return generate_thematic_word_seed(base_hash)
	else:
		return generate_standard_alphanumeric_seed(seed_input)

func generate_standard_alphanumeric_seed(seed_input: String) -> String:
	"""Generate standard 10-character hex seed (0-9, A-F).
	
	Args:
		seed_input: String input to hash
		
	Returns:
		10-character hex string with proper A-F characters
	"""
	# Try SHA-256 first for high-quality randomness
	var hash_context = HashingContext.new()
	var error = hash_context.start(HashingContext.HASH_SHA256)
	if error == OK:
		var update_error = hash_context.update(seed_input.to_utf8_buffer())
		if update_error == OK:
			var hash_bytes = hash_context.finish()
			if hash_bytes and hash_bytes.size() > 0:
				var hex_string = hash_bytes.hex_encode().to_upper()
				return hex_string.substr(0, 10)
	
	# SHA-256 failed, use deterministic hex fallback
	GLog.debug("Using hex fallback for seed generation")
	return generate_hex_fallback(seed_input)

func generate_hex_fallback(seed_input: String) -> String:
	"""Generate hex-style seed using deterministic method when SHA-256 fails.
	
	Args:
		seed_input: String input to convert
		
	Returns:
		10-character hex-style string with A-F characters
	"""
	var base_hash = abs(seed_input.hash())
	var result = ""
	
	# Generate 10 characters using hash manipulation
	for i in range(10):
		# Use different portions of the hash + iteration for variety
		var char_hash = (base_hash + i * 31) % 16  # 0-15 range for hex
		
		if char_hash < 10:
			result += str(char_hash)  # 0-9
		else:
			result += char("A".unicode_at(0) + (char_hash - 10))  # A-F
	
	return result

func generate_thematic_word_seed(base_hash: int) -> String:
	"""Generate thematic word-based seed (1% rarity).
	
	Args:
		base_hash: Base hash value for deterministic generation
		
	Returns:
		10-character seed with thematic words
	"""
	# Determine word rarity tier within the 1%
	var word_rarity = (base_hash / 100) % 100
	var word_list: Array
	
	if word_rarity < 70:  # 70% of word seeds (0.7% overall)
		word_list = THEMATIC_WORDS.common
	elif word_rarity < 95:  # 25% of word seeds (0.25% overall)  
		word_list = THEMATIC_WORDS.uncommon
	else:  # 5% of word seeds (0.05% overall)
		word_list = THEMATIC_WORDS.rare
	
	# Select word deterministically
	var word_index = (base_hash / 10000) % word_list.size()
	var base_word = word_list[word_index]
	
	# Fill remaining characters with numbers/letters
	var remaining = 10 - base_word.length()
	var fill_chars = ""
	
	for i in range(remaining):
		var char_hash = (base_hash + i * 47 + base_word.length()) % 36
		if char_hash < 10:
			fill_chars += str(char_hash)  # 0-9
		else:
			fill_chars += char("A".unicode_at(0) + (char_hash - 10))  # A-Z
	
	var final_seed = base_word + fill_chars
	GLog.info("Generated thematic seed: " + final_seed)
	return final_seed

func hash_to_seed(hash_seed: String) -> int:
	"""Convert a hash seed back to an integer seed.
	
	Args:
		hash_seed: 10-character hex hash seed
		
	Returns:
		Integer seed derived from hash
	"""
	if hash_seed.length() != 10:
		GLog.warn("Invalid hash seed length: " + str(hash_seed.length()) + ", expected 10")
		return abs(hash_seed.hash()) % 2147483647
	
	# Convert first 8 hex characters to integer (avoids overflow)
	var hex_substr = hash_seed.substr(0, 8)
	var int_value = hex_substr.hex_to_int()
	
	# Ensure positive and within range
	return abs(int_value) % 2147483647

func validate_hash_seed(hash_seed: String) -> bool:
	"""Validate that a hash seed is properly formatted.
	
	Args:
		hash_seed: String to validate
		
	Returns:
		True if valid 10-character alphanumeric string (hex or thematic)
	"""
	if hash_seed.length() != 10:
		return false
	
	# Check if all characters are valid alphanumeric
	for i in range(hash_seed.length()):
		var c = hash_seed[i]
		var is_digit = (c >= '0' and c <= '9')
		var is_upper_letter = (c >= 'A' and c <= 'Z')
		var is_lower_letter = (c >= 'a' and c <= 'z')
		
		if not (is_digit or is_upper_letter or is_lower_letter):
			return false
	
	return true

func is_thematic_seed(hash_seed: String) -> bool:
	"""Check if a seed contains recognizable thematic words.
	
	Args:
		hash_seed: 10-character seed to check
		
	Returns:
		True if contains words from our thematic lists
	"""
	if hash_seed.length() != 10:
		return false
	
	var upper_seed = hash_seed.to_upper()
	
	# Check against all word lists
	for category in THEMATIC_WORDS.values():
		for word in category:
			if upper_seed.begins_with(word):
				return true
	
	return false

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
		"master_hash_seed": master_hash_seed,
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
	
	if state_data.has("master_hash_seed"):
		master_hash_seed = state_data.master_hash_seed
	elif master_seed != 0:
		# Generate hash seed from existing integer seed if not present
		master_hash_seed = generate_hash_seed(str(master_seed))
	
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

func get_hash_seed_string() -> String:
	"""Get the master hash seed for display/sharing."""
	return master_hash_seed

func validate_seed_input(input: String) -> bool:
	"""Validate that a seed input is acceptable."""
	# Empty string is valid (auto-generate)
	if input.strip_edges().is_empty():
		return true
	
	# Check if it's a valid hash seed
	if validate_hash_seed(input.strip_edges()):
		return true
	
	# Check if it's a valid integer
	if input.strip_edges().is_valid_int():
		return true
	
	# Any non-empty string is valid (will be hashed)
	return input.length() > 0

func start_run(seed_input: Variant = null) -> void:
	"""Initialize seeding for a new run."""
	if seed_input != null:
		set_master_seed(seed_input)
	elif master_seed == 0 or master_hash_seed.is_empty():
		GLog.warn("start_run called with no seed and no existing seed - auto-generating")
		set_master_seed(null)
	
	current_run_active = true
	GLog.info("New run started with seed: " + str(master_seed) + " (Hash: " + master_hash_seed + ")")
	
	# Validate the run state
	validate_run_state()

func end_run() -> void:
	"""Clean up after a run ends."""
	current_run_active = false
	GLog.info("Run ended, seed system reset")

func is_run_active() -> bool:
	"""Check if a seeded run is currently active."""
	return current_run_active

func validate_run_state() -> bool:
	"""Validate that the seed system is in a consistent state."""
	var errors: Array[String] = []
	
	if not is_initialized:
		errors.append("SeedManager not initialized")
	
	if master_seed == 0:
		errors.append("Master seed is 0")
	
	if master_hash_seed.is_empty():
		errors.append("Master hash seed is empty")
	
	if not current_run_active:
		errors.append("Run not marked as active")
	
	# Validate RNG instances exist and have valid seeds
	if not map_rng:
		errors.append("Map RNG not initialized")
	elif map_rng.seed == 0:
		errors.append("Map RNG has zero seed")
	
	if not combat_rng:
		errors.append("Combat RNG not initialized")
	elif combat_rng.seed == 0:
		errors.append("Combat RNG has zero seed")
	
	if errors.size() > 0:
		GLog.error("Seed system validation failed:")
		for error in errors:
			GLog.error("  - " + error)
		return false
	
	GLog.debug("Seed system validation passed")
	return true