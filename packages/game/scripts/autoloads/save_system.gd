extends Node

const DEBUG_ENABLED: bool = true

const SAVE_VERSION: String = "1.0.0"
const SAVE_FILE_PATH: String = "user://savegame.dat"
const AUTOSAVE_PATH: String = "user://autosave.dat"
const SAVE_ENCRYPTION_KEY: String = "TheRushBeginsInDarkness"

signal save_completed(success: bool)
signal load_completed(success: bool)
signal save_deleted(slot: int)

var current_save_data: Dictionary = {}
var autosave_enabled: bool = true
var autosave_interval: float = 60.0
var autosave_timer: Timer

func _ready() -> void:
	GLog.debug("SaveSystem initialized - Preserving reality across dimensions")
	setup_autosave()

func setup_autosave() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = autosave_interval
	autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(autosave_timer)
	
	if autosave_enabled:
		autosave_timer.start()

func _on_autosave_timeout() -> void:
	if autosave_enabled:
		GLog.debug("Autosaving...")
		save_game(AUTOSAVE_PATH, true)

func save_game(path: String = SAVE_FILE_PATH, is_autosave: bool = false) -> bool:
	var save_data := create_save_data()
	
	var file := FileAccess.open_encrypted_with_pass(path, 
		FileAccess.WRITE, SAVE_ENCRYPTION_KEY)
	
	if file == null:
		GLog.error("Failed to open save file: " + str(FileAccess.get_open_error()))
		save_completed.emit(false)
		return false
	
	file.store_var(save_data)
	file.close()
	
	if not is_autosave:
		current_save_data = save_data
		EventBus.emit_ui_notification("Game Saved", "success")
	
	GLog.debug("Game saved successfully to: " + path)
	save_completed.emit(true)
	return true

func load_game(path: String = SAVE_FILE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		GLog.warn("Save file does not exist: " + path)
		load_completed.emit(false)
		return false
	
	var file := FileAccess.open_encrypted_with_pass(path, 
		FileAccess.READ, SAVE_ENCRYPTION_KEY)
	
	if file == null:
		GLog.error("Failed to open save file: " + str(FileAccess.get_open_error()))
		load_completed.emit(false)
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if not validate_save_data(save_data):
		GLog.error("Invalid save data structure")
		load_completed.emit(false)
		return false
	
	if save_data.get("version", "") != SAVE_VERSION:
		GLog.warn("Save version mismatch. Attempting migration...")
		save_data = migrate_save_data(save_data)
	
	apply_save_data(save_data)
	current_save_data = save_data
	
	EventBus.emit_ui_notification("Game Loaded", "success")
	GLog.debug("Game loaded successfully from: " + path)
	load_completed.emit(true)
	return true

func create_save_data() -> Dictionary:
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"run_data": gather_run_data(),
		"player_data": gather_player_data(),
		"deck_data": gather_deck_data(),
		"map_data": gather_map_data(),
		"statistics": gather_statistics(),
		"unlocks": gather_unlocks()
	}
	
	GLog.debug("Save data created with " + str(save_data.size()) + " sections")
	return save_data

func gather_run_data() -> Dictionary:
	return {
		"seed": 0,
		"floor": 0,
		"act": 1,
		"gold": 0,
		"corruption": 0,
		"difficulty": GameSettings.difficulty if is_instance_valid(GameSettings) else 1,
		"character_class": "",
		"time_played": 0.0
	}

func gather_player_data() -> Dictionary:
	return {
		"health": 100,
		"max_health": 100,
		"sanity": 100,
		"max_sanity": 100,
		"energy": 3,
		"max_energy": 3,
		"block": 0,
		"statuses": []
	}

func gather_deck_data() -> Dictionary:
	return {
		"deck": [],
		"removed_cards": [],
		"upgraded_cards": [],
		"card_uses": {}
	}

func gather_map_data() -> Dictionary:
	return {
		"current_node": "",
		"visited_nodes": [],
		"available_paths": [],
		"boss_identity": ""
	}

func gather_statistics() -> Dictionary:
	return {
		"cards_played": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"gold_collected": 0,
		"enemies_defeated": 0,
		"elites_defeated": 0,
		"bosses_defeated": 0
	}

func gather_unlocks() -> Dictionary:
	return {
		"unlocked_cards": [],
		"unlocked_characters": [],
		"unlocked_curios": [],
		"achievements": []
	}

func apply_save_data(save_data: Dictionary) -> void:
	GLog.debug("Applying save data...")
	
	if save_data.has("run_data"):
		apply_run_data(save_data.run_data)
	
	if save_data.has("player_data"):
		apply_player_data(save_data.player_data)
	
	if save_data.has("deck_data"):
		apply_deck_data(save_data.deck_data)
	
	if save_data.has("map_data"):
		apply_map_data(save_data.map_data)
	
	if save_data.has("statistics"):
		apply_statistics(save_data.statistics)
	
	if save_data.has("unlocks"):
		apply_unlocks(save_data.unlocks)

func apply_run_data(_data: Dictionary) -> void:
	pass

func apply_player_data(_data: Dictionary) -> void:
	pass

func apply_deck_data(_data: Dictionary) -> void:
	pass

func apply_map_data(_data: Dictionary) -> void:
	pass

func apply_statistics(_data: Dictionary) -> void:
	pass

func apply_unlocks(_data: Dictionary) -> void:
	pass

func validate_save_data(save_data: Variant) -> bool:
	if not save_data is Dictionary:
		return false
	
	var required_keys := ["version", "timestamp", "run_data", "player_data"]
	for key in required_keys:
		if not save_data.has(key):
			GLog.error("Missing required save key: " + key)
			return false
	
	return true

func migrate_save_data(save_data: Dictionary) -> Dictionary:
	GLog.warn("Migrating save data from version: " + save_data.get("version", "unknown"))
	save_data["version"] = SAVE_VERSION
	return save_data

func delete_save(path: String = SAVE_FILE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		GLog.debug("Save file deleted: " + path)
		EventBus.emit_ui_notification("Save Deleted", "info")

func has_save_file(path: String = SAVE_FILE_PATH) -> bool:
	return FileAccess.file_exists(path)

func get_save_info(path: String = SAVE_FILE_PATH) -> Dictionary:
	if not has_save_file(path):
		return {}
	
	if load_game(path):
		return current_save_data
	
	return {}

func quick_save() -> void:
	save_game()

func quick_load() -> void:
	load_game()