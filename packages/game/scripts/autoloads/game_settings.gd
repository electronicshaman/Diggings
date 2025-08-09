extends Node

const DEBUG_ENABLED: bool = true

signal settings_changed(setting_name: String, value: Variant)

@export_group("Audio Settings")
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var sfx_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 1.0

@export_group("Video Settings")
var fullscreen: bool = false
var vsync: bool = true
var resolution: Vector2i = Vector2i(1920, 1080)

@export_group("Gameplay Settings")
@export_range(0.5, 3.0) var game_speed: float = 1.0
var auto_end_turn: bool = false
var show_damage_numbers: bool = true
var screen_shake: bool = true
var particle_effects: bool = true

@export_group("Game Settings")
@export_range(1, 5) var difficulty: int = 1
var tutorial_completed: bool = false
var statistics_tracking: bool = true

var settings_file_path: String = "user://settings.cfg"

func _ready() -> void:
	GLog.debug("GameSettings initialized")
	load_settings()

func save_settings() -> void:
	var config := ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.set_value("video", "resolution", resolution)
	
	config.set_value("gameplay", "game_speed", game_speed)
	config.set_value("gameplay", "auto_end_turn", auto_end_turn)
	config.set_value("gameplay", "show_damage_numbers", show_damage_numbers)
	config.set_value("gameplay", "screen_shake", screen_shake)
	config.set_value("gameplay", "particle_effects", particle_effects)
	
	config.set_value("game", "difficulty", difficulty)
	config.set_value("game", "tutorial_completed", tutorial_completed)
	config.set_value("game", "statistics_tracking", statistics_tracking)
	
	var error := config.save(settings_file_path)
	if error != OK:
		GLog.error("Failed to save settings: " + str(error))
	else:
		GLog.debug("Settings saved successfully")

func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_file_path)
	
	if error != OK:
		GLog.warn("No settings file found, using defaults")
		save_settings()
		return
	
	master_volume = config.get_value("audio", "master_volume", master_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	vsync = config.get_value("video", "vsync", vsync)
	resolution = config.get_value("video", "resolution", resolution)
	
	game_speed = config.get_value("gameplay", "game_speed", game_speed)
	auto_end_turn = config.get_value("gameplay", "auto_end_turn", auto_end_turn)
	show_damage_numbers = config.get_value("gameplay", "show_damage_numbers", show_damage_numbers)
	screen_shake = config.get_value("gameplay", "screen_shake", screen_shake)
	particle_effects = config.get_value("gameplay", "particle_effects", particle_effects)
	
	difficulty = config.get_value("game", "difficulty", difficulty)
	tutorial_completed = config.get_value("game", "tutorial_completed", tutorial_completed)
	statistics_tracking = config.get_value("game", "statistics_tracking", statistics_tracking)
	
	GLog.debug("Settings loaded successfully")
	apply_settings()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	
	Engine.time_scale = game_speed

func set_setting(setting_name: String, value: Variant) -> void:
	set(setting_name, value)
	settings_changed.emit(setting_name, value)
	save_settings()
	apply_settings()

func reset_to_defaults() -> void:
	master_volume = 1.0
	sfx_volume = 1.0
	music_volume = 1.0
	fullscreen = false
	vsync = true
	resolution = Vector2i(1920, 1080)
	game_speed = 1.0
	auto_end_turn = false
	show_damage_numbers = true
	screen_shake = true
	particle_effects = true
	difficulty = 1
	tutorial_completed = false
	statistics_tracking = true
	
	save_settings()
	apply_settings()
	GLog.debug("Settings reset to defaults")