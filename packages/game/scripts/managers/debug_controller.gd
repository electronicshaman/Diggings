class_name DebugController
extends Node

## DebugController - Centralized debug commands and shortcuts
##
## Handles all debug functionality in one place, only loaded in debug builds.
## Removes debug code from production controllers.

const DEBUG_ENABLED: bool = true

signal debug_action_triggered(action: String)

var game_controller: Node
var ui_controller: Node
var duel_manager: Node
var test_data_manager: TestDataManager

# Debug key mappings
var debug_shortcuts: Dictionary = {
	KEY_F1: "add_card",
	KEY_F2: "add_health", 
	KEY_F3: "add_energy",
	KEY_F5: "restart_duel",
	KEY_F9: "instant_win",
	KEY_F10: "instant_lose",
	KEY_F11: "reload_test_data",
	KEY_F12: "toggle_god_mode"
}

# God mode state
var god_mode_enabled: bool = false

func _ready() -> void:
	if not OS.is_debug_build():
		GLog.warn("DebugController loaded in non-debug build - disabling")
		queue_free()
		return
	
	set_process_unhandled_input(true)
	GLog.debug("DebugController initialized - Debug commands enabled")
	
	# Try to find test data manager
	test_data_manager = get_node_or_null("/root/TestDataManager")

func initialize(game_controller_ref: Node, ui_controller_ref: Node, duel_manager_ref: Node) -> void:
	game_controller = game_controller_ref
	ui_controller = ui_controller_ref
	duel_manager = duel_manager_ref
	
	GLog.debug("DebugController connected to game systems")

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	# Handle debug shortcuts
	if event is InputEventKey and event.pressed:
		if debug_shortcuts.has(event.keycode):
			var action = debug_shortcuts[event.keycode]
			execute_debug_action(action)
			get_viewport().set_input_as_handled()

## Execute a debug action by name
func execute_debug_action(action: String) -> void:
	GLog.debug("Debug action: " + action)
	
	match action:
		"add_card":
			_add_random_card()
		"add_health":
			_modify_player_health(10)
		"add_energy":
			_modify_player_energy(3)
		"restart_duel":
			_restart_duel()
		"instant_win":
			_force_duel_end("player")
		"instant_lose":
			_force_duel_end("enemy")
		"reload_test_data":
			_reload_test_data()
		"toggle_god_mode":
			_toggle_god_mode()
		_:
			GLog.warn("Unknown debug action: " + action)
	
	debug_action_triggered.emit(action)

## Add a random card to the player's hand
func _add_random_card() -> void:
	if not is_instance_valid(game_controller):
		GLog.warn("Cannot add card - GameController not available")
		return
	
	if game_controller.has_method("add_random_card_to_hand"):
		game_controller.add_random_card_to_hand()
		EventBus.emit_ui_notification("Added random card", "debug")
	elif is_instance_valid(test_data_manager):
		# Alternative: use test data manager
		var card = test_data_manager.get_random_test_card()
		if card and duel_manager and duel_manager.has_method("add_card_to_hand"):
			duel_manager.add_card_to_hand(card)
			EventBus.emit_ui_notification("Added: " + card.card_name, "debug")

## Modify player health
func _modify_player_health(amount: int) -> void:
	if not is_instance_valid(game_controller):
		GLog.warn("Cannot modify health - GameController not available")
		return
	
	if game_controller.has_method("modify_player_health"):
		game_controller.modify_player_health(amount)
		EventBus.emit_ui_notification("Health %+d" % amount, "debug")

## Modify player energy
func _modify_player_energy(amount: int) -> void:
	if not is_instance_valid(game_controller):
		GLog.warn("Cannot modify energy - GameController not available")
		return
	
	if game_controller.has_method("modify_player_energy"):
		game_controller.modify_player_energy(amount)
		EventBus.emit_ui_notification("Energy %+d" % amount, "debug")

## Restart the current duel
func _restart_duel() -> void:
	if not is_instance_valid(game_controller):
		GLog.warn("Cannot restart duel - GameController not available")
		return
	
	if game_controller.has_method("start_test_duel"):
		game_controller.start_test_duel()
		EventBus.emit_ui_notification("Duel restarted", "debug")

## Force end the duel with a specific winner
func _force_duel_end(winner: String) -> void:
	if not is_instance_valid(duel_manager):
		GLog.warn("Cannot force duel end - DuelManager not available")
		return
	
	# Manipulate health to force the end
	if game_controller and game_controller.has_method("get") and game_controller.get("current_duel_state"):
		var duel_state = game_controller.current_duel_state
		
		if winner == "player" and duel_state.get("enemy_data"):
			duel_state.enemy_data.current_health = 0
		elif winner == "enemy" and duel_state.get("player_data"):
			duel_state.player_data.current_health = 0
		
		if duel_manager.has_method("check_duel_end_conditions"):
			duel_manager.check_duel_end_conditions()
		
		EventBus.emit_ui_notification("Forced " + winner + " victory", "debug")

## Reload test data
func _reload_test_data() -> void:
	if not is_instance_valid(test_data_manager):
		GLog.warn("Cannot reload test data - TestDataManager not available")
		return
	
	test_data_manager.reload_test_content()
	EventBus.emit_ui_notification("Test data reloaded", "debug")

## Toggle god mode
func _toggle_god_mode() -> void:
	god_mode_enabled = !god_mode_enabled
	
	if god_mode_enabled:
		# Make player invincible
		if game_controller and game_controller.get("current_duel_state"):
			var duel_state = game_controller.current_duel_state
			if duel_state.get("player_data"):
				duel_state.player_data.max_health = 9999
				duel_state.player_data.current_health = 9999
				duel_state.player_data.max_energy = 99
				duel_state.player_data.current_energy = 99
	
	var status = "enabled" if god_mode_enabled else "disabled"
	EventBus.emit_ui_notification("God mode " + status, "debug")
	GLog.info("God mode " + status)

## Get list of available debug commands
func get_debug_commands() -> Array[String]:
	var commands: Array[String] = []
	for action in debug_shortcuts.values():
		commands.append(action)
	return commands

## Get debug shortcut for an action
func get_shortcut_for_action(action: String) -> int:
	for key in debug_shortcuts:
		if debug_shortcuts[key] == action:
			return key
	return -1

## Check if a debug action exists
func has_debug_action(action: String) -> bool:
	return action in debug_shortcuts.values()