extends "res://scripts/handlers/core/handler_base.gd"
class_name CurioRewardHandler

@export var curio_paths: Array[String] = []
@export var random_curio: bool = false
@export var curio_rarity: String = "Common"
@export var remove_curio: bool = false


func apply_effect(context):
	var result = HandlerResult.new()
	if remove_curio:
		# Open a UI for curio removal via EventBus if available (non-blocking effect)
		var eb = null
		if context and context.game_manager and context.game_manager.has_method("get_node_or_null"):
			eb = context.game_manager.get_node_or_null("/root/EventBus")
		if eb:
			eb.emit_signal("ui_popup_opened", "curio_removal")
		result.success = true
		result.ui_feedback = {"message": "Remove a curio"}
		return result
	# Addition path
	var curio_to_add = null
	var curio_manager = null
	if context and context.game_manager and context.game_manager.has_method("get_node_or_null"):
		curio_manager = context.game_manager.get_node_or_null("/root/CurioManager")
	if random_curio:
		curio_to_add = _get_random_curio(context, curio_manager)
	elif not curio_paths.is_empty():
		var path = curio_paths[0]
		if ResourceLoader.exists(path):
			curio_to_add = load(path)
	if curio_to_add and curio_manager and curio_manager.has_method("add_curio"):
		curio_manager.add_curio(curio_to_add)
		result.values_applied["curio"] = curio_to_add.resource_path
		result.success = true
		result.ui_feedback = {"message": "Gained curio"}
		return result
	result.success = false
	result.prevented_by = "no_curio"
	return result

func _get_random_curio(context, curio_manager):
	var base_path = "res://data/curios/"
	var rarity_folders = {
		"Common": "common/",
		"Rare": "rare/",
		"Legendary": "legendary/",
		"Corrupted": "corrupted/",
		"Starting": "starting/"
	}
	var folder = rarity_folders.get(curio_rarity, "common/")
	var character_class = ""
	if context and context.game_manager and "current_character_class" in context.game_manager:
		character_class = context.game_manager.current_character_class
	return _load_random_curio_from_folder(base_path + folder, character_class, curio_manager)

func _load_random_curio_from_folder(folder_path: String, character_class: String, curio_manager) -> Resource:
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
				var include = true
				if curio.has_method("get_synergy_for_class"):
					var synergy = curio.get_synergy_for_class(character_class)
					include = synergy >= 0.5
				if include:
					var already_has = false
					if curio_manager and curio_manager.has_method("has_curio"):
						already_has = curio_manager.has_curio(curio.curio_name)
					if not already_has:
						valid_curios.append(curio)
		file_name = dir.get_next()
	if valid_curios.is_empty():
		return null
	return valid_curios[randi() % valid_curios.size()]
