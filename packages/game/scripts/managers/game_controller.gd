extends Node

const DEBUG_ENABLED: bool = true

signal game_state_updated()
signal duel_started()
signal duel_ended(victory: bool)

var duel_manager: Node
var current_duel_state: Resource
var error_manager: ErrorManager

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
	GLog.debug("GameController initialized - Managing the game state")
	error_manager = ErrorManager.new()

## Initialize with comprehensive error handling
func initialize(duel_manager_ref: Node) -> Error:
	if not is_instance_valid(duel_manager_ref):
		error_manager.record_error("Cannot initialize - DuelManager reference is invalid", "initialization")
		return ERR_INVALID_PARAMETER
	
	duel_manager = duel_manager_ref
	
	# Validate required methods on duel manager
	var required_methods = ["start_new_duel", "end_player_turn", "play_card"]
	for method in required_methods:
		if not duel_manager.has_method(method):
			error_manager.record_error("DuelManager missing required method: " + method, "initialization")
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
	
	GLog.debug("GameController initialized successfully")
	return OK

## Start a new duel with the provided deck and enemy
func start_duel(player_deck: Array[CardData], enemy: Resource) -> Error:
	if not is_instance_valid(duel_manager):
		error_manager.record_error("Cannot start duel - DuelManager not initialized", "duel")
		return ERR_UNCONFIGURED
	
	if player_deck.is_empty():
		error_manager.record_error("Cannot start duel - Player deck is empty", "duel")
		return ERR_INVALID_PARAMETER
	
	if not is_instance_valid(enemy):
		error_manager.record_error("Cannot start duel - Enemy is invalid", "duel")
		return ERR_INVALID_PARAMETER
	
	# Validate deck contents
	if not _validate_deck_contents(player_deck):
		error_manager.record_error("Player deck validation failed", "duel")
		return ERR_INVALID_DATA
	
	GLog.debug("Starting duel with enemy: %s" % enemy.get("enemy_name"))
	duel_manager.start_new_duel(player_deck, enemy)
	
	return OK

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
				GLog.warn("Invalid card structure in deck")
		else:
			invalid_cards += 1
			GLog.warn("Null card found in deck")
	
	if invalid_cards > 0:
		push_warning("GameController: Deck has %d invalid cards out of %d total" % [invalid_cards, deck.size()])
	
	return valid_cards > 0

## Get error diagnostics for monitoring
func get_error_diagnostics() -> Dictionary:
	if error_manager:
		return error_manager.get_diagnostics()
	return {}

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

func play_card(card_instance: CardInstance) -> Error:
	if not is_instance_valid(card_instance):
		error_manager.record_error("Cannot play invalid card instance", "gameplay")
		return ERR_INVALID_PARAMETER
	
	if not is_instance_valid(duel_manager):
		error_manager.record_error("Cannot play card - DuelManager is invalid", "gameplay")
		return ERR_UNCONFIGURED
	
	if not duel_manager.has_method("play_card"):
		error_manager.record_error("DuelManager missing play_card method", "gameplay")
		return ERR_METHOD_NOT_FOUND
	
	duel_manager.play_card(card_instance)
	return OK

func end_player_turn() -> Error:
	if not is_instance_valid(duel_manager):
		error_manager.record_error("Cannot end turn - DuelManager is invalid", "gameplay")
		return ERR_UNCONFIGURED
	
	if not is_instance_valid(current_duel_state):
		error_manager.record_error("Cannot end turn - Duel state is invalid", "gameplay")
		return ERR_INVALID_DATA
	
	if not _has_prop(current_duel_state, "is_player_turn"):
		push_warning("GameController: Cannot verify player turn state")
		# Continue anyway - let DuelManager handle turn validation
	elif not current_duel_state.is_player_turn:
		push_warning("GameController: Not currently player's turn")
		return ERR_DOES_NOT_EXIST
	
	if duel_manager.has_method("end_player_turn"):
		duel_manager.end_player_turn()
		return OK
	else:
		error_manager.record_error("DuelManager missing end_player_turn method", "gameplay")
		return ERR_METHOD_NOT_FOUND

func modify_player_health(amount: int) -> Error:
	if not is_instance_valid(current_duel_state):
		error_manager.record_error("Cannot modify health - Duel state is invalid", "gameplay")
		return ERR_INVALID_DATA
	
	if not _has_prop(current_duel_state, "player_data") or not is_instance_valid(current_duel_state.player_data):
		error_manager.record_error("Cannot modify health - Player data is invalid", "gameplay")
		return ERR_INVALID_DATA
	
	var player_data = current_duel_state.player_data
	
	# Validate required properties
	var required_props = ["current_health", "max_health"]
	for prop in required_props:
		if not _has_prop(player_data, prop):
			error_manager.record_error("Player data missing property: " + prop, "gameplay")
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
		error_manager.record_error("Cannot modify energy - Duel state is invalid", "gameplay")
		return ERR_INVALID_DATA
	
	if not _has_prop(current_duel_state, "player_data") or not is_instance_valid(current_duel_state.player_data):
		error_manager.record_error("Cannot modify energy - Player data is invalid", "gameplay")
		return ERR_INVALID_DATA
	
	var player_data = current_duel_state.player_data
	
	# Validate required properties
	var required_props = ["current_energy", "max_energy"]
	for prop in required_props:
		if not _has_prop(player_data, prop):
			error_manager.record_error("Player data missing property: " + prop, "gameplay")
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
	GLog.debug("Duel started in GameController")
	game_state_updated.emit()
	duel_started.emit()
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("duel_started"):
		var enemy_data = null
		if is_instance_valid(current_duel_state) and _has_prop(current_duel_state, "enemy_data"):
			enemy_data = current_duel_state.enemy_data
		
		EventBus.duel_started.emit(enemy_data)

func _on_duel_ended(winner: String) -> void:
	GLog.debug("Duel ended - Winner: " + winner)
	
	if winner.is_empty():
		push_warning("GameController: Duel ended with empty winner string")
		winner = "unknown"
	
	var victory := winner == "player"
	duel_ended.emit(victory)
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("duel_ended"):
		EventBus.duel_ended.emit(victory)
	
	# Update statistics safely
	if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
		var stat_name = "enemies_defeated" if victory else "defeats"
		GameManager.increment_statistic(stat_name)

func _on_turn_started(is_player_turn: bool) -> void:
	GLog.debug("Turn started: " + ("Player" if is_player_turn else "Enemy"))
	
	# Emit event safely
	if is_instance_valid(EventBus) and EventBus.has_signal("turn_started"):
		var current_turn = 0
		if is_instance_valid(current_duel_state) and _has_prop(current_duel_state, "current_turn"):
			current_turn = current_duel_state.current_turn
		
		EventBus.turn_started.emit(current_turn)
	
	game_state_updated.emit()

func _on_card_played(card) -> void:
	var card_name = "Unknown Card"
	if card and typeof(card) == TYPE_OBJECT:
		# Support both CardInstance and CardData
		if _has_prop(card, "get_card_name"):
			card_name = card.get_card_name()
		elif _has_prop(card, "card_name"):
			card_name = card.card_name
	
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
			GLog.debug("Duel state changed: %s" % change_type)