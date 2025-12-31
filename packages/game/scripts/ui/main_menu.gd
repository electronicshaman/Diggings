extends Control
class_name MainMenuController

@onready var new_game_button = $MenuContainer/NewGameButton
@onready var use_previous_seed_button = $MenuContainer/UsePreviousSeed
@onready var continue_button = $MenuContainer/ContinueButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var test_duel_button = $MenuContainer/TestDuelButton
@onready var quit_button = $MenuContainer/QuitButton

func _ready():
	setup_button_connections()
	check_save_file_exists()
	check_previous_seed_available()

func setup_button_connections():
	new_game_button.pressed.connect(_on_new_game_pressed)
	use_previous_seed_button.pressed.connect(_on_use_previous_seed_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	test_duel_button.pressed.connect(_on_test_duel_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func check_save_file_exists():
	# Enable/disable continue button based on save file existence
	var save_exists = SaveSystem.has_save_file()
	continue_button.disabled = not save_exists

func check_previous_seed_available():
	# Enable/disable use previous seed button based on whether a previous run exists in history
	var has_previous_run = RunHistoryManager.has_previous_run()
	use_previous_seed_button.disabled = not has_previous_run
	if has_previous_run:
		var last_run = RunHistoryManager.get_last_run()
		var seed = last_run.get("seed", 0)
		var hash_seed = last_run.get("hash_seed", "")
		var character = last_run.get("character_name", "Unknown")
		GLog.debug("Previous run available: " + character + " - Seed: " + str(seed) + " (" + hash_seed + ")")
	else:
		GLog.debug("No previous run available")

func _on_new_game_pressed():
	GLog.info("New Game button pressed")
	
	# Clear any custom seeds to ensure fresh auto-generation for new game
	# (These should only persist if player explicitly sets them in Settings menu)
	GameSettings.clear_custom_seeds()
	
	# Pre-establish seed for the new run (affects character generation)
	GameManager.prepare_new_run()
	
	# Transition to class selection
	SceneManager.load_scene_by_name("class_selection")

func _on_continue_pressed():
	GLog.info("Continue button pressed")
	if SaveSystem.load_game():
		# Continue with loaded game state
		GameManager.change_state(GameManager.GameState.PLAYING)
		SceneManager.load_scene_by_name("map")
	else:
		GLog.error("Failed to load save file")

func _on_settings_pressed():
	GLog.info("Settings button pressed")
	SceneManager.load_scene_by_name("settings")

func _on_use_previous_seed_pressed():
	GLog.info("Use Previous Seed button pressed")
	
	# Check if previous run is available
	if not RunHistoryManager.has_previous_run():
		GLog.warn("No previous run available to use")
		return
	
	var last_run = RunHistoryManager.get_last_run()
	var previous_hash_seed = last_run.get("hash_seed", "")
	var previous_seed = last_run.get("seed", 0)
	var character_name = last_run.get("character_name", "Unknown")
	
	if previous_hash_seed.is_empty():
		GLog.warn("Previous run has no valid hash seed")
		return
	
	# Set the previous seed as the custom seed for the next run
	GameSettings.custom_hash_seed = previous_hash_seed
	GameSettings.save_settings()
	
	GLog.info("Using previous seed from " + character_name + ": " + str(previous_seed) + " (Hash: " + previous_hash_seed + ")")
	
	# Pre-establish seed for the new run (affects character generation)
	GameManager.prepare_new_run()
	
	# Transition to class selection
	SceneManager.load_scene_by_name("class_selection")

func _on_test_duel_pressed():
	GLog.info("Test Duel button pressed")
	SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")

func _on_quit_pressed():
	GLog.info("Quit button pressed")
	get_tree().quit()
