extends Node

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
var current_character_class: String = ""
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
		"map": null
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

func start_new_run(character_class: String, custom_seed: Variant = null, mode: GameMode = GameMode.STANDARD) -> void:
	GLog.debug("Starting new run with class: " + character_class)
	
	# Use custom seed if provided, otherwise use GameSettings custom seed, otherwise auto-generate
	var seed_to_use = custom_seed
	if seed_to_use == null:
		seed_to_use = GameSettings.custom_seed if not GameSettings.custom_seed.is_empty() else null
	
	# Initialize the seed system for this run
	var final_seed = SeedManager.set_master_seed(seed_to_use)
	SeedManager.start_run(seed_to_use)
	
	current_run_seed = final_seed
	current_character_class = character_class
	current_mode = mode
	is_run_active = true
	run_start_time = Time.get_ticks_msec() / 1000.0
	
	# Store the seed used for this run
	GameSettings.last_used_seed = final_seed
	GameSettings.save_settings()
	
	initialize_game_data()
	reset_run_statistics()
	
	change_state(GameState.PLAYING)
	EventBus.game_started.emit()
	
	SceneManager.load_scene_by_name("map")

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
	run_statistics["mode"] = current_mode
	run_statistics["floor_reached"] = game_data.get("current_floor", 0)
	run_statistics["timestamp"] = Time.get_unix_time_from_system()
	
	GLog.debug("Run statistics saved: " + str(run_statistics))

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

func is_game_paused() -> bool:
	return current_state == GameState.PAUSED

func can_pause() -> bool:
	return current_state == GameState.PLAYING

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_run_active and SaveSystem.autosave_enabled:
			SaveSystem.save_game(SaveSystem.AUTOSAVE_PATH, true)
		get_tree().quit()