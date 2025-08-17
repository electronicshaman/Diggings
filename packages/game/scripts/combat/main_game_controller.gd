extends Node2D

const DEBUG_ENABLED: bool = true

# Core controllers - safely referenced
@onready var duel_manager: Node = $DuelManager
@onready var game_controller: Node = $GameController
@onready var ui_controller: Node = $UIController
@onready var input_controller: Node = $InputController

# UI Reference Manager for safe UI access
var ui_manager: UIReferenceManager
var is_initialized: bool = false

# Quick access nodes that need direct references for critical functionality
var win_duel_button: Button
var lose_duel_button: Button

func _ready() -> void:
	GLog.debug("MainGameController awakened - The orchestrator of chaos")
	await get_tree().process_frame
	
	if _initialize_ui_manager() != OK:
		push_error("MainGameController: Failed to initialize UI manager")
		return
	
	initialize_controllers()

func _initialize_ui_manager() -> Error:
	ui_manager = UIReferenceManager.new()
	var result = ui_manager.initialize(self)
	
	if result != OK:
		push_error("MainGameController: UI manager initialization failed")
		return result
	
	# Cache critical buttons for direct access
	win_duel_button = get_node_or_null("UI/Control/TurnInfo/WinDuel")
	lose_duel_button = get_node_or_null("UI/Control/TurnInfo/LoseDuel")
	
	if not is_instance_valid(win_duel_button):
		push_warning("MainGameController: Win duel button not found")
	if not is_instance_valid(lose_duel_button):
		push_warning("MainGameController: Lose duel button not found")
	
	GLog.debug("MainGameController: UI manager initialized successfully")
	return OK

func initialize_controllers() -> void:
	if is_initialized:
		return
	
	if not is_instance_valid(game_controller):
		push_error("MainGameController: GameController is invalid")
		return
	
	if not is_instance_valid(duel_manager):
		push_error("MainGameController: DuelManager is invalid")
		return
	
	game_controller.initialize(duel_manager)
	
	var ui_references := get_ui_references()
	if ui_references.is_empty():
		push_warning("MainGameController: No UI references available")
	
	if is_instance_valid(ui_controller):
		ui_controller.initialize(ui_references, game_controller)
	else:
		push_error("MainGameController: UIController is invalid")
		return
	
	var end_turn_btn = ui_manager.get_ui_node("end_turn_button")
	if is_instance_valid(input_controller):
		input_controller.initialize(game_controller, ui_controller, end_turn_btn)
	else:
		push_error("MainGameController: InputController is invalid")
		return
	
	setup_connections()
	is_initialized = true
	GLog.debug("All controllers initialized and connected")

func get_ui_references() -> Dictionary:
	if not ui_manager:
		push_error("MainGameController: UI manager not initialized")
		return {}
	
	return ui_manager.get_ui_reference_dictionary()

func setup_connections() -> void:
	if is_instance_valid(game_controller):
		if game_controller.has_signal("duel_started"):
			game_controller.duel_started.connect(_on_duel_started_signal)
		if game_controller.has_signal("duel_ended"):
			game_controller.duel_ended.connect(_on_duel_ended_signal)
	
	if is_instance_valid(ui_controller):
		if ui_controller.has_signal("ui_refresh_requested"):
			ui_controller.ui_refresh_requested.connect(_on_ui_refresh_requested)
		else:
			push_warning("MainGameController: ui_refresh_requested signal not found on UIController")
	
	if is_instance_valid(input_controller):
		if input_controller.has_signal("input_action_triggered"):
			input_controller.input_action_triggered.connect(_on_input_action_triggered)
		else:
			push_warning("MainGameController: input_action_triggered signal not found on InputController")
	
	# Connect testing buttons safely
	if is_instance_valid(win_duel_button):
		win_duel_button.pressed.connect(_on_win_duel_pressed)
	else:
		push_warning("MainGameController: Cannot connect win_duel_button - button is invalid")
		
	if is_instance_valid(lose_duel_button):
		lose_duel_button.pressed.connect(_on_lose_duel_pressed)
	else:
		push_warning("MainGameController: Cannot connect lose_duel_button - button is invalid")

	# When an actual duel ends, transition appropriately
	if is_instance_valid(duel_manager) and duel_manager.has_signal("duel_ended"):
		duel_manager.duel_ended.connect(_on_duel_ended_from_manager)
	else:
		push_warning("MainGameController: Cannot connect to duel_ended signal")

func _on_duel_started_signal() -> void:
	GLog.debug("Duel started - game ready")
	EventBus.emit_ui_notification("Duel Started", "success")

func _on_ui_refresh_requested() -> void:
	pass

func _on_input_action_triggered(action: String) -> void:
	GLog.debug("Input action: " + action)
	EventBus.emit_game_event("input_" + action)

func _on_win_duel_pressed() -> void:
	GLog.debug("Test win button pressed - ending duel as player victory")
	if is_instance_valid(duel_manager) and duel_manager.has_method("end_duel"):
		duel_manager.end_duel("player")
	else:
		push_warning("MainGameController: Cannot end duel - DuelManager is invalid or missing method")
	
	# Return to map after a brief delay
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene"):
		SceneManager.load_scene("res://scenes/hexmap/Hexmap.tscn")
	else:
		push_error("MainGameController: Cannot load map scene - SceneManager unavailable")

func _on_lose_duel_pressed() -> void:
	GLog.debug("Test lose button pressed - ending duel as player defeat")
	if is_instance_valid(duel_manager) and duel_manager.has_method("end_duel"):
		duel_manager.end_duel("enemy")
	else:
		push_warning("MainGameController: Cannot end duel - DuelManager is invalid or missing method")
	
	# Go to game over after a brief delay
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene"):
		SceneManager.load_scene("res://scenes/ui/game_over.tscn")
	else:
		push_error("MainGameController: Cannot load game over scene - SceneManager unavailable")

func _on_duel_ended_signal(victory: bool) -> void:
	GLog.debug("Duel ended (from GameController) - Victory: " + str(victory))
	await get_tree().create_timer(0.6).timeout
	if victory:
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("map")
		else:
			push_error("MainGameController: Cannot load map scene on duel end - SceneManager unavailable")
	else:
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("game_over")
		else:
			push_error("MainGameController: Cannot load game over scene on duel end - SceneManager unavailable")

func _on_duel_ended_from_manager(winner: String) -> void:
	GLog.debug("Duel ended (signal) - Winner: " + winner)
	await get_tree().create_timer(0.6).timeout
	if winner == "player":
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("map")
		else:
			push_error("MainGameController: Cannot load map scene on duel end - SceneManager unavailable")
	else:
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("game_over")
		else:
			push_error("MainGameController: Cannot load game over scene on duel end - SceneManager unavailable")

func get_game_controller() -> Node:
	if is_instance_valid(game_controller):
		return game_controller
	push_warning("MainGameController: GameController is invalid")
	return null

func get_ui_controller() -> Node:
	if is_instance_valid(ui_controller):
		return ui_controller
	push_warning("MainGameController: UIController is invalid")
	return null

func get_input_controller() -> Node:
	if is_instance_valid(input_controller):
		return input_controller
	push_warning("MainGameController: InputController is invalid")
	return null

func get_duel_manager() -> Node:
	if is_instance_valid(duel_manager):
		return duel_manager
	push_warning("MainGameController: DuelManager is invalid")
	return null

## Get UI manager for external access to UI references
func get_ui_manager() -> UIReferenceManager:
	return ui_manager

## Refresh UI cache - useful when UI structure changes during runtime
func refresh_ui_references() -> void:
	if ui_manager:
		ui_manager.clear_cache()
		GLog.debug("MainGameController: UI references refreshed")
	else:
		push_warning("MainGameController: Cannot refresh UI - UI manager not initialized")
