extends EncounterOutcome
class_name CurioReward

const OUTCOME_NAME := "CurioReward"

@export var curio_paths: Array[String] = []
@export var random_curio: bool = false
@export var curio_rarity: String = "Common"
@export var remove_curio: bool = false

func apply_outcome(encounter_manager: Node, game_state: Dictionary, _context: Dictionary = {}) -> void:
	if remove_curio:
		_handle_curio_removal(encounter_manager, game_state)
	else:
		_handle_curio_addition(encounter_manager, game_state)

func _handle_curio_addition(encounter_manager: Node, game_state: Dictionary) -> void:
	var curio_to_add = null
	
	if random_curio:
		curio_to_add = _get_random_curio(game_state, encounter_manager.curio_manager)
	elif not curio_paths.is_empty():
		var path = curio_paths[0]
		if ResourceLoader.exists(path):
			curio_to_add = load(path)
	
	if curio_to_add and encounter_manager.curio_manager:
		encounter_manager.curio_manager.add_curio(curio_to_add)
		GLog.debug("Added curio: %s" % curio_to_add.curio_name)

func _handle_curio_removal(encounter_manager: Node, _game_state: Dictionary) -> void:
	if encounter_manager.event_bus:
		encounter_manager.event_bus.ui_popup_opened.emit("curio_removal")
	
	GLog.debug("Opened curio removal interface")

func _get_random_curio(game_state: Dictionary, curio_manager: Node) -> Resource:
	var base_path = "res://data/curios/"
	var rarity_folders = {
		"Common": "common/",
		"Rare": "rare/",
		"Legendary": "legendary/",
		"Corrupted": "corrupted/",
		"Starting": "starting/"
	}
	
	var folder = rarity_folders.get(curio_rarity, "common/")
	var character_class = game_state.get("character_class", "")
	
	return _load_random_curio_from_folder(base_path + folder, character_class, curio_manager)

func _load_random_curio_from_folder(folder_path: String, character_class: String, curio_manager: Node) -> Resource:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return null
	
	var valid_curios = []
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var curio_path = folder_path + file_name
			var curio = load(curio_path)
			if curio:
				var synergy = curio.get_synergy_for_class(character_class)
				if synergy >= 0.5:
					if not curio_manager or not curio_manager.has_curio(curio.curio_name):
						valid_curios.append(curio)
		file_name = dir.get_next()
	
	if valid_curios.is_empty():
		return null
	
	return valid_curios[randi() % valid_curios.size()]

func get_formatted_description() -> String:
	if remove_curio:
		return "Remove a curio"
	elif random_curio:
		return "Gain a random %s curio" % curio_rarity
	elif not curio_paths.is_empty():
		var curio_name = curio_paths[0].get_file().get_basename().replace("_", " ").capitalize()
		return "Gain %s" % curio_name
	return "Gain a curio"

func get_preview_text() -> String:
	if remove_curio:
		return "Remove curio"
	elif random_curio:
		return "+%s curio" % curio_rarity
	else:
		return "+Curio"

func is_positive() -> bool:
	return not remove_curio

func get_outcome_name() -> String:
	return OUTCOME_NAME
