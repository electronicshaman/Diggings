extends Node

const DEBUG_ENABLED: bool = true

signal game_state_updated()
signal test_content_loaded()

var duel_manager: Node
var test_cards: Array[CardData] = []
var test_enemies: Array[Resource] = []
var current_duel_state: Resource
var player_character: CharacterClass

# Error tracking for stability monitoring
var _error_count: int = 0
var _last_error_time: float = 0.0
var _critical_errors: Array[String] = []

# Safe property existence helper for Objects/Resources without has_property()
func _has_prop(obj, prop_name: String) -> bool:
	if obj == null:
		return false
	if obj is Dictionary:
		return (obj as Dictionary).has(prop_name)
	if obj is Object:
		var o: Object = obj
		var plist: Array = o.get_property_list()
		for p in plist:
			if typeof(p) == TYPE_DICTIONARY and (p as Dictionary).get("name", "") == prop_name:
				return true
	return false

func _ready() -> void:
	GLog.debug("GameController initialized - Managing the cosmic game state")
	_safe_load_test_content()

## Initialize with comprehensive error handling
func initialize(duel_manager_ref: Node) -> Error:
	if not is_instance_valid(duel_manager_ref):
		push_error("GameController: Cannot initialize - DuelManager reference is invalid")
		return ERR_INVALID_PARAMETER
	
	duel_manager = duel_manager_ref
	
	# Validate required methods on duel manager
	var required_methods = ["start_new_duel", "end_player_turn", "play_card"]
	for method in required_methods:
		if not duel_manager.has_method(method):
			push_error("GameController: DuelManager missing required method: " + method)
			return ERR_METHOD_NOT_FOUND
	
	# Connect signals safely
	var signal_connections = [
		{"signal": "duel_started", "method": "_on_duel_started"},
		{"signal": "duel_ended", "method": "_on_duel_ended"},
		{"signal": "turn_started", "method": "_on_turn_started"},
		{"signal": "card_played", "method": "_on_card_played"}
	]
	
	for connection in signal_connections:
		if duel_manager.has_signal(connection.signal):
			var connect_result = duel_manager.connect(connection.signal, Callable(self, connection.method))
			if connect_result != OK:
				push_warning("GameController: Failed to connect signal: " + connection.signal)
		else:
			push_warning("GameController: DuelManager missing signal: " + connection.signal)
	
	# Initialize duel state safely
	if _has_prop(duel_manager, "duel_state"):
		current_duel_state = duel_manager.duel_state
		if is_instance_valid(current_duel_state) and current_duel_state.has_method("add_change_listener"):
			current_duel_state.add_change_listener(_on_duel_state_changed)
		else:
			push_warning("GameController: DuelState is invalid or missing change listener support")
	else:
		push_warning("GameController: DuelManager missing duel_state property")
	
	if DEBUG_ENABLED:
		GLog.debug("GameController initialized successfully")
	return OK

## Safe test content loading with error boundaries
func _safe_load_test_content() -> void:
	if DEBUG_ENABLED:
		GLog.debug("Loading test content...")
	
	var loading_tasks = [
		{"name": "character", "method": "_load_bushranger_character"},
		{"name": "enemies", "method": "_load_test_enemies"}
	]
	
	var successful_loads = 0
	
	for task in loading_tasks:
		var result = _execute_with_error_boundary(task.method, [])
		if result.success:
			successful_loads += 1
		else:
			push_warning("GameController: Failed to load %s - %s" % [task.name, result.error_message])
	
	if successful_loads > 0:
		test_content_loaded.emit()
		if DEBUG_ENABLED:
			GLog.debug("Test content loading complete: %d/2 tasks successful" % successful_loads)
	else:
		push_error("GameController: All content loading tasks failed")

## Load character with comprehensive validation
func _load_bushranger_character() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	if DEBUG_ENABLED:
		GLog.debug("Loading Bushranger character class...")
	var character_path = "res://data/characters/bushranger.tres"
	
	# Use ResourceManager for safer loading
	if is_instance_valid(ResourceManager):
		player_character = ResourceManager.load_resource(character_path) as CharacterClass
	else:
		# Fallback to direct loading
		if not ResourceLoader.exists(character_path):
			result.error_message = "Character resource not found: " + character_path
			return result
		
		player_character = load(character_path) as CharacterClass
	
	# Validate loaded character
	if not is_instance_valid(player_character):
		result.error_message = "Failed to load character resource at: " + character_path
		return result
	
	# Validate character structure
	if not _validate_character_data(player_character):
		result.error_message = "Character data validation failed for: " + character_path
		return result
	
	if DEBUG_ENABLED:
		GLog.debug("Loaded character: " + player_character.character_class_name)
	
	# Load starting deck safely
	if player_character.has_method("load_starting_deck"):
		test_cards = player_character.load_starting_deck()
		if test_cards.is_empty():
			push_warning("GameController: Character has empty starting deck")
		else:
			if DEBUG_ENABLED:
				GLog.debug("Loaded %d cards for starting deck" % test_cards.size())
	else:
		push_warning("GameController: Character missing load_starting_deck method")
		test_cards = []
	
	result.success = true
	return result

## Load test enemies with validation
func _load_test_enemies() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	var enemy_paths := [
		"res://data/enemies/claim_jumper.tres",
		"res://data/enemies/mad_dog_morgan.tres"
	]
	
	var loaded_count = 0
	var _failed_count = 0
	
	for path in enemy_paths:
		var enemy_data: Resource = null
		
		# Use ResourceManager for safer loading
		if is_instance_valid(ResourceManager):
			enemy_data = ResourceManager.load_resource(path)
		else:
			# Fallback to direct loading
			if ResourceLoader.exists(path):
				enemy_data = load(path)
		
		# Validate loaded enemy
		if is_instance_valid(enemy_data):
			if _validate_enemy_data(enemy_data):
				test_enemies.append(enemy_data)
				loaded_count += 1
				if _has_prop(enemy_data, "enemy_name"):
					if DEBUG_ENABLED:
						GLog.debug("Loaded test enemy: " + enemy_data.enemy_name)
				else:
					if DEBUG_ENABLED:
						GLog.debug("Loaded unnamed enemy from: " + path)
			else:
				_failed_count += 1
				if DEBUG_ENABLED:
					GLog.warn("Enemy data validation failed: " + path)
		else:
			_failed_count += 1
			if DEBUG_ENABLED:
				GLog.warn("Enemy resource not found or invalid: " + path)
	
	if loaded_count > 0:
		result.success = true
		if DEBUG_ENABLED:
			GLog.debug("Loaded %d/%d enemy resources" % [loaded_count, enemy_paths.size()])
	else:
		result.error_message = "Failed to load any enemy resources (%d attempted)" % enemy_paths.size()
	
	return result

## Execute a method with error boundary protection
func _execute_with_error_boundary(method_name: String, args: Array) -> Dictionary:
	var result = {"success": false, "error_message": "Unknown error"}
	
	if not has_method(method_name):
		result.error_message = "Method not found: " + method_name
		_record_error(result.error_message)
		return result
	
	# Call method safely
	# Use callv so we don't pass the entire args Array as a single parameter
	var method_result = callv(method_name, args)
	
	# Handle different return types
	if method_result is Dictionary:
		result = method_result
	elif method_result is bool:
		result.success = method_result
		if not method_result:
			result.error_message = "Method returned false: " + method_name
	else:
		result.success = true  # Assume success for other return types
		
	return result

## Validate character data structure
func _validate_character_data(character: CharacterClass) -> bool:
	if not is_instance_valid(character):
		return false
	
	var required_properties = ["character_class_name", "base_health", "base_energy", "base_sanity"]
	for prop in required_properties:
		if not _has_prop(character, prop):
			push_warning("GameController: Character missing property: " + prop)
			return false
	
	return true

## Validate enemy data structure
func _validate_enemy_data(enemy: Resource) -> bool:
	if not is_instance_valid(enemy):
		return false
	
	var required_properties = ["enemy_name", "health"]
	for prop in required_properties:
		if not _has_prop(enemy, prop):
			push_warning("GameController: Enemy missing property: " + prop)
			return false
	
	return true

## Record and track errors for monitoring
func _record_error(error_message: String) -> void:
	_error_count += 1
	_last_error_time = Time.get_ticks_msec() / 1000.0
	
	# Track critical errors
	if error_message.contains("critical") or error_message.contains("fatal"):
		_critical_errors.append(error_message)
		
		# Limit critical error history
		if _critical_errors.size() > 10:
			_critical_errors.pop_front()
	
	GLog.error("GameController error #%d: %s" % [_error_count, error_message])

func start_test_duel() -> Error:
	# Validate prerequisites
	var validation_result = _validate_duel_prerequisites()
	if validation_result != OK:
		return validation_result
	
	# Execute duel start with error boundary
	var result = _execute_with_error_boundary("_safe_start_duel", [])
	if not result.success:
		push_error("GameController: Failed to start duel - %s" % result.error_message)
		return ERR_CANT_CREATE
	
	return OK

## Validate prerequisites for starting a duel
func _validate_duel_prerequisites() -> Error:
	if test_cards.is_empty():
		push_error("GameController: Cannot start duel - No test cards loaded!")
		return ERR_FILE_NOT_FOUND
	
	if test_enemies.is_empty():
		push_error("GameController: Cannot start duel - No test enemies loaded!")
		return ERR_FILE_NOT_FOUND
	
	if not is_instance_valid(player_character):
		push_error("GameController: Cannot start duel - No player character loaded!")
		return ERR_INVALID_DATA
	
	if not is_instance_valid(duel_manager):
		push_error("GameController: Cannot start duel - DuelManager not initialized!")
		return ERR_UNCONFIGURED
	
	return OK

## Safely start a duel with comprehensive error handling
func _safe_start_duel() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	# Apply character class to player data
	var character_apply_result = _execute_with_error_boundary("_safe_apply_character_to_player_data", [])
	if not character_apply_result.success:
		result.error_message = "Failed to apply character: " + character_apply_result.error_message
		return result
	
	# Add test curios safely
	_safe_add_test_curios()
	
	# Prepare duel data
	var player_deck: Array[CardData] = test_cards.duplicate()
	var enemy := test_enemies[0]  # Already validated to have at least one enemy
	
	# Validate deck contents
	if not _validate_deck_contents(player_deck):
		result.error_message = "Player deck validation failed"
		return result
	
	if DEBUG_ENABLED:
		GLog.debug("Starting duel as %s with enemy: %s" % [player_character.character_class_name, enemy.enemy_name])
	
	# Start the duel
	duel_manager.start_new_duel(player_deck, enemy)
	result.success = true
	
	return result

## Safely apply character data to player
func _safe_apply_character_to_player_data() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	# Validate prerequisites
	if not is_instance_valid(current_duel_state):
		result.error_message = "Current duel state is invalid"
		return result
	
	if not _has_prop(current_duel_state, "player_data") or not is_instance_valid(current_duel_state.player_data):
		result.error_message = "Player data is invalid"
		return result
	
	if not is_instance_valid(player_character):
		result.error_message = "Player character is invalid"
		return result
	
	var player_data = current_duel_state.player_data
	
	# Set the character class safely
	if player_data.has_method("set_character_class"):
		player_data.set_character_class(player_character)
	else:
		push_warning("GameController: Player data missing set_character_class method")
	
	# Apply base stats from character
	if _has_prop(player_data, "stats") and is_instance_valid(player_data.stats):
		var stats = player_data.stats
		
		# Apply stats safely
		var stat_mappings = {
			"max_health": "base_health",
			"current_health": "base_health",
			"max_sanity": "base_sanity",
			"current_sanity": "base_sanity",
			"max_energy": "base_energy",
			"current_energy": "base_energy",
			"current_gold": "starting_gold"
		}
		
		for stat_name in stat_mappings:
			var char_property = stat_mappings[stat_name]
			
			if _has_prop(stats, stat_name) and _has_prop(player_character, char_property):
				stats.set(stat_name, player_character.get(char_property))
	else:
		push_warning("GameController: Player data missing stats")
	
	if DEBUG_ENABLED:
		GLog.debug("Applied %s stats: %d health, %d sanity, %d energy, %d gold" % [
			player_character.character_class_name,
			player_character.base_health,
			player_character.base_sanity,
			player_character.base_energy,
			player_character.starting_gold
		])
	
	result.success = true
	return result

## Safely add test curios
func _safe_add_test_curios() -> void:
	if not is_instance_valid(CurioManager):
		if DEBUG_ENABLED:
			GLog.debug("CurioManager not available")
		return
	
	if not CurioManager.has_method("get_active_curios") or not CurioManager.has_method("debug_add_curio"):
		if DEBUG_ENABLED:
			GLog.debug("CurioManager missing required methods")
		return
	
	var active_curios = CurioManager.get_active_curios()
	if active_curios.is_empty():
		if DEBUG_ENABLED:
			GLog.debug("Adding test curios for debugging")
		var test_curios = ["Lucky Nugget", "Iron Horseshoe", "Bush Tea"]
		
		for curio_name in test_curios:
			CurioManager.debug_add_curio(curio_name)

## Validate deck contents
func _validate_deck_contents(deck: Array[CardData]) -> bool:
	if deck.is_empty():
		push_warning("GameController: Deck is empty")
		return false
	
	var valid_cards = 0
	var invalid_cards = 0
	
	for card in deck:
		if is_instance_valid(card):
			if _has_prop(card, "card_name") and _has_prop(card, "effects"):
				valid_cards += 1
			else:
				invalid_cards += 1
				if DEBUG_ENABLED:
					GLog.warn("Invalid card structure in deck")
		else:
			invalid_cards += 1
			if DEBUG_ENABLED:
				GLog.warn("Null card found in deck")
	
	if invalid_cards > 0:
		push_warning("GameController: Deck has %d invalid cards out of %d total" % [invalid_cards, deck.size()])
	
	return valid_cards > 0

## Get error diagnostics for monitoring
func get_error_diagnostics() -> Dictionary:
	return {
		"error_count": _error_count,
		"last_error_time": _last_error_time,
		"critical_errors": _critical_errors.duplicate(),
		"content_status": {
			"test_cards_loaded": test_cards.size(),
			"test_enemies_loaded": test_enemies.size(),
			"character_loaded": is_instance_valid(player_character),
			"duel_manager_valid": is_instance_valid(duel_manager)
		}
	}

func get_deck_count() -> int:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_deck_count"):
		return duel_manager.get_deck_count()
	return 0

func get_discard_count() -> int:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_discard_count"):
		return duel_manager.get_discard_count()
	return 0

func get_hand_cards() -> Array:
	if is_instance_valid(duel_manager) and duel_manager.has_method("get_hand_cards"):
		return duel_manager.get_hand_cards()
	return []

func play_card(card_data: CardData) -> Error:
	if not is_instance_valid(card_data):
		push_error("GameController: Cannot play invalid card")
		return ERR_INVALID_PARAMETER
	
	if not is_instance_valid(duel_manager):
		push_error("GameController: Cannot play card - DuelManager is invalid")
		return ERR_UNCONFIGURED
	
	if not duel_manager.has_method("play_card"):
		push_error("GameController: DuelManager missing play_card method")
		return ERR_METHOD_NOT_FOUND
	
	duel_manager.play_card(card_data)
	return OK

func end_player_turn() -> Error:
	if not is_instance_valid(duel_manager):
		push_error("GameController: Cannot end turn - DuelManager is invalid")
		return ERR_UNCONFIGURED
	
	if not is_instance_valid(current_duel_state):
		push_error("GameController: Cannot end turn - Duel state is invalid")
		return ERR_INVALID_DATA
	
	if not current_duel_state.has_property("is_player_turn"):
		push_warning("GameController: Cannot verify player turn state")
		# Continue anyway - let DuelManager handle turn validation
	elif not current_duel_state.is_player_turn:
		push_warning("GameController: Not currently player's turn")
		return ERR_DOES_NOT_EXIST
	
	if duel_manager.has_method("end_player_turn"):
		duel_manager.end_player_turn()
		return OK
	else:
		push_error("GameController: DuelManager missing end_player_turn method")
		return ERR_METHOD_NOT_FOUND

func add_random_card_to_hand() -> Error:
	if test_cards.is_empty():
		push_warning("GameController: Cannot add card - No test cards available")
		return ERR_FILE_NOT_FOUND
	
	if not is_instance_valid(current_duel_state):
		push_error("GameController: Cannot add card - Duel state is invalid")
		return ERR_INVALID_DATA
	
	if not current_duel_state.has_property("hand") or not is_instance_valid(current_duel_state.hand):
		push_error("GameController: Cannot add card - Hand is invalid")
		return ERR_INVALID_DATA
	
	var random_card := test_cards[randi() % test_cards.size()]
	if current_duel_state.hand.has_method("add_card"):
		current_duel_state.hand.add_card(random_card)
		game_state_updated.emit()
		return OK
	else:
		push_error("GameController: Hand missing add_card method")
		return ERR_METHOD_NOT_FOUND

func modify_player_health(amount: int) -> Error:
	if not is_instance_valid(current_duel_state):
		push_error("GameController: Cannot modify health - Duel state is invalid")
		return ERR_INVALID_DATA
	
	if not current_duel_state.has_property("player_data") or not is_instance_valid(current_duel_state.player_data):
		push_error("GameController: Cannot modify health - Player data is invalid")
		return ERR_INVALID_DATA
	
	var player_data = current_duel_state.player_data
	
	# Validate required properties
	var required_props = ["current_health", "max_health"]
	for prop in required_props:
		if not player_data.has_property(prop):
			push_error("GameController: Player data missing property: " + prop)
			return ERR_INVALID_DATA
	
	player_data.current_health += amount
	player_data.current_health = clampi(
		player_data.current_health,
		0,
		player_data.max_health
	)
	game_state_updated.emit()
	return OK

func modify_player_energy(amount: int) -> Error:
	if not is_instance_valid(current_duel_state):
		push_error("GameController: Cannot modify energy - Duel state is invalid")
		return ERR_INVALID_DATA
	
	if not current_duel_state.has_property("player_data") or not is_instance_valid(current_duel_state.player_data):
		push_error("GameController: Cannot modify energy - Player data is invalid")
		return ERR_INVALID_DATA
	
	var player_data = current_duel_state.player_data
	
	# Validate required properties
	var required_props = ["current_energy", "max_energy"]
	for prop in required_props:
		if not player_data.has_property(prop):
			push_error("GameController: Player data missing property: " + prop)
			return ERR_INVALID_DATA
	
	player_data.current_energy += amount
	player_data.current_energy = clampi(
		player_data.current_energy,
		0,
		player_data.max_energy
	)
	game_state_updated.emit()
	return OK

func _on_duel_started() -> void:
	if DEBUG_ENABLED:
		GLog.debug("Duel started in GameController")
	game_state_updated.emit()
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("duel_started"):
		var enemy_data = null
		if is_instance_valid(current_duel_state) and current_duel_state.has_property("enemy_data"):
			enemy_data = current_duel_state.enemy_data
		
		EventBus.duel_started.emit(enemy_data)

func _on_duel_ended(winner: String) -> void:
	if DEBUG_ENABLED:
		GLog.debug("Duel ended - Winner: " + winner)
	
	if winner.is_empty():
		push_warning("GameController: Duel ended with empty winner string")
		winner = "unknown"
	
	var victory := winner == "player"
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("duel_ended"):
		EventBus.duel_ended.emit(victory)
	
	# Update statistics safely
	if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
		var stat_name = "enemies_defeated" if victory else "defeats"
		GameManager.increment_statistic(stat_name)

func _on_turn_started(is_player_turn: bool) -> void:
	if DEBUG_ENABLED:
		GLog.debug("Turn started: " + ("Player" if is_player_turn else "Enemy"))
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("turn_started"):
		var current_turn = 0
		if is_instance_valid(current_duel_state) and current_duel_state.has_property("current_turn"):
			current_turn = current_duel_state.current_turn
		
		EventBus.turn_started.emit(current_turn)
	
	game_state_updated.emit()

func _on_card_played(card_data: CardData) -> void:
	var card_name = "Unknown Card"
	if is_instance_valid(card_data) and card_data.has_property("card_name"):
		card_name = card_data.card_name
	
	if DEBUG_ENABLED:
		GLog.debug("Card played: " + card_name)
	
	# Update statistics safely
	if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
		GameManager.increment_statistic("cards_played")
	
	game_state_updated.emit()

func _on_duel_state_changed(change_type: String, _data: Dictionary) -> void:
	game_state_updated.emit()
	
	if change_type.is_empty():
		push_warning("GameController: Duel state changed with empty change type")
		return
	
	# Handle specific change types safely
	match change_type:
		"damage_dealt":
			if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
				var amount = _data.get("amount", 0)
				if amount > 0:
					GameManager.increment_statistic("damage_dealt", amount)
		_:
			if DEBUG_ENABLED:
				GLog.debug("Duel state changed: %s" % change_type)
