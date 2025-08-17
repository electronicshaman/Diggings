class_name TestDataManager
extends Node

## TestDataManager - Manages test content loading for development
##
## Separates test/debug content loading from production code.
## Only loaded in debug builds to keep production code clean.

const DEBUG_ENABLED: bool = true

signal test_content_loaded()
signal test_content_failed(error_message: String)

var test_cards: Array[CardData] = []
var test_enemies: Array[Resource] = []
var player_character: CharacterClass
var is_loaded: bool = false

func _ready() -> void:
	if not OS.is_debug_build():
		GLog.warn("TestDataManager loaded in non-debug build - disabling")
		queue_free()
		return
	
	GLog.debug("TestDataManager initialized - Loading test content...")
	_load_all_test_content()

## Load all test content asynchronously
func _load_all_test_content() -> void:
	var success = true
	var error_messages = []
	
	# Load character
	var char_result = await _load_test_character()
	if not char_result.success:
		success = false
		error_messages.append(char_result.error_message)
	
	# Load enemies
	var enemy_result = await _load_test_enemies()
	if not enemy_result.success:
		success = false
		error_messages.append(enemy_result.error_message)
	
	# Load test curios
	_setup_test_curios()
	
	# Signal completion
	if success:
		is_loaded = true
		test_content_loaded.emit()
		GLog.info("Test content loaded successfully")
	else:
		var combined_error = "\n".join(error_messages)
		test_content_failed.emit(combined_error)
		GLog.error("Test content loading failed: " + combined_error)

## Load test character (defaults to selected class or Bushranger)
func _load_test_character() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	# Get selected character class from GameManager, fallback to Bushranger
	var character_class = GameManager.current_character_class if GameManager.current_character_class != "" else "Bushranger"
	GLog.debug("Loading %s character class for testing..." % character_class)
	
	var character_path = "res://data/characters/" + character_class.to_lower() + ".tres"
	
	# Load character resource
	if ResourceLoader.exists(character_path):
		player_character = load(character_path) as CharacterClass
		
		if is_instance_valid(player_character):
			# Load starting deck
			if player_character.has_method("load_starting_deck"):
				test_cards = player_character.load_starting_deck()
				GLog.debug("Loaded %d cards for %s starting deck" % [test_cards.size(), character_class])
			
			result.success = true
			GLog.debug("Test character loaded: " + player_character.character_class_name)
		else:
			result.error_message = "Failed to load character resource: " + character_path
	else:
		result.error_message = "Character resource not found: " + character_path
	
	return result

## Load test enemies
func _load_test_enemies() -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	var enemy_paths := [
		"res://data/enemies/claim_jumper.tres",
		"res://data/enemies/mad_dog_morgan.tres"
	]
	
	var loaded_count = 0
	var failed_paths = []
	
	for path in enemy_paths:
		if ResourceLoader.exists(path):
			var enemy_data = load(path)
			if is_instance_valid(enemy_data):
				test_enemies.append(enemy_data)
				loaded_count += 1
				
				var enemy_name = enemy_data.get("enemy_name") if enemy_data.has_method("get") else "Unknown"
				GLog.debug("Loaded test enemy: " + str(enemy_name))
			else:
				failed_paths.append(path)
		else:
			failed_paths.append(path)
	
	if loaded_count > 0:
		result.success = true
		GLog.debug("Loaded %d/%d test enemies" % [loaded_count, enemy_paths.size()])
	else:
		result.error_message = "Failed to load any test enemies. Failed paths: " + str(failed_paths)
	
	return result

## Setup test curios for debugging
func _setup_test_curios() -> void:
	if not is_instance_valid(CurioManager):
		GLog.debug("CurioManager not available for test curios")
		return
	
	if not CurioManager.has_method("get_active_curios") or not CurioManager.has_method("debug_add_curio"):
		GLog.debug("CurioManager missing required methods for test curios")
		return
	
	var active_curios = CurioManager.get_active_curios()
	if active_curios.is_empty():
		GLog.debug("Adding test curios for debugging")
		var test_curios = ["Lucky Nugget", "Iron Horseshoe", "Bush Tea"]
		
		for curio_name in test_curios:
			CurioManager.debug_add_curio(curio_name)

## Get a random test card
func get_random_test_card() -> CardData:
	if test_cards.is_empty():
		push_warning("TestDataManager: No test cards available")
		return null
	
	return test_cards[randi() % test_cards.size()]

## Get a random test enemy
func get_random_test_enemy() -> Resource:
	if test_enemies.is_empty():
		push_warning("TestDataManager: No test enemies available")
		return null
	
	return test_enemies[randi() % test_enemies.size()]

## Get the first test enemy (for consistent testing)
func get_first_test_enemy() -> Resource:
	if test_enemies.is_empty():
		push_warning("TestDataManager: No test enemies available")
		return null
	
	return test_enemies[0]

## Check if test content is ready
func is_test_content_ready() -> bool:
	return is_loaded and not test_cards.is_empty() and not test_enemies.is_empty()

## Reload all test content (useful for hot-reloading during development)
func reload_test_content() -> void:
	GLog.debug("Reloading test content...")
	test_cards.clear()
	test_enemies.clear()
	player_character = null
	is_loaded = false
	
	_load_all_test_content()