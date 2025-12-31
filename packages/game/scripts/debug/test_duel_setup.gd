extends Control
class_name TestDuelSetupController

const DEBUG_ENABLED = true

# UI References
@onready var character_dropdown: OptionButton = $MarginContainer/VBoxContainer/ConfigSection/CharacterRow/CharacterDropdown
@onready var deck_dropdown: OptionButton = $MarginContainer/VBoxContainer/ConfigSection/DeckRow/DeckDropdown
@onready var enemy_dropdown: OptionButton = $MarginContainer/VBoxContainer/ConfigSection/EnemyRow/EnemyDropdown
@onready var curio_list: ItemList = $MarginContainer/VBoxContainer/ConfigSection/CurioRow/CurioList
@onready var health_slider: HSlider = $MarginContainer/VBoxContainer/ConfigSection/HealthRow/HealthSlider
@onready var health_label: Label = $MarginContainer/VBoxContainer/ConfigSection/HealthRow/HealthValue
@onready var energy_slider: HSlider = $MarginContainer/VBoxContainer/ConfigSection/EnergyRow/EnergySlider
@onready var energy_label: Label = $MarginContainer/VBoxContainer/ConfigSection/EnergyRow/EnergyValue
@onready var start_button: Button = $MarginContainer/VBoxContainer/ButtonRow/StartButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonRow/BackButton

# Loaded resources
var characters: Array[Resource] = []
var decks: Array[Resource] = []
var enemies: Array[Resource] = []
var curios: Array[Resource] = []

func _ready() -> void:
	_scan_resources()
	_populate_dropdowns()
	_setup_connections()
	_update_slider_labels()

func _scan_resources() -> void:
	# Scan characters
	characters = _scan_directory("res://data/characters/", "tres")
	GLog.debug("Found %d characters" % characters.size())

	# Scan decks (character + test directories)
	decks = _scan_directory("res://data/decks/character/", "tres")
	decks.append_array(_scan_directory("res://data/decks/test/", "tres"))
	GLog.debug("Found %d decks" % decks.size())

	# Scan enemies
	enemies = _scan_directory("res://data/enemies/", "tres")
	GLog.debug("Found %d enemies" % enemies.size())

	# Scan curios (all subdirectories)
	curios = _scan_directory("res://data/curios/starting/", "tres")
	curios.append_array(_scan_directory("res://data/curios/common/", "tres"))
	curios.append_array(_scan_directory("res://data/curios/rare/", "tres"))
	curios.append_array(_scan_directory("res://data/curios/legendary/", "tres"))
	GLog.debug("Found %d curios" % curios.size())

func _scan_directory(path: String, extension: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with("." + extension):
				var full_path = path + file_name
				var resource = load(full_path)
				if resource:
					result.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

func _populate_dropdowns() -> void:
	# Characters
	character_dropdown.clear()
	for character in characters:
		var name = character.get("class_name") if character.get("class_name") else character.resource_path.get_file().get_basename()
		character_dropdown.add_item(name)

	# Decks
	deck_dropdown.clear()
	for deck in decks:
		var name = deck.get("deck_name") if deck.get("deck_name") else deck.resource_path.get_file().get_basename()
		deck_dropdown.add_item(name)

	# Enemies
	enemy_dropdown.clear()
	for enemy in enemies:
		var name = enemy.get("enemy_name") if enemy.get("enemy_name") else enemy.resource_path.get_file().get_basename()
		enemy_dropdown.add_item(name)

	# Curios (multi-select list)
	curio_list.clear()
	for curio in curios:
		var name = curio.get("curio_name") if curio.get("curio_name") else curio.resource_path.get_file().get_basename()
		curio_list.add_item(name)

func _setup_connections() -> void:
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	health_slider.value_changed.connect(_on_health_changed)
	energy_slider.value_changed.connect(_on_energy_changed)
	character_dropdown.item_selected.connect(_on_character_selected)

func _update_slider_labels() -> void:
	health_label.text = str(int(health_slider.value))
	energy_label.text = str(int(energy_slider.value))

func _on_health_changed(value: float) -> void:
	health_label.text = str(int(value))

func _on_energy_changed(value: float) -> void:
	energy_label.text = str(int(value))

func _on_character_selected(index: int) -> void:
	# Update health slider to character's base health
	if index >= 0 and index < characters.size():
		var character = characters[index]
		var base_health = character.get("base_health") if character.get("base_health") else 50
		health_slider.value = base_health
		var base_energy = character.get("base_energy") if character.get("base_energy") else 3
		energy_slider.value = base_energy

func _on_start_pressed() -> void:
	GLog.info("Starting test duel")

	var character_idx = character_dropdown.selected
	var deck_idx = deck_dropdown.selected
	var enemy_idx = enemy_dropdown.selected

	if character_idx < 0 or deck_idx < 0 or enemy_idx < 0:
		GLog.warn("Please select character, deck, and enemy")
		return

	var character = characters[character_idx]
	var deck = decks[deck_idx]
	var enemy = enemies[enemy_idx]

	# Get selected curios
	var selected_curios: Array[Resource] = []
	for i in curio_list.get_selected_items():
		selected_curios.append(curios[i])

	var health_override = int(health_slider.value)
	var energy_override = int(energy_slider.value)

	_start_test_duel(character, deck, enemy, selected_curios, health_override, energy_override)

func _start_test_duel(character: Resource, deck: Resource, enemy: Resource, selected_curios: Array[Resource], health: int, energy: int) -> void:
	GLog.info("Test duel config: Character=%s, Deck=%s, Enemy=%s, Curios=%d, HP=%d, Energy=%d" % [
		character.get("class_name") if character else "None",
		deck.get("deck_name") if deck else "None",
		enemy.get("enemy_name") if enemy else "None",
		selected_curios.size(),
		health,
		energy
	])

	# Clear any existing curios
	CurioManager.clear_curios()

	# Add selected curios
	for curio in selected_curios:
		CurioManager.add_curio(curio)

	# Convert DeckData to Array[CardData]
	var player_deck: Array[CardData] = []
	if deck and deck.has_method("get") and deck.get("card_paths"):
		for card_path in deck.card_paths:
			var card = load(card_path) as CardData
			if card:
				player_deck.append(card)

	if player_deck.is_empty():
		GLog.error("Failed to load deck cards")
		return

	# Create DuelConfig with modifiers for health/energy overrides
	var modifiers = {
		"test_duel": true,
		"health_override": health,
		"energy_override": energy
	}

	var duel_config = DuelConfig.new(player_deck, enemy, "test_duel", modifiers)

	if not duel_config.is_valid():
		GLog.error("Invalid duel config: %s" % str(duel_config.get_validation_errors()))
		return

	# Store in GameManager
	GameManager.pending_duel_config = duel_config

	# Transition to duel scene
	SceneManager.load_scene("res://scenes/game/duel.tscn")

func _on_back_pressed() -> void:
	SceneManager.load_scene("res://scenes/ui/main_menu.tscn")
