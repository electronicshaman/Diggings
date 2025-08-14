extends Node

# Ensure MapNodeConfig class is loaded and registered
const MapNodeConfig = preload("res://scripts/map/MapNodeConfig.gd")

const DEBUG_ENABLED: bool = true

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	VICTORY,
	LOADING
}

enum GameMode {
	STANDARD,
	DAILY,
	ENDLESS,
	CUSTOM
}

signal game_state_changed(new_state: GameState)
signal game_mode_changed(new_mode: GameMode)

var current_state: GameState = GameState.MENU
var current_mode: GameMode = GameMode.STANDARD
var current_run_seed: int = 0
var current_run_hash_seed: String = ""
var current_character_class: String = ""
var selected_character: GeneratedCharacter = null
var is_run_active: bool = false

var game_data: Dictionary = {}
var run_statistics: Dictionary = {}
var session_start_time: float = 0.0
var run_start_time: float = 0.0

func _ready() -> void:
	GLog.debug("GameManager initialized - The cosmic game engine awakens")
	session_start_time = Time.get_ticks_msec() / 1000.0
	setup_connections()
	initialize_game_data()

func setup_connections() -> void:
	EventBus.connect_safe("game_started", _on_game_started)
	EventBus.connect_safe("game_ended", _on_game_ended)
	EventBus.connect_safe("duel_started", _on_duel_started)
	EventBus.connect_safe("duel_ended", _on_duel_ended)

func initialize_game_data() -> void:
	game_data = {
		"player": null,
		"current_enemy": null,
		"current_floor": 0,
		"current_act": 1,
		"gold": 0,
		"corruption": 0,
		"deck": [],
		"curios": [],
		"maps": {},  # Multiple maps, one per region
		"current_map": "",  # Current region being explored
		"completed_maps": [],  # List of completed region IDs
		"available_maps": []  # List of available region IDs
	}
	
	reset_run_statistics()

func reset_run_statistics() -> void:
	run_statistics = {
		"cards_played": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"gold_collected": 0,
		"enemies_defeated": 0,
		"elites_defeated": 0,
		"bosses_defeated": 0,
		"turns_taken": 0,
		"perfect_battles": 0,
		"cards_exhausted": 0,
		"cards_upgraded": 0,
		"shops_visited": 0,
		"rest_sites_visited": 0,
		"events_encountered": 0
	}

func prepare_new_run() -> void:
	"""Pre-establish seed for new run, affecting character generation and everything else."""
	GLog.debug("Preparing new run - establishing seed")
	
	# Clear any custom seeds from GameSettings to ensure fresh generation
	# (unless player explicitly set one in settings menu)
	# The custom seeds should only be used if player enters them in settings
	# For normal "New Game", we want auto-generation
	
	# Get the effective seed from GameSettings (prioritizes hash seed over regular seed)
	var seed_to_use = GameSettings.get_effective_seed()
	if seed_to_use.is_empty():
		seed_to_use = null  # Auto-generate
	
	# Initialize the seed system for this run
	var final_seed = SeedManager.set_master_seed(seed_to_use)
	SeedManager.start_run(seed_to_use)
	
	# Store both integer and hash seeds for the run
	current_run_seed = final_seed
	current_run_hash_seed = SeedManager.get_hash_seed_string()
	
	# Store the established seeds back to GameSettings for persistence
	GameSettings.last_used_seed = final_seed
	GameSettings.last_used_hash_seed = current_run_hash_seed
	GameSettings.save_settings()
	
	GLog.info("New run prepared with seed: " + str(final_seed) + " (Hash: " + current_run_hash_seed + ")")

func start_new_run(character_class: String, custom_seed: Variant = null, mode: GameMode = GameMode.STANDARD) -> void:
	GLog.debug("Starting new run with class: " + character_class)
	
	if custom_seed != null:
		# Override with custom seed (for direct API calls)
		GLog.info("Using custom seed override: " + str(custom_seed))
		var final_seed = SeedManager.set_master_seed(custom_seed)
		SeedManager.start_run(custom_seed)
		current_run_seed = final_seed
		current_run_hash_seed = SeedManager.get_hash_seed_string()
		GameSettings.last_used_seed = final_seed
		GameSettings.last_used_hash_seed = current_run_hash_seed
		GameSettings.save_settings()
	elif current_run_seed == 0 or current_run_hash_seed.is_empty():
		# No seed pre-established, fall back to auto-generation
		GLog.warn("No seed pre-established for run, auto-generating from GameSettings")
		var seed_to_use = GameSettings.get_effective_seed()
		if seed_to_use.is_empty():
			seed_to_use = null
		var final_seed = SeedManager.set_master_seed(seed_to_use)
		SeedManager.start_run(seed_to_use)
		current_run_seed = final_seed
		current_run_hash_seed = SeedManager.get_hash_seed_string()
		GameSettings.last_used_seed = final_seed
		GameSettings.last_used_hash_seed = current_run_hash_seed
		GameSettings.save_settings()
	else:
		# Use the pre-established seed from prepare_new_run()
		GLog.info("Using pre-established seed: " + str(current_run_seed) + " (Hash: " + current_run_hash_seed + ")")
		# Ensure SeedManager has the run marked as active
		if not SeedManager.is_run_active():
			SeedManager.current_run_active = true
	
	current_character_class = character_class
	current_mode = mode
	is_run_active = true
	run_start_time = Time.get_ticks_msec() / 1000.0
	
	initialize_game_data()
	reset_run_statistics()
	
	# Apply character data if available
	if selected_character:
		apply_character_data()
	
	# Generate all maps for this run
	generate_all_maps()
	
	change_state(GameState.PLAYING)
	EventBus.game_started.emit()
	
	# Go to map selection screen instead of directly to map
	SceneManager.load_scene_by_name("map_selection")

func end_current_run(victory: bool = false) -> void:
	GLog.debug("Ending run - Victory: " + str(victory))
	
	is_run_active = false
	var run_duration := (Time.get_ticks_msec() / 1000.0) - run_start_time
	
	save_run_statistics(victory, run_duration)
	
	# Clean up seed system
	SeedManager.end_run()
	
	change_state(GameState.VICTORY if victory else GameState.GAME_OVER)
	EventBus.game_ended.emit(victory)

func save_run_statistics(victory: bool, duration: float) -> void:
	run_statistics["victory"] = victory
	run_statistics["duration"] = duration
	run_statistics["character_class"] = current_character_class
	run_statistics["seed"] = current_run_seed
	run_statistics["hash_seed"] = current_run_hash_seed
	run_statistics["mode"] = current_mode
	run_statistics["floor_reached"] = game_data.get("current_floor", 0)
	run_statistics["timestamp"] = Time.get_unix_time_from_system()
	
	# Add character name if available
	if selected_character:
		run_statistics["character_name"] = selected_character.full_name + " '" + selected_character.nickname + "'"
	else:
		run_statistics["character_name"] = current_character_class
	
	GLog.debug("Run statistics saved: " + str(run_statistics))
	
	# Save to run history for persistent tracking
	RunHistoryManager.add_run(run_statistics)

func apply_character_data() -> void:
	"""Apply selected character data to game state"""
	if not selected_character:
		return
	
	GLog.info("Applying character data for: " + selected_character.full_name + " '" + selected_character.nickname + "'")
	
	# Apply stat modifiers to base stats
	var base_stats = get_base_character_stats(current_character_class)
	for stat in selected_character.stat_modifiers:
		if base_stats.has(stat):
			base_stats[stat] += selected_character.stat_modifiers[stat]
	
	# Apply starting gold
	if base_stats.has("starting_gold"):
		game_data["gold"] = base_stats["starting_gold"]
	
	# Add starting curio
	if selected_character.starting_curio:
		var curio_resource = selected_character.starting_curio
		if curio_resource:
			var curio_name = "Unknown Curio"
			if curio_resource.curio_name:
				curio_name = curio_resource.curio_name
			
			GLog.info("Character has starting curio: " + curio_name)
			var success = CurioManager.add_curio(curio_resource)
			if success:
				GLog.info("Added starting curio: " + curio_name)
			else:
				GLog.warn("Failed to add starting curio: " + curio_name)
	
	# Store character in game data for access by other systems
	game_data["character"] = selected_character
	
	GLog.info("Character data applied successfully")

func get_base_character_stats(character_class: String) -> Dictionary:
	"""Get base stats for a character class from the character resource"""
	var character_path = "res://data/characters/" + character_class.to_lower() + ".tres"
	
	if ResourceLoader.exists(character_path):
		var character_resource = load(character_path) as CharacterClass
		if character_resource:
			return character_resource.get_starting_stats()
	
	GLog.warn("Failed to load character resource for %s, using fallback stats" % character_class)
	# Fallback stats if resource loading fails
	return {"base_health": 50, "base_sanity": 100, "base_energy": 3, "starting_gold": 10}

func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	var old_state := current_state
	current_state = new_state
	
	GLog.debug("Game state changed: " + str(GameState.keys()[old_state]) + 
		" -> " + str(GameState.keys()[new_state]))
	
	game_state_changed.emit(new_state)
	
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			EventBus.game_paused.emit()
		GameState.PLAYING:
			get_tree().paused = false
			EventBus.game_resumed.emit()
		GameState.GAME_OVER:
			handle_game_over()
		GameState.VICTORY:
			handle_victory()

func handle_game_over() -> void:
	GLog.debug("Game Over - The darkness claims another soul")
	EventBus.emit_ui_notification("GAME OVER", "error")

func handle_victory() -> void:
	GLog.debug("Victory - The light prevails... for now")
	EventBus.emit_ui_notification("VICTORY!", "success")
	unlock_rewards()

func unlock_rewards() -> void:
	pass

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

func _on_game_started() -> void:
	GLog.debug("Game started event received")

func _on_game_ended(victory: bool) -> void:
	GLog.debug("Game ended event received - Victory: " + str(victory))

func _on_duel_started(_enemy_data: Resource) -> void:
	run_statistics.turns_taken = 0

func _on_duel_ended(victory: bool) -> void:
	if victory:
		run_statistics.enemies_defeated += 1
		if run_statistics.turns_taken == 1:
			run_statistics.perfect_battles += 1

func increment_statistic(stat_name: String, amount: int = 1) -> void:
	if run_statistics.has(stat_name):
		run_statistics[stat_name] += amount
		EventBus.statistics_updated.emit(stat_name, run_statistics[stat_name])

func get_run_time() -> float:
	if not is_run_active:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - run_start_time

func get_session_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - session_start_time

func generate_all_maps() -> void:
	GLog.debug("Generating all maps for new run")
	
	var regions = ["goldfields", "outback", "mountains", "coast"]
	game_data.available_maps = regions.duplicate()
	game_data.completed_maps = []
	
	# Create a map generator instance
	var map_generator = preload("res://scripts/map/MapGenerator.gd").new()
	
	for region_id in regions:
		var config_path = "res://data/maps/" + region_id + "_config.tres"
		if not ResourceLoader.exists(config_path):
			GLog.error("Map config not found: " + config_path)
			continue
			
		var config = load(config_path) as MapRegionConfig
		if not config:
			GLog.error("Failed to load map config: " + config_path)
			continue
		
		# Generate map for this region with a unique seed offset
		var region_seed = current_run_seed + region_id.hash()
		var map_data = map_generator.generate_map_for_region(config, region_seed)
		
		if not map_data or map_data.is_empty():
			GLog.error("Failed to generate map for region: " + region_id)
			continue
		
		# Store the generated map
		game_data.maps[region_id] = {
			"generator_data": map_data,
			"config": config,
			"completed": false,
			"current_player_node": map_data.start_node if map_data.has("start_node") else "",
			"visited_nodes": [map_data.start_node] if map_data.has("start_node") else []
		}
		
		GLog.debug("Generated map for region: " + region_id + " with " + str(map_data.get("nodes", {}).size()) + " nodes")
	
	# Clean up the temporary generator
	map_generator.queue_free()
	
	GLog.info("All maps generated successfully")

func select_map(region_id: String) -> void:
	if not game_data.maps.has(region_id):
		GLog.error("Trying to select non-existent map: " + region_id)
		return
		
	if region_id in game_data.completed_maps:
		GLog.warn("Trying to select already completed map: " + region_id)
		return
	
	game_data.current_map = region_id
	GLog.info("Selected map: " + region_id)
	
	# Load the map scene
	SceneManager.load_scene_by_name("map")

func complete_current_map() -> void:
	var current = game_data.current_map
	if current.is_empty():
		GLog.error("No current map to complete")
		return
	
	# Mark as completed
	game_data.completed_maps.append(current)
	game_data.available_maps.erase(current)
	if game_data.maps.has(current):
		game_data.maps[current].completed = true
	
	GLog.info("Completed map: " + current)
	
	# Check for victory
	if game_data.available_maps.is_empty():
		GLog.info("All maps completed! Victory!")
		end_current_run(true)
	else:
		# Return to map selection
		SceneManager.load_scene_by_name("map_selection")

func is_game_paused() -> bool:
	return current_state == GameState.PAUSED

func can_pause() -> bool:
	return current_state == GameState.PLAYING

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_run_active and SaveSystem.autosave_enabled:
			SaveSystem.save_game(SaveSystem.AUTOSAVE_PATH, true)
		get_tree().quit()
