extends Node2D

const DEBUG_ENABLED: bool = true

# Signals for UI updates
signal game_state_updated()

# Core controllers - safely referenced
@onready var duel_manager: Node = $DuelManager
@onready var duel_state_manager: Node = $GameController
@onready var ui_controller: Node = $UIController
@onready var input_controller: Node = $InputController

# UI Reference Manager for safe UI access
var ui_manager: UIReferenceManager
var is_initialized: bool = false

# Expose current duel state so UI can bind to it
var current_duel_state: Resource = null

# Quick access nodes that need direct references for critical functionality
var win_duel_button: Button
var lose_duel_button: Button

func _ready() -> void:
	GLog.debug("DuelSceneController awakened - The orchestrator of chaos")
	await get_tree().process_frame
	
	if _initialize_ui_manager() != OK:
		push_error("DuelSceneController: Failed to initialize UI manager")
		return
	
	initialize_controllers()

func _initialize_ui_manager() -> Error:
	ui_manager = UIReferenceManager.new()
	var result = ui_manager.initialize(self)
	
	if result != OK:
		push_error("DuelSceneController: UI manager initialization failed")
		return result
	
	# Cache critical buttons for direct access
	win_duel_button = get_node_or_null("UI/Control/DebugPanel/DebugButtons/WinDuel")
	lose_duel_button = get_node_or_null("UI/Control/DebugPanel/DebugButtons/LoseDuel")
	
	if not is_instance_valid(win_duel_button):
		push_warning("DuelSceneController: Win duel button not found")
	if not is_instance_valid(lose_duel_button):
		push_warning("DuelSceneController: Lose duel button not found")
	
	GLog.debug("DuelSceneController: UI manager initialized successfully")
	return OK

func initialize_controllers() -> void:
	if is_initialized:
		return
	
	if not is_instance_valid(duel_manager):
		push_error("DuelSceneController: DuelManager is invalid")
		return
	
	if not is_instance_valid(duel_state_manager):
		push_error("DuelSceneController: DuelStateManager is invalid")
		return
	
	# Initialize DuelStateManager first
	var init_result = duel_state_manager.initialize(duel_manager)
	if init_result != OK:
		push_error("DuelSceneController: Failed to initialize DuelStateManager")
		return
	
	var ui_references := get_ui_references()
	if ui_references.is_empty():
		push_warning("DuelSceneController: No UI references available")
	
	if is_instance_valid(ui_controller):
		ui_controller.initialize(ui_references, self)
	else:
		push_error("DuelSceneController: UIController is invalid")
		return
	
	var end_turn_btn = ui_manager.get_ui_node("end_turn_button")
	if is_instance_valid(input_controller):
		input_controller.initialize(duel_manager, ui_controller, end_turn_btn)
	else:
		push_error("DuelSceneController: InputController is invalid")
		return
	
	setup_connections()
	is_initialized = true
	GLog.debug("All controllers initialized and connected")
	
	# If a DuelState already exists on DuelManager (e.g., hot reload), attach and pass to UI
	if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
		current_duel_state = duel_manager.duel_state
		_attach_duel_state_change_listener()
		if is_instance_valid(ui_controller) and ui_controller.has_method("update_duel_state"):
			ui_controller.update_duel_state(current_duel_state)

	# Check for pending duel and start it
	await get_tree().process_frame
	_initialize_duel()


func get_ui_references() -> Dictionary:
	if not ui_manager:
		push_error("DuelSceneController: UI manager not initialized")
		return {}
	
	return ui_manager.get_ui_reference_dictionary()

func setup_connections() -> void:
	# Connect to DuelStateManager signals
	if is_instance_valid(duel_state_manager):
		if duel_state_manager.has_signal("game_state_updated"):
			duel_state_manager.game_state_updated.connect(_on_game_state_updated)
		if duel_state_manager.has_signal("duel_started"):
			duel_state_manager.duel_started.connect(_on_duel_started_signal)
		if duel_state_manager.has_signal("duel_ended"):
			duel_state_manager.duel_ended.connect(_on_duel_ended_from_state_manager)
	
	if is_instance_valid(ui_controller):
		if ui_controller.has_signal("ui_refresh_requested"):
			ui_controller.ui_refresh_requested.connect(_on_ui_refresh_requested)
		else:
			push_warning("DuelSceneController: ui_refresh_requested signal not found on UIController")
	
	if is_instance_valid(input_controller):
		if input_controller.has_signal("input_action_triggered"):
			input_controller.input_action_triggered.connect(_on_input_action_triggered)
		else:
			push_warning("DuelSceneController: input_action_triggered signal not found on InputController")
	
	# Connect testing buttons safely
	if is_instance_valid(win_duel_button):
		win_duel_button.pressed.connect(_on_win_duel_pressed)
	else:
		push_warning("DuelSceneController: Cannot connect win_duel_button - button is invalid")
		
	if is_instance_valid(lose_duel_button):
		lose_duel_button.pressed.connect(_on_lose_duel_pressed)
	else:
		push_warning("DuelSceneController: Cannot connect lose_duel_button - button is invalid")

## Initialize duel from GameManager config or fallback to test duel
func _initialize_duel() -> void:
	GLog.debug("Initializing duel...")
	
	# Check if a duel is already running (from bootstrap or other source)
	if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
		if duel_manager.duel_state.has_method("is_duel_active") and duel_manager.duel_state.is_duel_active():
			GLog.debug("Duel already active - skipping initialization")
			return
	
	# Check for pending duel config from GameManager
	if is_instance_valid(GameManager) and GameManager.is_duel_prepared():
		var duel_config = GameManager.get_pending_duel_config()
		if duel_config and duel_config.is_valid():
			GLog.info("Starting duel from config: %s" % str(duel_config.get_summary()))

			# Get the modified deck (applies any temporary modifiers)
			var card_array = duel_config.get_modified_deck()
			var enemy_data = duel_config.enemy_data

			# Convert Array[CardData] to DeckData for start_duel()
			var player_deck = _create_deck_data_from_cards(card_array, duel_config.scene_context)

			# Start the duel via DuelStateManager
			duel_state_manager.start_duel(player_deck, enemy_data)

			# Check if this is a quick duel and set flag
			if duel_config.get_modifier("quick_duel", false):
				GameManager.game_data["is_quick_duel"] = true
				GLog.info("Quick duel mode activated", "duel_scene_controller")
				
				# Apply health override if present
				var health_override = duel_config.get_modifier("health_override", -1)
				if health_override > 0:
					if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
						var ds = duel_manager.duel_state
						if ds.player_data and ds.player_data.stats:
							ds.player_data.stats.current_health = health_override
							GLog.info("Applied health override: %d" % health_override, "duel_scene_controller")

				# Apply energy override if present
				var energy_override = duel_config.get_modifier("energy_override", -1)
				if energy_override > 0:
					if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
						var ds = duel_manager.duel_state
						if ds.player_data and ds.player_data.stats:
							ds.player_data.stats.max_energy = energy_override
							ds.player_data.stats.current_energy = energy_override
							GLog.info("Applied energy override: %d" % energy_override, "duel_scene_controller")

				# Apply character class if present (initializes class-specific resources)
				var char_class = duel_config.get_modifier("character_class", null)
				if char_class:
					if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
						var ds = duel_manager.duel_state
						if ds.player_data:
							ds.player_data.set_character_class(char_class)
							GLog.info("Applied character class: %s" % char_class.character_class_name, "duel_scene_controller")
			else:
				GameManager.game_data["is_quick_duel"] = false

			# Clear the config after using it
			GameManager.clear_pending_duel_config()
			return
	
	# Check for active duel sequence (returning from victory reward mid-sequence)
	if GameManager.duel_sequence_state and GameManager.duel_sequence_state.is_active:
		GLog.info("Active duel sequence detected - starting next battle", "duel_scene_controller")

		# Use DuelSequenceHandler to create next battle config
		var sequence_handler = DuelSequenceHandler.new()
		var next_config = sequence_handler.start_next_battle()

		if next_config and next_config.is_valid():
			var card_array = next_config.get_modified_deck()
			var enemy_data = next_config.enemy_data
			var player_deck = _create_deck_data_from_cards(card_array, next_config.scene_context)

			duel_state_manager.start_duel(player_deck, enemy_data)
			GameManager.game_data["is_quick_duel"] = true
			GLog.info("Started sequence battle against: %s" % (enemy_data.enemy_name if enemy_data and "enemy_name" in enemy_data else "Unknown"), "duel_scene_controller")
			return
		else:
			GLog.error("Failed to create config for sequence battle", "duel_scene_controller")

	# No fallback - let test scenes handle their own initialization
	GLog.debug("No duel config found - waiting for external initialization")


func _on_game_state_updated() -> void:
	game_state_updated.emit()

func _on_duel_started_signal() -> void:
	GLog.debug("Duel started - game ready")
	EventBus.emit_ui_notification("Duel Started", "success")

	# Capture DuelState reference and pass to UI
	if is_instance_valid(duel_manager) and "duel_state" in duel_manager and is_instance_valid(duel_manager.duel_state):
		current_duel_state = duel_manager.duel_state
		_attach_duel_state_change_listener()
		if is_instance_valid(ui_controller) and ui_controller.has_method("update_duel_state"):
			ui_controller.update_duel_state(current_duel_state)
	game_state_updated.emit()

func _on_duel_ended_from_state_manager(victory: bool) -> void:
	GLog.debug("Duel ended (from state manager) - Victory: %s" % victory)
	game_state_updated.emit()
	
	# Quick duel flow is routed by DuelManager (victory_reward/game_over/sequence).
	if GameManager and GameManager.game_data.get("is_quick_duel", false):
		return

	# Check for duel sequence - let DuelManager handle the transition and persistence
	if GameManager.duel_sequence_state and GameManager.duel_sequence_state.is_active:
		GLog.debug("Duel sequence active - deferring end game logic to DuelManager", "duel_scene_controller")
		return

	await get_tree().create_timer(0.6).timeout
	if victory:
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("quick_duel_setup")
		else:
			push_error("DuelSceneController: Cannot load quick duel setup scene on duel end - SceneManager unavailable")
	else:
		if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
			SceneManager.load_scene_by_name("game_over")
		else:
			push_error("DuelSceneController: Cannot load game over scene on duel end - SceneManager unavailable")

func _on_ui_refresh_requested() -> void:
	pass

func _on_input_action_triggered(action: String) -> void:
	GLog.debug("Input action: " + action)
	EventBus.emit_game_event("input_" + action)


func _attach_duel_state_change_listener() -> void:
	if not is_instance_valid(current_duel_state):
		return
	if current_duel_state.has_method("add_change_listener"):
		# Attach a lightweight listener to refresh UI on any DuelState change
		current_duel_state.add_change_listener(_on_duel_state_changed)

func _on_duel_state_changed(_change_type: String, _data: Dictionary) -> void:
	# Propagate a UI refresh whenever DuelState mutates (hand draws, battlefield staging, etc.)
	game_state_updated.emit()

func _on_win_duel_pressed() -> void:
	GLog.debug("Test win button pressed - ending duel as player victory")
	if is_instance_valid(duel_manager) and duel_manager.has_method("end_duel"):
		duel_manager.end_duel("player")
	else:
		push_warning("DuelSceneController: Cannot end duel - DuelManager is invalid or missing method")
	
	# Return to quick duel setup after a brief delay
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene"):
		SceneManager.load_scene("res://scenes/game/quick_duel_setup.tscn")
	else:
		push_error("DuelSceneController: Cannot load quick duel setup scene - SceneManager unavailable")

func _on_lose_duel_pressed() -> void:
	GLog.debug("Test lose button pressed - ending duel as player defeat")
	if is_instance_valid(duel_manager) and duel_manager.has_method("end_duel"):
		duel_manager.end_duel("enemy")
	else:
		push_warning("DuelSceneController: Cannot end duel - DuelManager is invalid or missing method")
	
	# Go to game over after a brief delay
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene"):
		SceneManager.load_scene("res://scenes/ui/game_over.tscn")
	else:
		push_error("DuelSceneController: Cannot load game over scene - SceneManager unavailable")


func get_ui_controller() -> Node:
	if is_instance_valid(ui_controller):
		return ui_controller
	push_warning("DuelSceneController: UIController is invalid")
	return null

func get_input_controller() -> Node:
	if is_instance_valid(input_controller):
		return input_controller
	push_warning("DuelSceneController: InputController is invalid")
	return null

func get_duel_manager() -> Node:
	if is_instance_valid(duel_manager):
		return duel_manager
	push_warning("DuelSceneController: DuelManager is invalid")
	return null

func get_duel_state_manager() -> Node:
	if is_instance_valid(duel_state_manager):
		return duel_state_manager
	push_warning("DuelSceneController: DuelStateManager is invalid")
	return null

## Get UI manager for external access to UI references
func get_ui_manager() -> UIReferenceManager:
	return ui_manager

## Refresh UI cache - useful when UI structure changes during runtime
func refresh_ui_references() -> void:
	if ui_manager:
		ui_manager.clear_cache()
		GLog.debug("DuelSceneController: UI references refreshed")
	else:
		push_warning("DuelSceneController: Cannot refresh UI - UI manager not initialized")


## Convert Array[CardData] to DeckData for duel initialization
func _create_deck_data_from_cards(cards: Array[CardData], context: String = "") -> DeckData:
	var deck_data = DeckData.new("Encounter Deck", "encounter")
	deck_data.description = "Deck for %s" % context if context else "Encounter deck"

	for card in cards:
		if is_instance_valid(card) and not card.resource_path.is_empty():
			deck_data.card_paths.append(card.resource_path)
		elif is_instance_valid(card):
			# Card was created at runtime without a resource path - skip with warning
			push_warning("DuelSceneController: Card '%s' has no resource_path, skipping" % card.card_name)

	GLog.debug("Created DeckData with %d cards from Array[CardData]" % deck_data.card_paths.size())
	return deck_data
