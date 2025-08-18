extends Node2D

const DEBUG_ENABLED: bool = true

# Signals for UI updates
signal game_state_updated()

# Core controllers - safely referenced
@onready var duel_manager: Node = $DuelManager
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
	
	if not is_instance_valid(duel_manager):
		push_error("MainGameController: DuelManager is invalid")
		return
	
	var ui_references := get_ui_references()
	if ui_references.is_empty():
		push_warning("MainGameController: No UI references available")
	
	if is_instance_valid(ui_controller):
		ui_controller.initialize(ui_references, self)
	else:
		push_error("MainGameController: UIController is invalid")
		return
	
	var end_turn_btn = ui_manager.get_ui_node("end_turn_button")
	if is_instance_valid(input_controller):
		input_controller.initialize(self, ui_controller, end_turn_btn)
	else:
		push_error("MainGameController: InputController is invalid")
		return
	
	setup_connections()
	is_initialized = true
	GLog.debug("All controllers initialized and connected")
	
	# Check for pending duel and start it
	await get_tree().process_frame
	_initialize_duel()


func get_ui_references() -> Dictionary:
	if not ui_manager:
		push_error("MainGameController: UI manager not initialized")
		return {}
	
	return ui_manager.get_ui_reference_dictionary()

func setup_connections() -> void:
	# Connect to DuelManager signals directly
	if is_instance_valid(duel_manager):
		if duel_manager.has_signal("duel_started"):
			duel_manager.duel_started.connect(_on_duel_started_signal)
		if duel_manager.has_signal("duel_ended"):
			duel_manager.duel_ended.connect(_on_duel_ended_from_manager)
		if duel_manager.has_signal("turn_started"):
			duel_manager.turn_started.connect(_on_turn_started)
		if duel_manager.has_signal("card_played"):
			duel_manager.card_played.connect(_on_card_played)
	
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

## Initialize duel from GameManager config or fallback to test duel
func _initialize_duel() -> void:
	GLog.debug("Initializing duel...")
	
	# Check for pending duel config from GameManager
	if is_instance_valid(GameManager) and GameManager.is_duel_prepared():
		var duel_config = GameManager.get_pending_duel_config()
		if duel_config and duel_config.is_valid():
			GLog.info("Starting duel from config: %s" % str(duel_config.get_summary()))
			
			# Get the modified deck (applies any temporary modifiers)
			var player_deck = duel_config.get_modified_deck()
			var enemy_data = duel_config.enemy_data
			
			# Start the duel
			start_duel(player_deck, enemy_data)
			
			# Clear the config after using it
			GameManager.clear_pending_duel_config()
			return
	
	# Fallback: start test duel for debugging
	GLog.warn("No duel config found - starting test duel")
	start_test_duel()

## Start a duel with the given deck and enemy (core GameController functionality)
func start_duel(player_deck: Array[CardData], enemy: Resource) -> Error:
	if not is_instance_valid(duel_manager):
		push_error("MainGameController: Cannot start duel - DuelManager is invalid")
		return ERR_UNCONFIGURED
	
	if player_deck.is_empty():
		push_error("MainGameController: Cannot start duel - Player deck is empty")
		return ERR_INVALID_PARAMETER
	
	if not is_instance_valid(enemy):
		push_error("MainGameController: Cannot start duel - Enemy is invalid")
		return ERR_INVALID_PARAMETER
	
	# Validate deck contents
	if not _validate_deck_contents(player_deck):
		push_error("MainGameController: Player deck validation failed")
		return ERR_INVALID_DATA
	
	var enemy_name = enemy.enemy_name if "enemy_name" in enemy else "Unknown"
	GLog.debug("Starting duel with enemy: %s" % enemy_name)
	duel_manager.start_new_duel(player_deck, enemy)
	
	return OK

## Start a test duel (fallback for debugging)
func start_test_duel() -> void:
	# Try to get deck from DeckManager first
	var deck: Array[CardData] = []
	if is_instance_valid(DeckManager) and DeckManager.is_deck_available():
		deck = DeckManager.get_current_deck()
	
	# Fallback to building default deck
	if deck.is_empty():
		deck = _build_default_player_deck()
	
	# Get default enemy
	var enemy: Resource = _get_default_enemy()
	
	if deck.is_empty() or not is_instance_valid(enemy):
		push_warning("MainGameController: Could not build test duel inputs (deck or enemy missing)")
		return
	
	var err = start_duel(deck, enemy)
	if err != OK:
		push_warning("MainGameController: start_test_duel failed with error code: " + str(err))

## Validate deck contents
func _validate_deck_contents(deck: Array[CardData]) -> bool:
	if deck.is_empty():
		push_warning("MainGameController: Deck is empty")
		return false
	
	var valid_cards = 0
	var invalid_cards = 0
	
	for card in deck:
		if is_instance_valid(card):
			if "card_name" in card and "effects" in card:
				valid_cards += 1
			else:
				invalid_cards += 1
				GLog.warn("Invalid card structure in deck")
		else:
			invalid_cards += 1
			GLog.warn("Null card found in deck")
	
	if invalid_cards > 0:
		push_warning("MainGameController: Deck has %d invalid cards out of %d total" % [invalid_cards, deck.size()])
	
	return valid_cards > 0

## Build default player deck (GameController functionality)
func _build_default_player_deck() -> Array[CardData]:
	var result: Array[CardData] = []
	var char_class = "bushranger"
	if is_instance_valid(GameManager) and GameManager.current_character_class and GameManager.current_character_class != "":
		char_class = GameManager.current_character_class
	
	var character_path = "res://data/characters/%s.tres" % [char_class.to_lower()]
	if ResourceLoader.exists(character_path):
		var character_res = load(character_path)
		if character_res and character_res.has_method("load_starting_deck"):
			result = character_res.load_starting_deck()
	else:
		push_warning("MainGameController: Character resource not found at " + character_path)

	return result

## Get default enemy (GameController functionality)
func _get_default_enemy() -> Resource:
	# Prefer a known basic enemy; fallback to first .tres in data/enemies
	var default_enemy_path = "res://data/enemies/claim_jumper.tres"
	if ResourceLoader.exists(default_enemy_path):
		return load(default_enemy_path)
	# Fallback scan (lightweight)
	var dir = DirAccess.open("res://data/enemies/")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".tres"):
				var p = "res://data/enemies/%s" % fname
				if ResourceLoader.exists(p):
					return load(p)
			fname = dir.get_next()
	# As a last resort, return null
	return null

## Essential GameController methods for other controllers to use
func play_card(card_instance: CardInstance) -> Error:
	if not is_instance_valid(card_instance):
		push_error("MainGameController: Cannot play invalid card instance")
		return ERR_INVALID_PARAMETER
	
	if not is_instance_valid(duel_manager):
		push_error("MainGameController: Cannot play card - DuelManager is invalid")
		return ERR_UNCONFIGURED
	
	if not duel_manager.has_method("play_card"):
		push_error("MainGameController: DuelManager missing play_card method")
		return ERR_METHOD_NOT_FOUND
	
	duel_manager.play_card(card_instance)
	return OK

func end_player_turn() -> Error:
	if not is_instance_valid(duel_manager):
		push_error("MainGameController: Cannot end turn - DuelManager is invalid")
		return ERR_UNCONFIGURED
	
	if duel_manager.has_method("end_player_turn"):
		duel_manager.end_player_turn()
		return OK
	else:
		push_error("MainGameController: DuelManager missing end_player_turn method")
		return ERR_METHOD_NOT_FOUND

func get_hand_cards() -> Array:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_hand_cards"):
		return duel_manager.get_hand_cards()
	return []

func get_deck_count() -> int:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_deck_count"):
		return duel_manager.get_deck_count()
	return 0

func get_discard_count() -> int:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_discard_count"):
		return duel_manager.get_discard_count()
	return 0

func _on_duel_started_signal() -> void:
	GLog.debug("Duel started - game ready")
	EventBus.emit_ui_notification("Duel Started", "success")
	game_state_updated.emit()

func _on_ui_refresh_requested() -> void:
	pass

func _on_input_action_triggered(action: String) -> void:
	GLog.debug("Input action: " + action)
	EventBus.emit_game_event("input_" + action)

func _on_turn_started(is_player_turn: bool) -> void:
	GLog.debug("Turn started: " + ("Player" if is_player_turn else "Enemy"))
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("turn_started"):
		EventBus.turn_started.emit(is_player_turn)
	
	game_state_updated.emit()

func _on_card_played(card) -> void:
	var card_name = "Unknown Card"
	if card and typeof(card) == TYPE_OBJECT:
		# Support both CardInstance and CardData
		if "get_card_name" in card:
			card_name = card.get_card_name()
		elif "card_name" in card:
			card_name = card.card_name
	
	GLog.debug("Card played: " + card_name)
	
	# Update statistics safely
	if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
		GameManager.increment_statistic("cards_played")
	
	game_state_updated.emit()

func _on_win_duel_pressed() -> void:
	GLog.debug("Test win button pressed - ending duel as player victory")
	if is_instance_valid(duel_manager) and duel_manager.has_method("end_duel"):
		duel_manager.end_duel("player")
	else:
		push_warning("MainGameController: Cannot end duel - DuelManager is invalid or missing method")
	
	# Return to map after a brief delay
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene"):
		SceneManager.load_scene("res://scenes/hexmap/hexmap.tscn")
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

func _on_duel_ended_from_manager(winner: String) -> void:
	GLog.debug("Duel ended (signal) - Winner: " + winner)
	game_state_updated.emit()
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
