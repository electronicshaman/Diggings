extends Node

const DEBUG_ENABLED: bool = true

signal input_action_triggered(action: String)

var duel_manager: Node
var ui_controller: Node
var end_turn_button: Button
var debug_controller: DebugController

var input_enabled: bool = true
var is_handling_input: bool = false

func _ready() -> void:
	GLog.debug("InputController initialized - Interpreting mortal intentions")
	set_process_unhandled_input(true)
	
	# Try to find debug controller if in debug build
	if OS.is_debug_build():
		debug_controller = get_node_or_null("/root/DebugController")

func initialize(duel_manager_ref: Node, ui_controller_ref: Node, button_ref: Button) -> void:
	duel_manager = duel_manager_ref
	ui_controller = ui_controller_ref
	end_turn_button = button_ref
	
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# Initialize debug controller if available
	if is_instance_valid(debug_controller):
		debug_controller.initialize(duel_manager, ui_controller, duel_manager)
	
	setup_event_connections()

func setup_event_connections() -> void:
	EventBus.connect_safe("game_paused", _on_game_paused)
	EventBus.connect_safe("game_resumed", _on_game_resumed)
	EventBus.connect_safe("duel_ended", _on_duel_ended)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_handling_input:
		return
	
	is_handling_input = true
	
	# Handle standard input
	if event.is_action_pressed("ui_page_up"):
		_handle_debug_toggle()
	elif event.is_action_pressed("ui_cancel"):
		_handle_pause_toggle()
	elif event.is_action_pressed("ui_accept"):
		_handle_end_turn()
	
	# Let DebugController handle debug shortcuts if available
	# (It will process its own input events)
	
	is_handling_input = false

func _handle_debug_toggle() -> void:
	if ui_controller and ui_controller.has_method("toggle_debug_panel"):
		ui_controller.toggle_debug_panel()
		GLog.debug("Debug panel toggled")
		input_action_triggered.emit("debug_toggle")

func _handle_pause_toggle() -> void:
	if GameManager.can_pause():
		GameManager.toggle_pause()
		GLog.debug("Game pause toggled")
		input_action_triggered.emit("pause_toggle")

func _handle_end_turn() -> void:
	if can_end_turn():
		_on_end_turn_pressed()

func _on_end_turn_pressed() -> void:
	if not duel_manager:
		return
	
	duel_manager.end_player_turn()
	GLog.debug("End turn requested")
	input_action_triggered.emit("end_turn")

func can_end_turn() -> bool:
	if not duel_manager or not duel_manager.duel_state:
		return false
	
	var duel_state = duel_manager.duel_state
	return duel_state.is_player_turn and not duel_state.get("duel_ended", false)

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	GLog.debug("Input " + ("enabled" if enabled else "disabled"))

func _on_game_paused() -> void:
	set_input_enabled(false)

func _on_game_resumed() -> void:
	set_input_enabled(true)

func _on_duel_ended(_victory: bool) -> void:
	if end_turn_button:
		end_turn_button.disabled = true

func is_input_enabled() -> bool:
	return input_enabled
