extends Node2D

const DEBUG_ENABLED: bool = true

@onready var duel_manager := $DuelManager
@onready var game_controller := $GameController
@onready var ui_controller := $UIController
@onready var input_controller := $InputController

@onready var hand_area := $UI/Control/HandArea
@onready var debug_panel := $UI/Control/DebugPanel
@onready var end_turn_button := $UI/Control/TurnInfo/EndTurnButton

var is_initialized: bool = false

func _ready() -> void:
	GLog.debug("MainGameController awakened - The orchestrator of chaos")
	await get_tree().process_frame
	initialize_controllers()
	
	await get_tree().create_timer(0.5).timeout
	start_initial_duel()

func initialize_controllers() -> void:
	if is_initialized:
		return
	
	game_controller.initialize(duel_manager)
	
	var ui_references := get_ui_references()
	ui_controller.initialize(ui_references, game_controller)
	
	input_controller.initialize(game_controller, ui_controller, end_turn_button)
	
	setup_connections()
	is_initialized = true
	GLog.debug("All controllers initialized and connected")

func get_ui_references() -> Dictionary:
	return {
		"player_health": $UI/Control/PlayerArea/PlayerStats/HealthLabel,
		"player_energy": $UI/Control/PlayerArea/PlayerStats/EnergyLabel,
		"player_defense": $UI/Control/PlayerArea/PlayerStats/DefenseLabel,
		"player_sanity": $UI/Control/PlayerArea/PlayerStats/SanityLabel,
		"enemy_name": $UI/Control/EnemyArea/EnemyStats/EnemyName,
		"enemy_health": $UI/Control/EnemyArea/EnemyStats/EnemyHealth,
		"enemy_defense": $UI/Control/EnemyArea/EnemyStats/EnemyDefense,
		"deck": $UI/Control/PileIndicatorsLeft/DeckLabel,
		"discard": $UI/Control/PileIndicatorsRight/DiscardLabel,
		"turn": $UI/Control/TurnInfo/TurnLabel,
		"phase": $UI/Control/TurnInfo/PhaseLabel,
		"end_turn_button": end_turn_button,
		"debug_panel": debug_panel,
		"hand_area": hand_area,
		"add_card_button": $UI/Control/DebugPanel/DebugButtons/AddCardButton,
		"set_health_button": $UI/Control/DebugPanel/DebugButtons/SetHealthButton,
		"set_energy_button": $UI/Control/DebugPanel/DebugButtons/SetEnergyButton,
		"reset_duel_button": $UI/Control/DebugPanel/DebugButtons/ResetDuelButton
	}

func setup_connections() -> void:
	game_controller.test_content_loaded.connect(_on_test_content_loaded)
	ui_controller.ui_refresh_requested.connect(_on_ui_refresh_requested)
	input_controller.input_action_triggered.connect(_on_input_action_triggered)

func start_initial_duel() -> void:
	if game_controller and game_controller.test_cards.size() > 0:
		game_controller.start_test_duel()
	else:
		GLog.warn("Cannot start duel - waiting for test content to load")
		await game_controller.test_content_loaded
		game_controller.start_test_duel()

func _on_test_content_loaded() -> void:
	GLog.debug("Test content loaded, ready for dueling")
	EventBus.emit_ui_notification("Game Ready", "success")

func _on_ui_refresh_requested() -> void:
	pass

func _on_input_action_triggered(action: String) -> void:
	GLog.debug("Input action: " + action)
	EventBus.emit_game_event("input_" + action)

func get_game_controller() -> Node:
	return game_controller

func get_ui_controller() -> Node:
	return ui_controller

func get_input_controller() -> Node:
	return input_controller

func get_duel_manager() -> Node:
	return duel_manager
