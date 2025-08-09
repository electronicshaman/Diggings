extends Control
class_name MainMenuController

@onready var new_game_button = $MenuContainer/NewGameButton
@onready var continue_button = $MenuContainer/ContinueButton
@onready var settings_button = $MenuContainer/SettingsButton
@onready var quit_button = $MenuContainer/QuitButton

func _ready():
	setup_button_connections()
	check_save_file_exists()

func setup_button_connections():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func check_save_file_exists():
	# Enable/disable continue button based on save file existence
	var save_exists = SaveSystem.has_save_file()
	continue_button.disabled = not save_exists

func _on_new_game_pressed():
	GLog.info("New Game button pressed")
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

func _on_quit_pressed():
	GLog.info("Quit button pressed")
	get_tree().quit()