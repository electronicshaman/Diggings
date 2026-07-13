extends Node

const DEBUG_ENABLED: bool = true

const HISTORY_FILE_PATH: String = "user://run_history.json"
const MAX_HISTORY_ENTRIES: int = 100  # Keep last 100 runs

signal run_history_updated(run_data: Dictionary)
signal history_loaded()

var run_history: Dictionary = {"runs": []}
var is_loaded: bool = false

func _ready() -> void:
	name = "RunHistoryManager"
	GLog.debug("RunHistoryManager initialized - Chronicling the cosmic struggle")
	load_history()

func load_history() -> void:
	"""Load run history from persistent storage."""
	if not FileAccess.file_exists(HISTORY_FILE_PATH):
		GLog.debug("No run history file found, starting fresh")
		run_history = {"runs": []}
		is_loaded = true
		history_loaded.emit()
		return
	
	var file = FileAccess.open(HISTORY_FILE_PATH, FileAccess.READ)
	if file == null:
		GLog.error("Failed to open run history file: " + str(FileAccess.get_open_error()))
		run_history = {"runs": []}
		is_loaded = true
		history_loaded.emit()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		GLog.error("Failed to parse run history JSON: " + str(parse_result))
		run_history = {"runs": []}
		is_loaded = true
		history_loaded.emit()
		return
	
	var loaded_data = json.get_data()
	if loaded_data is Dictionary and loaded_data.has("runs"):
		run_history = loaded_data
		GLog.info("Loaded run history with " + str(run_history.runs.size()) + " entries")
	else:
		GLog.warn("Invalid run history format, starting fresh")
		run_history = {"runs": []}
	
	is_loaded = true
	history_loaded.emit()

func save_history() -> bool:
	"""Save run history to persistent storage."""
	var file = FileAccess.open(HISTORY_FILE_PATH, FileAccess.WRITE)
	if file == null:
		GLog.error("Failed to open run history file for writing: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = JSON.stringify(run_history, "\t")
	file.store_string(json_string)
	file.close()
	
	GLog.debug("Run history saved successfully")
	return true

func add_run(run_data: Dictionary) -> void:
	"""Add a completed run to the history.
	
	Args:
		run_data: Dictionary containing run statistics and details
	"""
	if not is_loaded:
		GLog.warn("Attempting to add run before history is loaded")
		return
	
	# Create a complete run record
	var run_record = {
		"id": generate_run_id(),
		"timestamp": Time.get_unix_time_from_system(),
		"seed": run_data.get("seed", 0),
		"hash_seed": run_data.get("hash_seed", ""),
		"character_class": run_data.get("character_class", ""),
		"victory": run_data.get("victory", false),
		"duration": run_data.get("duration", 0.0),
		"floor_reached": run_data.get("floor_reached", 0),
		"mode": run_data.get("mode", GameManager.GameMode.STANDARD),
		"character_name": run_data.get("character_name", ""),
		"cards_played": run_data.get("cards_played", 0),
		"damage_dealt": run_data.get("damage_dealt", 0),
		"damage_taken": run_data.get("damage_taken", 0),
		"gold_collected": run_data.get("gold_collected", 0),
		"enemies_defeated": run_data.get("enemies_defeated", 0),
		"elites_defeated": run_data.get("elites_defeated", 0),
		"bosses_defeated": run_data.get("bosses_defeated", 0),
		"turns_taken": run_data.get("turns_taken", 0),
		"perfect_battles": run_data.get("perfect_battles", 0),
		"cards_exhausted": run_data.get("cards_exhausted", 0),
		"cards_upgraded": run_data.get("cards_upgraded", 0),
		"shops_visited": run_data.get("shops_visited", 0),
		"rest_sites_visited": run_data.get("rest_sites_visited", 0),
		"events_encountered": run_data.get("events_encountered", 0)
	}
	
	# Add to beginning of array (most recent first)
	run_history.runs.push_front(run_record)
	
	# Trim history if too long
	if run_history.runs.size() > MAX_HISTORY_ENTRIES:
		run_history.runs = run_history.runs.slice(0, MAX_HISTORY_ENTRIES)
		GLog.debug("Trimmed run history to " + str(MAX_HISTORY_ENTRIES) + " entries")
	
	# Save to disk
	save_history()
	
	GLog.info("Added run to history: " + str(run_record.character_class) + " (" + str(run_record.hash_seed) + ") - Victory: " + str(run_record.victory))
	run_history_updated.emit(run_record)

func get_last_run() -> Dictionary:
	"""Get the most recent run from history.
	
	Returns:
		Dictionary containing the last run data, or empty dict if no runs
	"""
	if not is_loaded:
		GLog.warn("Attempting to get last run before history is loaded")
		return {}
	
	if run_history.runs.size() == 0:
		GLog.debug("No runs in history")
		return {}
	
	return run_history.runs[0]

func get_run_count() -> int:
	"""Get the total number of runs in history."""
	if not is_loaded:
		return 0
	return run_history.runs.size()

func get_runs_by_character(character_class: String) -> Array:
	"""Get all runs for a specific character class."""
	if not is_loaded:
		return []
	
	var character_runs = []
	for run in run_history.runs:
		if run.get("character_class", "") == character_class:
			character_runs.append(run)
	
	return character_runs

func get_victory_count() -> int:
	"""Get the total number of victorious runs."""
	if not is_loaded:
		return 0
	
	var victories = 0
	for run in run_history.runs:
		if run.get("victory", false):
			victories += 1
	
	return victories

func get_average_run_time() -> float:
	"""Get the average duration of all runs."""
	if not is_loaded or run_history.runs.size() == 0:
		return 0.0
	
	var total_time = 0.0
	for run in run_history.runs:
		total_time += run.get("duration", 0.0)
	
	return total_time / run_history.runs.size()

func clear_history() -> void:
	"""Clear all run history. Use with caution!"""
	run_history = {"runs": []}
	save_history()
	GLog.info("Run history cleared")

func generate_run_id() -> String:
	"""Generate a unique ID for a run."""
	var timestamp = Time.get_unix_time_from_system()
	var random_component = randi() % 10000  # non-gameplay identifier: unique run record ID, not a gameplay opportunity
	return str(timestamp) + "_" + str(random_component)

func has_previous_run() -> bool:
	"""Check if there's at least one run in history."""
	return is_loaded and run_history.runs.size() > 0

func get_last_run_seed() -> String:
	"""Get the hash seed from the most recent run.
	
	Returns:
		Hash seed string, or empty string if no runs available
	"""
	var last_run = get_last_run()
	return last_run.get("hash_seed", "")

func export_history_to_csv() -> String:
	"""Export run history to CSV format for analysis.
	
	Returns:
		CSV string containing all run data
	"""
	if not is_loaded:
		return ""
	
	var csv_lines = []
	
	# Header
	var headers = [
		"timestamp", "character_class", "character_name", "seed", "hash_seed",
		"victory", "duration", "floor_reached", "mode", "cards_played",
		"damage_dealt", "damage_taken", "gold_collected", "enemies_defeated",
		"elites_defeated", "bosses_defeated", "turns_taken", "perfect_battles"
	]
	csv_lines.append(",".join(headers))
	
	# Data rows
	for run in run_history.runs:
		var values = []
		for header in headers:
			values.append(str(run.get(header, "")))
		csv_lines.append(",".join(values))
	
	return "\n".join(csv_lines)