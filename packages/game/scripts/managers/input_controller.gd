extends Node

const DEBUG_ENABLED: bool = true

signal input_action_triggered(action: String)

var game_controller: Node
var ui_controller: Node
var end_turn_button: Button

var input_enabled: bool = true
var is_processing_input: bool = false

func _ready() -> void:
	GLog.debug("InputController initialized - Interpreting mortal intentions")
	set_process_unhandled_input(true)

func initialize(game_controller_ref: Node, ui_controller_ref: Node, button_ref: Button) -> void:
	game_controller = game_controller_ref
	ui_controller = ui_controller_ref
	end_turn_button = button_ref
	
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	setup_event_connections()

func setup_event_connections() -> void:
	EventBus.connect_safe("game_paused", _on_game_paused)
	EventBus.connect_safe("game_resumed", _on_game_resumed)
	EventBus.connect_safe("duel_ended", _on_duel_ended)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_processing_input:
		return
	
	is_processing_input = true
	
	if event.is_action_pressed("ui_page_up"):
		_handle_debug_toggle()
	elif event.is_action_pressed("ui_cancel"):
		_handle_pause_toggle()
	elif event.is_action_pressed("ui_accept"):
		_handle_end_turn()
	
	if OS.is_debug_build():
		_handle_debug_shortcuts(event)
	
	is_processing_input = false

func _handle_debug_shortcuts(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_trigger_debug_action("add_card")
			KEY_F2:
				_trigger_debug_action("add_health")
			KEY_F3:
				_trigger_debug_action("add_energy")
			KEY_F5:
				_trigger_debug_action("restart_duel")
			KEY_F9:
				_trigger_debug_action("instant_win")
			KEY_F10:
				_trigger_debug_action("instant_lose")

func _handle_debug_toggle() -> void:
	if ui_controller:
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
	if not game_controller:
		return
	
	game_controller.end_player_turn()
	GLog.debug("End turn requested")
	input_action_triggered.emit("end_turn")

func can_end_turn() -> bool:
	if not game_controller or not ("current_duel_state" in game_controller):
		return false
	
	var duel_state = game_controller.current_duel_state
	return duel_state and duel_state.is_player_turn and not duel_state.get("duel_ended", false)

func _trigger_debug_action(action: String) -> void:
	if not OS.is_debug_build():
		return
	
	GLog.debug("Debug action triggered: " + action)
	
	match action:
		"add_card":
			if game_controller:
				game_controller.add_random_card_to_hand()
		"add_health":
			if game_controller:
				game_controller.modify_player_health(10)
		"add_energy":
			if game_controller:
				game_controller.modify_player_energy(3)
		"restart_duel":
			if game_controller:
				game_controller.start_test_duel()
		"instant_win":
			_force_duel_end("player")
		"instant_lose":
			_force_duel_end("enemy")
	
	input_action_triggered.emit("debug_" + action)

func _force_duel_end(winner: String) -> void:
	if not game_controller or not ("current_duel_state" in game_controller):
		return
	
	var duel_state = game_controller.current_duel_state
	if duel_state:
		if winner == "player" and duel_state.enemy_data:
			duel_state.enemy_data.current_health = 0
		elif winner == "enemy" and duel_state.player_data:
			duel_state.player_data.current_health = 0
		
		EventBus.duel_ended.emit(winner == "player")
		if ui_controller:
			ui_controller.show_duel_result(winner)

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
