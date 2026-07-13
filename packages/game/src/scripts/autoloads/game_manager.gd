extends Node

# Quick Duel is now the primary game mode

const DEBUG_ENABLED: bool = true
const CURATED_RUN_PATH := "res://data/runs/the_diggings_short_run.tres"

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
var selected_character: CharacterClass = null
var run_session: RunSession = null
var last_run_summary: Dictionary = {}
var is_run_active: bool = false

var game_data: Dictionary = {}
var run_statistics: Dictionary = {}
var session_start_time: float = 0.0
var run_start_time: float = 0.0

# Duel system
var pending_duel_config: DuelConfig = null

# Temporary compatibility state for Quick Duel. Task 6 retires its callers.
var duel_sequence_state = null # Will be DuelSequenceState instance

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

		"maps": {}, # Multiple maps, one per region
		"current_map": "", # Current region being explored
	"completed_maps": [], # List of completed region IDs
	# Pre-populate with a few default regions used by MapSelection fallbacks
	"available_maps": ["goldfields", "outback", "mountains", "coast"] # List of available region IDs
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
		seed_to_use = null # Auto-generate
	
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

func start_new_run(
	character: CharacterClass,
	custom_seed: Variant = null,
	mode: GameMode = GameMode.STANDARD
) -> bool:
	if not character:
		GLog.error("Cannot start curated run without a character class")
		return false
	GLog.debug("Starting new run with class: " + character.character_class_name)
	
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
		# No seed pre-established, use the normal new-run preparation path.
		GLog.warn("No seed pre-established for run, auto-generating from GameSettings")
		prepare_new_run()
	else:
		# Use the pre-established seed from prepare_new_run()
		GLog.info("Using pre-established seed: " + str(current_run_seed) + " (Hash: " + current_run_hash_seed + ")")
		# Ensure SeedManager has the run marked as active
		if not SeedManager.is_run_active():
			SeedManager.current_run_active = true
	
	current_mode = mode
	run_start_time = Time.get_ticks_msec() / 1000.0
	
	initialize_game_data()
	reset_run_statistics()

	var started := begin_curated_run(character, current_run_seed)
	if not started:
		return false
	EventBus.emit_game_started()
	SceneManager.load_scene_by_name("duel")
	return true


func has_active_run() -> bool:
	return run_session != null and run_session.state in [
		RunSession.State.FIGHT_READY,
		RunSession.State.IN_DUEL,
		RunSession.State.REWARD_PENDING
	]


func begin_curated_run(character: CharacterClass, run_seed: int) -> bool:
	reset_curated_run()
	if not character:
		return false
	selected_character = character
	current_character_class = character.character_class_name
	current_run_seed = run_seed
	if SeedManager.master_seed != run_seed:
		SeedManager.set_master_seed(run_seed)
	if not DeckManager.start_new_run_deck(current_character_class):
		reset_curated_run()
		return false
	run_session = RunSession.new(DeckManager, SeedManager)
	var definition := load(CURATED_RUN_PATH) as RunDefinition
	if not run_session.begin(definition, character, run_seed):
		reset_curated_run()
		return false
	current_run_hash_seed = SeedManager.get_hash_seed_string()
	pending_duel_config = run_session.prepare_current_duel()
	if pending_duel_config == null or not pending_duel_config.is_valid():
		reset_curated_run()
		return false
	is_run_active = true
	change_state(GameState.PLAYING)
	return true


func reset_curated_run() -> void:
	pending_duel_config = null
	run_session = null
	selected_character = null
	is_run_active = false
	DeckManager.clear_current_deck()
	CurioManager.reset_run_curios()


func get_pending_run_rewards() -> Array[CardData]:
	return run_session.get_pending_card_offers() if run_session else []


func choose_run_card(card: CardData) -> bool:
	if run_session == null or not run_session.apply_card_reward(card):
		return false
	return _prepare_and_start_next_run_duel()


func choose_run_recovery() -> bool:
	if run_session == null or not run_session.apply_recovery():
		return false
	return _prepare_and_start_next_run_duel()


func _prepare_and_start_next_run_duel() -> bool:
	pending_duel_config = run_session.prepare_current_duel()
	if pending_duel_config == null or not pending_duel_config.is_valid():
		run_session.record_defeat(RunSession.EndReason.INVALID_STATE)
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return false
	return start_prepared_duel()


func complete_curated_duel(player: PlayerData, winner: String) -> void:
	if not has_active_run():
		return
	if winner != "player":
		var reason := (
			RunSession.EndReason.SANITY
			if player.stats.current_sanity <= 0
			else RunSession.EndReason.HEALTH
		)
		run_session.record_defeat(reason)
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return
	if not run_session.record_victory(player):
		last_run_summary = run_session.get_summary()
		end_current_run(false)
		SceneManager.load_scene_by_name("game_over")
		return
	if run_session.is_complete():
		last_run_summary = run_session.get_summary()
		end_current_run(true)
		SceneManager.load_scene_by_name("run_complete")
	else:
		SceneManager.load_scene_by_name("between_fight_choice")


func get_last_run_summary() -> Dictionary:
	return last_run_summary.duplicate(true)

func end_current_run(victory: bool = false) -> void:
	GLog.debug("Ending run - Victory: " + str(victory))
	
	is_run_active = false
	var run_duration := (Time.get_ticks_msec() / 1000.0) - run_start_time
	
	save_run_statistics(victory, run_duration)
	
	# Clean up deck and duel system
	if is_instance_valid(DeckManager):
		DeckManager.clear_current_deck()
	pending_duel_config = null
	
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
	
	# Static class selection uses the class name as the run character name.
	if selected_character:
		run_statistics["character_name"] = selected_character.character_class_name
	else:
		run_statistics["character_name"] = current_character_class
	
	GLog.debug("Run statistics saved: " + str(run_statistics))
	
	# Save to run history for persistent tracking
	RunHistoryManager.add_run(run_statistics)

## Prepare a duel with the given enemy (from encounters, events, etc.)
func prepare_duel(enemy: Resource, context: String = "", modifiers: Dictionary = {}) -> bool:
	GLog.info("Preparing duel against enemy: %s" % (enemy.enemy_name if enemy and "enemy_name" in enemy else "Unknown"))
	
	if not is_instance_valid(enemy):
		GLog.error("GameManager: Cannot prepare duel - invalid enemy")
		return false
	
	if not is_instance_valid(DeckManager) or not DeckManager.is_deck_available():
		GLog.error("GameManager: Cannot prepare duel - no deck available")
		return false
	
	# Get current deck from DeckManager
	var player_deck = DeckManager.get_current_deck()
	if player_deck.is_empty():
		GLog.error("GameManager: Cannot prepare duel - player deck is empty")
		return false
	
	# Create duel configuration
	pending_duel_config = DuelConfig.new(player_deck, enemy, context, modifiers)
	
	if not pending_duel_config.is_valid():
		var errors = pending_duel_config.get_validation_errors()
		GLog.error("GameManager: Invalid duel config - " + str(errors))
		pending_duel_config = null
		return false
	
	GLog.debug("Duel prepared: %s" % str(pending_duel_config.get_summary()))
	return true

## Start the prepared duel (loads duel scene)
func start_prepared_duel() -> bool:
	if not is_instance_valid(pending_duel_config):
		GLog.error("GameManager: No duel prepared")
		return false
	
	if not pending_duel_config.is_valid():
		GLog.error("GameManager: Prepared duel config is invalid")
		return false
	
	GLog.info("Starting prepared duel")
	change_state(GameState.PLAYING)
	SceneManager.load_scene_by_name("duel")
	return true

## Convenience method: prepare and start duel immediately
func start_duel_with_enemy(enemy: Resource, context: String = "", modifiers: Dictionary = {}) -> bool:
	if prepare_duel(enemy, context, modifiers):
		return start_prepared_duel()
	return false

## Get the pending duel config (used by MainGameController)
func get_pending_duel_config() -> DuelConfig:
	return pending_duel_config

## Clear pending duel config (called after duel starts)
func clear_pending_duel_config() -> void:
	pending_duel_config = null
	GLog.debug("Pending duel config cleared")

## Check if a duel is prepared and ready to start
func is_duel_prepared() -> bool:
	return is_instance_valid(pending_duel_config) and pending_duel_config.is_valid()

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

func get_player_data():
	# PlayerData is stored in game_data["player"] when available
	return game_data.get("player", null)

func take_damage(amount: int) -> int:
	var player = get_player_data()
	if player and player.has_method("take_damage"):
		var actual: int = int(player.take_damage(amount))
		# Notify UI via EventBus if available
		if has_node("/root/EventBus") and player.stats:
			EventBus.health_changed.emit(player.stats.current_health, player.stats.max_health)
		# Track run stats
		run_statistics.damage_taken += actual
		return actual
	return 0

func heal(amount: int) -> void:
	var player = get_player_data()
	if player and player.has_method("heal"):
		player.heal(amount)
		if has_node("/root/EventBus") and player.stats:
			EventBus.health_changed.emit(player.stats.current_health, player.stats.max_health)

func add_corruption(amount: int) -> void:
	var updated := maxi(0, int(game_data.get("corruption", 0)) + amount)
	game_data["corruption"] = updated
	var player := get_player_data() as PlayerData
	if player:
		player.run_corruption = updated
	EventBus.corruption_changed.emit(amount)

func generate_all_maps() -> void:
	# Map generation placeholder for region selection
	game_data.completed_maps = []
	game_data.maps = {}
	GLog.info("Map generation initialized")

func select_map(region_id: String) -> void:
	if not game_data.maps.has(region_id):
		# Create a minimal entry so selection can proceed
		game_data.maps[region_id] = {"id": region_id, "completed": false}
		
	if region_id in game_data.completed_maps:
		GLog.warn("Trying to select already completed map: " + region_id)
		return
	
	game_data.current_map = region_id
	GLog.info("Selected map: " + region_id)

	# MVP routing: map exploration is disabled in quick duel mode.
	SceneManager.load_scene_by_name("quick_duel_setup")

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
		# MVP routing: map exploration is disabled in quick duel mode.
		SceneManager.load_scene_by_name("quick_duel_setup")

func is_game_paused() -> bool:
	return current_state == GameState.PAUSED

func can_pause() -> bool:
	return current_state == GameState.PLAYING

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_run_active and SaveSystem.autosave_enabled:
			SaveSystem.save_game(SaveSystem.AUTOSAVE_PATH, true)
		get_tree().quit()
