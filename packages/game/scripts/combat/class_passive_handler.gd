## ClassPassiveHandler
## Manages character class passive abilities and their lifecycle.
## Follows Interface Segregation - each passive is a separate, focused method.
extends RefCounted
class_name ClassPassiveHandler

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED: bool = true

# Component dependencies
var duel_state: DuelState
var _connected_signals: Array[Dictionary] = []

func _init(state: DuelState) -> void:
	duel_state = state
	
	if not duel_state:
		GLog.error("ClassPassiveHandler: initialized with null DuelState")
	
	GLog.debug("ClassPassiveHandler: initialized")

# Passive registration methods
func setup_passives() -> void:
	"""Detect class and register appropriate passives"""
	if not duel_state or not duel_state.player_data:
		GLog.error("ClassPassiveHandler: Cannot setup passives - invalid duel state")
		return
	
	var player_class = _get_player_class()
	GLog.info("ClassPassiveHandler: Setting up passives for class: %s" % player_class)
	
	# Register class-specific passives
	match player_class:
		"Preacher":
			_setup_preacher_passives()
		_:
			GLog.debug("ClassPassiveHandler: No passives to register for class: %s" % player_class)

func _setup_preacher_passives() -> void:
	"""Connect Preacher-specific handlers"""
	GLog.debug("ClassPassiveHandler: Setting up Preacher passive abilities")
	
	# Fervent Faith: Gain +1 defense when gaining Faith
	if EventBus.has_signal("resource_gained"):
		var fervent_faith_callable = _on_fervent_faith
		EventBus.connect_safe("resource_gained", fervent_faith_callable)
		_connected_signals.append({
			"signal": "resource_gained",
			"callable": fervent_faith_callable
		})
	
	# Temptation: Choice when reaching max Faith
	if EventBus.has_signal("resource_gained"):
		var temptation_callable = _on_temptation_check
		EventBus.connect_safe("resource_gained", temptation_callable)
		_connected_signals.append({
			"signal": "resource_gained", 
			"callable": temptation_callable
		})
	
	# Holy Conviction: Improve Fortune card success chance based on Faith
	if EventBus.has_signal("gambling_modifier_query"):
		var holy_conviction_callable = _on_holy_conviction
		EventBus.connect_safe("gambling_modifier_query", holy_conviction_callable)
		_connected_signals.append({
			"signal": "gambling_modifier_query",
			"callable": holy_conviction_callable
		})
	
	GLog.info("ClassPassiveHandler: Preacher passives registered: %d signal connections" % _connected_signals.size())

# Class detection methods
func _get_player_class() -> String:
	"""Return player's class name"""
	if not duel_state or not duel_state.player_data:
		return ""
	
	var player = duel_state.player_data
	
	# Check character_class resource first
	if player.character_class and "character_class_name" in player.character_class:
		return player.character_class.character_class_name
	
	# Fallback to character_class_name property
	if player.character_class_name:
		return player.character_class_name
	
	return ""

func _is_class(class_name_param: String) -> bool:
	"""Check if player is specific class"""
	return _get_player_class() == class_name_param

# Preacher passive handlers
func _on_fervent_faith(player_data, resource_name: String, amount: int) -> void:
	"""Fervent Faith: +1 defense when gaining Faith"""
	# Only trigger for Faith resource gains
	if resource_name != "Faith":
		return
	
	# Only trigger for the current player and positive amounts
	if amount <= 0 or player_data != duel_state.player_data:
		return
	
	# Only trigger for Preacher class
	if not _is_class("Preacher"):
		return
	
	# Grant +1 defense
	player_data.gain_defense(1)
	GLog.debug("ClassPassiveHandler: Fervent Faith: Gained 1 defense from Faith gain")

func _on_temptation_check(player_data, resource_name: String, _amount: int) -> void:
	"""Temptation: trigger choice at max Faith"""
	# Only trigger for Faith resource changes
	if resource_name != "Faith":
		return
	
	# Only trigger for the current player
	if player_data != duel_state.player_data:
		return
	
	# Only trigger for Preacher class
	if not _is_class("Preacher"):
		return
	
	# Check if Faith has reached maximum
	var current_faith = player_data.get_resource("Faith")
	var max_faith = player_data.get_resource_max("Faith")
	if max_faith > 0 and current_faith >= max_faith:
		_trigger_temptation_choice()

func _trigger_temptation_choice() -> void:
	"""Execute Temptation effect"""
	var player = duel_state.player_data
	if not player:
		return
	
	# TODO: This needs a modal dialog UI
	# For now, auto-choose gold (safer option)
	var current_faith = player.get_resource("Faith")
	var max_faith = player.get_resource_max("Faith")
	GLog.info("ClassPassiveHandler: Temptation triggered! Max Faith reached (%d/%d)" % [current_faith, max_faith])
	
	# Auto-choose gold for now (25 gold, lose all Faith)
	if player.stats:
		player.stats.gain_gold(25)
		player.reset_resource("Faith")
		GLog.info("ClassPassiveHandler: Temptation: Chose gold. Gained 25 gold, lost all Faith")
	
	# Alternative: gain 3 Corruption and keep Faith
	# player.stats.gain_corruption(3)
	# GLog.info("Temptation: Chose corruption. Gained 3 corruption, kept Faith")

func _on_holy_conviction(player_data: Object, context: Dictionary) -> void:
	"""Holy Conviction: +10% Fortune success at Faith >= 5"""
	# Only trigger for Preacher class
	if not _is_class("Preacher"):
		return
	
	# Only trigger for the current player
	if player_data != duel_state.player_data:
		return
	
	# Check if Faith >= 5
	var current_faith = player_data.get_resource("Faith")
	if current_faith >= 5:
		# Modify the success chance in the context
		if context.has("success_chance"):
			var current_chance: float = context.success_chance
			context.success_chance = min(1.0, current_chance + 0.1)  # Cap at 100%
			GLog.debug("ClassPassiveHandler: Holy Conviction active! Fortune success chance: %.0f%% -> %.0f%%" % [
				current_chance * 100, context.success_chance * 100
			])

# Cleanup method
func cleanup() -> void:
	"""Disconnect all registered signal handlers"""
	GLog.debug("ClassPassiveHandler: Cleaning up signal connections")
	
	for connection in _connected_signals:
		var signal_name = connection.signal
		var callable = connection.callable
		
		if EventBus.has_signal(signal_name):
			EventBus.disconnect_safe(signal_name, callable)
		else:
			GLog.warn("ClassPassiveHandler: Signal '%s' not found during cleanup" % signal_name)
	
	var disconnected_count = _connected_signals.size()
	_connected_signals.clear()
	
	GLog.info("ClassPassiveHandler: cleanup complete: %d connections removed" % disconnected_count)