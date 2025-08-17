extends Control

const DEBUG_ENABLED: bool = true

# UI References
@onready var back_button = $MainContainer/ButtonContainer/BackButton
@onready var custom_seed_input = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/CustomSeedContainer/CustomSeedInput
@onready var validate_button = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/CustomSeedContainer/ValidateButton
@onready var validation_label = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/ValidationLabel
@onready var show_seed_checkbox = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/ShowSeedCheckbox
@onready var last_seed_display = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/LastSeedContainer/LastSeedDisplay
@onready var copy_seed_button = $MainContainer/SettingsContainer/SettingsVBox/SeedSettings/LastSeedContainer/CopySeedButton

func _ready():
	# Connect UI signals
	back_button.pressed.connect(_on_back_pressed)
	validate_button.pressed.connect(_on_validate_seed)
	copy_seed_button.pressed.connect(_on_copy_seed)
	custom_seed_input.text_changed.connect(_on_seed_input_changed)
	show_seed_checkbox.toggled.connect(_on_show_seed_toggled)
	
	# Load current settings
	load_current_settings()
	
	GLog.debug("Settings UI initialized")

func load_current_settings():
	"""Load current settings from GameSettings."""
	custom_seed_input.text = GameSettings.custom_seed
	show_seed_checkbox.button_pressed = GameSettings.show_seed_in_ui
	
	# Display last used seed (use hash seed for consistency with other UI)
	if not GameSettings.last_used_hash_seed.is_empty():
		last_seed_display.text = GameSettings.last_used_hash_seed
		copy_seed_button.disabled = false
	else:
		last_seed_display.text = "None"
		copy_seed_button.disabled = true
		
	# Validate current input
	_validate_current_input()

func _on_back_pressed():
	# Save settings before leaving
	save_all_settings()
	SceneManager.load_scene_by_name("main_menu")

func _on_validate_seed():
	"""Validate the current seed input and show feedback."""
	_validate_current_input()

func _on_seed_input_changed(new_text: String):
	"""Handle seed input changes."""
	# Auto-validate as user types (with slight delay to avoid spam)
	get_tree().create_timer(0.5).timeout.connect(_validate_current_input)

func _on_show_seed_toggled(button_pressed: bool):
	"""Handle show seed checkbox changes."""
	GameSettings.show_seed_in_ui = button_pressed
	GLog.debug("Show seed in UI: " + str(button_pressed))

func _on_copy_seed():
	"""Copy the last used hash seed to clipboard and custom seed input."""
	if not GameSettings.last_used_hash_seed.is_empty():
		var seed_text = GameSettings.last_used_hash_seed
		DisplayServer.clipboard_set(seed_text)
		custom_seed_input.text = seed_text
		GameSettings.custom_hash_seed = seed_text  # Set hash seed since we're copying a hash
		GameSettings.custom_seed = ""  # Clear regular seed since hash takes precedence
		
		# Show temporary feedback
		_show_validation_message("Seed copied to clipboard and input field!", Color.GREEN)
		GLog.debug("Copied seed to clipboard: " + seed_text)

func _validate_current_input():
	"""Validate the current seed input and update UI feedback."""
	var input_text = custom_seed_input.text.strip_edges()
	
	# Determine if this is a hash seed or regular seed and update GameSettings appropriately
	if input_text.is_empty():
		GameSettings.custom_seed = ""
		GameSettings.custom_hash_seed = ""
		_show_validation_message("Empty seed will generate random seed for each run", Color.WHITE)
		return
	
	# Check if it's a valid hash seed (10 alphanumeric characters)
	if SeedManager.validate_hash_seed(input_text.to_upper()):
		GameSettings.custom_hash_seed = input_text.to_upper()
		GameSettings.custom_seed = ""  # Clear regular seed since hash takes precedence
		var is_thematic = SeedManager.is_thematic_seed(input_text.to_upper())
		if is_thematic:
			_show_validation_message("Valid thematic hash seed! ✨", Color.GREEN)
		else:
			_show_validation_message("Valid hash seed!", Color.GREEN)
	elif SeedManager.validate_seed_input(input_text):
		# It's a regular seed (integer or string to be hashed)
		GameSettings.custom_seed = input_text
		GameSettings.custom_hash_seed = ""  # Clear hash seed
		if input_text.is_valid_int():
			_show_validation_message("Valid integer seed!", Color.GREEN)
		else:
			_show_validation_message("Valid string seed (will be hashed)!", Color.GREEN)
	else:
		_show_validation_message("Invalid seed input", Color.RED)

func _show_validation_message(message: String, color: Color):
	"""Display a validation message with color."""
	validation_label.text = message
	validation_label.modulate = color
	
	# Reset to default color after a few seconds
	if color != Color.WHITE:
		get_tree().create_timer(3.0).timeout.connect(func():
			validation_label.modulate = Color(0.8, 0.8, 0.8, 1)
		)

func save_all_settings():
	"""Save all current settings."""
	GameSettings.save_settings()
	GLog.debug("All settings saved")