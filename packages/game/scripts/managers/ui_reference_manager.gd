class_name UIReferenceManager
extends RefCounted

## UIReferenceManager - Centralized UI node reference management
##
## This class provides safe, validated access to UI nodes using Godot 4.4 best practices:
## - Uses unique names (%) for critical UI elements
## - Implements null-safe node access
## - Provides graceful degradation for missing nodes
## - Caches validated references for performance

const DEBUG_ENABLED: bool = true

## UI reference cache with validation status
var _ui_cache: Dictionary = {}
var _validation_status: Dictionary = {}
var _root_node: Node = null

## Initialize the UI reference manager with a root node
func initialize(root: Node) -> Error:
	if not is_instance_valid(root):
		push_error("UIReferenceManager: Invalid root node provided")
		return ERR_INVALID_PARAMETER
	
	_root_node = root
	_validate_ui_structure()
	return OK

## Get a UI node reference safely with validation
func get_ui_node(reference_key: String) -> Node:
	if not _ui_cache.has(reference_key):
		_cache_ui_reference(reference_key)
	
	var cached_node = _ui_cache.get(reference_key)
	if not is_instance_valid(cached_node):
		_log_missing_node_warning(reference_key)
		return null
	
	return cached_node

## Get multiple UI nodes at once
func get_ui_nodes(reference_keys: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for key in reference_keys:
		result[key] = get_ui_node(key)
	return result

## Check if a UI node reference exists and is valid
func has_valid_ui_node(reference_key: String) -> bool:
	var node = get_ui_node(reference_key)
	return is_instance_valid(node)

## Update the UI cache for a specific node (useful after UI changes)
func refresh_ui_reference(reference_key: String) -> void:
	_ui_cache.erase(reference_key)
	_validation_status.erase(reference_key)
	_cache_ui_reference(reference_key)

## Clear all cached references (useful when UI structure changes)
func clear_cache() -> void:
	_ui_cache.clear()
	_validation_status.clear()
	GLog.debug("UIReferenceManager: Cache cleared") if DEBUG_ENABLED else null

## Get UI reference dictionary for compatibility with existing code
func get_ui_reference_dictionary() -> Dictionary:
	var references: Dictionary = {}
	
	# Define all UI reference mappings
	var ui_mappings = {
		"player_health": "%PlayerHealthLabel",
		"player_energy": "%PlayerEnergyLabel", 
		"player_defense": "%PlayerDefenseLabel",
		"player_sanity": "%PlayerSanityLabel",
		"player_gold": "%PlayerGoldLabel",
		"character_name": "%CharacterNameLabel",
		"enemy_name": "%EnemyNameLabel",
		"enemy_health": "%EnemyHealthLabel",
		"enemy_defense": "%EnemyDefenseLabel",
		"deck": "%DeckLabel",
		"discard": "%DiscardLabel",
		"turn": "%TurnLabel",
		"phase": "%PhaseLabel",
		"seed": "%SeedLabel",
		"end_turn_button": "%EndTurnButton",
		"debug_panel": "%DebugPanel",
		"hand_area": "%HandArea",
		"enemy_hand_area": "%EnemyHandArea",
		"battlefield_area": "%BattlefieldArea",
		"add_card_button": "%AddCardButton",
		"set_health_button": "%SetHealthButton",
		"set_energy_button": "%SetEnergyButton",
		"reset_duel_button": "%ResetDuelButton",
		"curios_panel": "%CuriosPanel",
		"curios_list": "%CuriosList"
	}
	
	# Get all references
	for key in ui_mappings:
		references[key] = get_ui_node(key)
	
	return references

## Validate the entire UI structure
func _validate_ui_structure() -> void:
	if not is_instance_valid(_root_node):
		push_error("UIReferenceManager: Root node is invalid")
		return
	
	GLog.debug("UIReferenceManager: Validating UI structure...") if DEBUG_ENABLED else null
	
	# Pre-validate critical UI paths using unique names
	var critical_references = [
		"player_health", "player_energy", "enemy_health", 
		"end_turn_button", "hand_area"
	]
	
	var missing_count = 0
	for ref_key in critical_references:
		if not _cache_ui_reference(ref_key):
			missing_count += 1
	
	if missing_count > 0:
		push_warning("UIReferenceManager: %d critical UI references are missing" % missing_count)
	else:
		GLog.debug("UIReferenceManager: All critical UI references validated") if DEBUG_ENABLED else null

## Cache a UI reference by finding the appropriate node
func _cache_ui_reference(reference_key: String) -> bool:
	if not is_instance_valid(_root_node):
		return false
	
	var node: Node = null
	
	# Try to find node using unique name first (Godot 4.4 best practice)
	var unique_name = _get_unique_name_for_reference(reference_key)
	if unique_name != "":
		node = _root_node.get_node_or_null(unique_name)
	
	# Fallback to path-based search if unique name fails
	if not is_instance_valid(node):
		var fallback_path = _get_fallback_path_for_reference(reference_key)
		if fallback_path != "":
			node = _root_node.get_node_or_null(fallback_path)
	
	# Cache the result (even if null)
	_ui_cache[reference_key] = node
	_validation_status[reference_key] = is_instance_valid(node)
	
	if DEBUG_ENABLED and is_instance_valid(node):
		GLog.debug("UIReferenceManager: Cached '%s' -> %s" % [reference_key, node.get_path()])
	
	return is_instance_valid(node)

## Get unique name for a reference key (preferred method)
func _get_unique_name_for_reference(reference_key: String) -> String:
	var unique_names = {
		"player_health": "%PlayerHealthLabel",
		"player_energy": "%PlayerEnergyLabel",
		"player_defense": "%PlayerDefenseLabel", 
		"player_sanity": "%PlayerSanityLabel",
		"player_gold": "%PlayerGoldLabel",
		"character_name": "%CharacterNameLabel",
		"enemy_name": "%EnemyNameLabel",
		"enemy_health": "%EnemyHealthLabel",
		"enemy_defense": "%EnemyDefenseLabel",
		"deck": "%DeckLabel",
		"discard": "%DiscardLabel", 
		"turn": "%TurnLabel",
		"phase": "%PhaseLabel",
		"seed": "%SeedLabel",
		"end_turn_button": "%EndTurnButton",
		"debug_panel": "%DebugPanel",
		"hand_area": "%HandArea",
		"enemy_hand_area": "%EnemyHandArea",
		"battlefield_area": "%BattlefieldArea",
		"add_card_button": "%AddCardButton",
		"set_health_button": "%SetHealthButton",
		"set_energy_button": "%SetEnergyButton",
		"reset_duel_button": "%ResetDuelButton",
		"curios_panel": "%CuriosPanel",
		"curios_list": "%CuriosList"
	}
	
	return unique_names.get(reference_key, "")

## Get fallback path for a reference key (compatibility with existing UI)
func _get_fallback_path_for_reference(reference_key: String) -> String:
	var fallback_paths = {
		"player_health": "UI/Control/PlayerArea/PlayerStats/LeftColumn/HealthLabel",
		"player_energy": "UI/Control/PlayerArea/PlayerStats/LeftColumn/EnergyLabel",
		"player_defense": "UI/Control/PlayerArea/PlayerStats/LeftColumn/DefenseLabel",
		"player_sanity": "UI/Control/PlayerArea/PlayerStats/RightColumn/SanityLabel",
		"player_gold": "UI/Control/PlayerArea/PlayerStats/RightColumn/GoldLabel",
		"character_name": "UI/Control/PlayerArea/PlayerStats/LeftColumn/CharacterNameLabel",
		"enemy_name": "UI/Control/EnemyArea/EnemyStats/EnemyName",
		"enemy_health": "UI/Control/EnemyArea/EnemyStats/EnemyHealth",
		"enemy_defense": "UI/Control/EnemyArea/EnemyStats/EnemyDefense",
		"deck": "UI/Control/PileIndicatorsLeft/DeckLabel",
		"discard": "UI/Control/PileIndicatorsRight/DiscardLabel",
		"turn": "UI/Control/TurnInfo/TurnLabel",
		"phase": "UI/Control/TurnInfo/PhaseLabel",
		"seed": "UI/Control/TurnInfo/SeedLabel",
		"end_turn_button": "UI/Control/TurnInfo/EndTurnButton",
		"debug_panel": "UI/Control/DebugPanel",
		"hand_area": "UI/Control/HandArea",
		"enemy_hand_area": "UI/Control/EnemyHandArea",
		"battlefield_area": "UI/Control/BattlefieldArea",
		"add_card_button": "UI/Control/DebugPanel/DebugButtons/AddCardButton",
		"set_health_button": "UI/Control/DebugPanel/DebugButtons/SetHealthButton", 
		"set_energy_button": "UI/Control/DebugPanel/DebugButtons/SetEnergyButton",
		"reset_duel_button": "UI/Control/DebugPanel/DebugButtons/ResetDuelButton",
		"curios_panel": "UI/Control/CuriosPanel",
		"curios_list": "UI/Control/CuriosPanel/CuriosList"
	}
	
	return fallback_paths.get(reference_key, "")

## Log warning for missing UI node
func _log_missing_node_warning(reference_key: String) -> void:
	if not _validation_status.get(reference_key, false):
		push_warning("UIReferenceManager: UI reference '%s' is missing or invalid" % reference_key)
		GLog.warn("Missing UI reference: %s" % reference_key) if DEBUG_ENABLED else null

## Get validation report for debugging
func get_validation_report() -> Dictionary:
	var report = {
		"total_references": _ui_cache.size(),
		"valid_references": 0,
		"invalid_references": [],
		"cache_status": _validation_status.duplicate()
	}
	
	for key in _validation_status:
		if _validation_status[key]:
			report.valid_references += 1
		else:
			report.invalid_references.append(key)
	
	return report