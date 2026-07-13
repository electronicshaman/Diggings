extends Node

const DEBUG_ENABLED: bool = true

signal scene_loaded(scene_path: String)
signal scene_unloaded(scene_path: String)
signal transition_started()
signal transition_finished()

var current_scene: Node = null
var is_transitioning: bool = false
var loaded_scenes: Dictionary = {}

## Pending intent to be consumed by the target scene
var pending_intent: SceneIntent = null

const TRANSITION_DURATION: float = 0.5
const SCENE_PATHS: Dictionary = {
	"main_menu": "res://scenes/ui/main_menu.tscn",
	"class_selection": "res://scenes/ui/class_selection.tscn",
	"duel": "res://scenes/game/duel.tscn",
	"quick_duel_setup": "res://scenes/game/quick_duel_setup.tscn",
	"game_over": "res://scenes/ui/game_over.tscn",
	"between_fight_choice": "res://scenes/ui/between_fight_choice.tscn",

	"settings": "res://scenes/ui/settings.tscn",
	"deck_viewer": "res://scenes/ui/deck_viewer.tscn",
	"deck_management": "res://scenes/ui/deck_management.tscn",
	"run_complete": "res://scenes/ui/run_complete.tscn"
}

var transition_overlay: ColorRect

func _ready() -> void:
	GLog.debug("SceneManager initialized - Portal between worlds established")
	setup_transition_overlay()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var root := get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func setup_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.name = "TransitionOverlay"
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_overlay.z_index = 1000
	
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "TransitionLayer"
	canvas_layer.layer = 100
	canvas_layer.add_child(transition_overlay)
	add_child(canvas_layer)

func load_scene(scene_path: String, with_transition: bool = true) -> void:
	if is_transitioning:
		GLog.warn("Scene transition already in progress")
		return
	
	if not ResourceLoader.exists(scene_path):
		GLog.error("Scene does not exist: " + scene_path)
		return
	
	GLog.debug("Loading scene: " + scene_path)
	is_transitioning = true
	
	if with_transition:
		await fade_out()
	
	await _change_scene(scene_path)
	
	if with_transition:
		await fade_in()
	
	is_transitioning = false
	scene_loaded.emit(scene_path)
	EventBus.scene_transition_completed.emit(scene_path)

func load_scene_by_name(scene_name: String, with_transition: bool = true) -> void:
	if SCENE_PATHS.has(scene_name):
		load_scene(SCENE_PATHS[scene_name], with_transition)
	else:
		GLog.error("Unknown scene name: " + scene_name)

## Load a scene with an intent providing typed parameters
func load_scene_with_intent(scene_path: String, intent: SceneIntent, with_transition: bool = true) -> void:
	pending_intent = intent
	GLog.debug("Loading scene with intent: %s -> %s" % [intent.get_intent_type(), scene_path])
	load_scene(scene_path, with_transition)

## Load a named scene with an intent
func load_scene_by_name_with_intent(scene_name: String, intent: SceneIntent, with_transition: bool = true) -> void:
	if SCENE_PATHS.has(scene_name):
		load_scene_with_intent(SCENE_PATHS[scene_name], intent, with_transition)
	else:
		GLog.error("Unknown scene name: " + scene_name)

## Get and consume the pending intent (returns null if none)
func get_pending_intent() -> SceneIntent:
	var intent = pending_intent
	pending_intent = null
	return intent

## Check if there's a pending intent without consuming it
func has_pending_intent() -> bool:
	return pending_intent != null

func _change_scene(scene_path: String) -> void:
	transition_started.emit()
	EventBus.scene_transition_started.emit(scene_path)
	
	call_deferred("_deferred_change_scene", scene_path)
	await get_tree().process_frame

func _deferred_change_scene(scene_path: String) -> void:
	if current_scene:
		scene_unloaded.emit(current_scene.scene_file_path)
		current_scene.queue_free()
	
	var new_scene := load(scene_path) as PackedScene
	if new_scene:
		current_scene = new_scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		EventBus.scene_loaded.emit(current_scene)
	else:
		GLog.error("Failed to load scene: " + scene_path)

func reload_current_scene(with_transition: bool = true) -> void:
	if current_scene and current_scene.scene_file_path:
		load_scene(current_scene.scene_file_path, with_transition)
	else:
		GLog.error("No current scene to reload")

func fade_out(duration: float = TRANSITION_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = TRANSITION_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, duration)
	await tween.finished

func preload_scene(scene_path: String) -> void:
	if loaded_scenes.has(scene_path):
		return
	
	if not ResourceLoader.exists(scene_path):
		GLog.error("Cannot preload - scene does not exist: " + scene_path)
		return
	
	GLog.debug("Preloading scene: " + scene_path)
	var scene := load(scene_path) as PackedScene
	if scene:
		loaded_scenes[scene_path] = scene

func preload_common_scenes() -> void:
	var scenes_to_preload := [
		"quick_duel_setup",
		"duel",
		"game_over",

	]
	
	for scene_name in scenes_to_preload:
		if SCENE_PATHS.has(scene_name):
			preload_scene(SCENE_PATHS[scene_name])

func clear_preloaded_scenes() -> void:
	loaded_scenes.clear()
	GLog.debug("Cleared all preloaded scenes")

func get_current_scene_name() -> String:
	if not current_scene:
		return ""
	
	for key in SCENE_PATHS:
		if SCENE_PATHS[key] == current_scene.scene_file_path:
			return key
	
	return current_scene.scene_file_path

func add_persistent_node(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(node)
	GLog.debug("Added persistent node: " + node.name)

func remove_persistent_node(node: Node) -> void:
	if node.get_parent() == self:
		remove_child(node)
		GLog.debug("Removed persistent node: " + node.name)

func transition_to_main_menu() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	load_scene_by_name("main_menu")

func transition_to_game() -> void:
	load_scene_by_name("quick_duel_setup")

func transition_to_game_over() -> void:
	load_scene_by_name("game_over")
