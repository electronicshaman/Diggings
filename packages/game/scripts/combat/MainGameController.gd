extends Node2D

const DEBUG_ENABLED: bool = true

@onready var duel_manager := $DuelManager
@onready var game_controller := $GameController
@onready var ui_controller := $UIController
@onready var input_controller := $InputController

# UI Elements - Direct references using @onready
@onready var hand_area := $UI/Control/HandArea
@onready var debug_panel := $UI/Control/DebugPanel
@onready var end_turn_button := $UI/Control/TurnInfo/EndTurnButton
@onready var win_duel_button := $UI/Control/TurnInfo/WinDuel
@onready var lose_duel_button := $UI/Control/TurnInfo/LoseDuel

# Player Stats UI
@onready var player_health_label := $UI/Control/PlayerArea/PlayerStats/LeftColumn/HealthLabel
@onready var player_energy_label := $UI/Control/PlayerArea/PlayerStats/LeftColumn/EnergyLabel
@onready var player_defense_label := $UI/Control/PlayerArea/PlayerStats/LeftColumn/DefenseLabel
@onready var player_sanity_label := $UI/Control/PlayerArea/PlayerStats/RightColumn/SanityLabel
@onready var character_name_label := $UI/Control/PlayerArea/PlayerStats/LeftColumn/CharacterNameLabel
@onready var player_gold_label := $UI/Control/PlayerArea/PlayerStats/RightColumn/GoldLabel

# Enemy Stats UI
@onready var enemy_name_label := $UI/Control/EnemyArea/EnemyStats/EnemyName
@onready var enemy_health_label := $UI/Control/EnemyArea/EnemyStats/EnemyHealth
@onready var enemy_defense_label := $UI/Control/EnemyArea/EnemyStats/EnemyDefense

# Game Info UI
@onready var deck_label := $UI/Control/PileIndicatorsLeft/DeckLabel
@onready var discard_label := $UI/Control/PileIndicatorsRight/DiscardLabel
@onready var turn_label := $UI/Control/TurnInfo/TurnLabel
@onready var phase_label := $UI/Control/TurnInfo/PhaseLabel

# Debug UI
@onready var add_card_button := $UI/Control/DebugPanel/DebugButtons/AddCardButton
@onready var set_health_button := $UI/Control/DebugPanel/DebugButtons/SetHealthButton
@onready var set_energy_button := $UI/Control/DebugPanel/DebugButtons/SetEnergyButton
@onready var reset_duel_button := $UI/Control/DebugPanel/DebugButtons/ResetDuelButton

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
		"player_health": player_health_label,
		"player_energy": player_energy_label,
		"player_defense": player_defense_label,
		"player_sanity": player_sanity_label,
		"player_gold": player_gold_label,
		"character_name": character_name_label,
		"enemy_name": enemy_name_label,
		"enemy_health": enemy_health_label,
		"enemy_defense": enemy_defense_label,
		"deck": deck_label,
		"discard": discard_label,
		"turn": turn_label,
		"phase": phase_label,
		"end_turn_button": end_turn_button,
		"debug_panel": debug_panel,
		"hand_area": hand_area,
		"add_card_button": add_card_button,
		"set_health_button": set_health_button,
		"set_energy_button": set_energy_button,
		"reset_duel_button": reset_duel_button
	}

func setup_connections() -> void:
	game_controller.test_content_loaded.connect(_on_test_content_loaded)
	ui_controller.ui_refresh_requested.connect(_on_ui_refresh_requested)
	input_controller.input_action_triggered.connect(_on_input_action_triggered)
	
	# Connect testing buttons
	win_duel_button.pressed.connect(_on_win_duel_pressed)
	lose_duel_button.pressed.connect(_on_lose_duel_pressed)

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

func _on_win_duel_pressed() -> void:
	GLog.debug("Test win button pressed - ending duel as player victory")
	if duel_manager:
		duel_manager.end_duel("player")
	
	# Return to map after a brief delay
	await get_tree().create_timer(1.0).timeout
	SceneManager.load_scene("res://scenes/game/map.tscn")

func _on_lose_duel_pressed() -> void:
	GLog.debug("Test lose button pressed - ending duel as player defeat")
	if duel_manager:
		duel_manager.end_duel("enemy")
	
	# Go to game over after a brief delay
	await get_tree().create_timer(1.0).timeout
	SceneManager.load_scene("res://scenes/ui/game_over.tscn")

func get_game_controller() -> Node:
	return game_controller

func get_ui_controller() -> Node:
	return ui_controller

func get_input_controller() -> Node:
	return input_controller

func get_duel_manager() -> Node:
	return duel_manager
