extends Control
class_name TestDuelSetupController

const DEBUG_ENABLED = true

# UI References
@onready var character_dropdown: OptionButton = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/CharacterRow/CharacterDropdown
@onready var deck_dropdown: OptionButton = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/DeckRow/DeckDropdown
@onready var enemy_dropdown: OptionButton = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/EnemyRow/EnemyDropdown
@onready var curio_container: VBoxContainer = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/CurioRow/CurioScroll/CurioContainer
@onready var health_slider: HSlider = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/HealthRow/HealthSlider
@onready var health_label: Label = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/HealthRow/HealthValue
@onready var energy_slider: HSlider = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/EnergyRow/EnergySlider
@onready var energy_label: Label = $MarginContainer/MainHBox/VBoxContainer/ConfigSection/EnergyRow/EnergyValue
@onready var start_button: Button = $MarginContainer/MainHBox/VBoxContainer/ButtonRow/StartButton
@onready var back_button: Button = $MarginContainer/MainHBox/VBoxContainer/ButtonRow/BackButton
@onready var decklist_container: VBoxContainer = $MarginContainer/MainHBox/DecklistSection/DecklistPanel/DecklistScroll/DecklistContainer

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
	
	if deck_dropdown.item_count > 0:
		if deck_dropdown.selected == -1:
			deck_dropdown.selected = 0
		_update_decklist(deck_dropdown.selected)

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
	curios = _scan_directory("res://data/curios/common/", "tres")
	curios.append_array(_scan_directory("res://data/curios/rare/", "tres"))
	curios.append_array(_scan_directory("res://data/curios/legendary/", "tres"))
	curios.append_array(_scan_directory("res://data/curios/corrupted/", "tres"))
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

	_populate_curio_list()

func _populate_curio_list() -> void:
	# Clear existing
	for child in curio_container.get_children():
		child.queue_free()
	
	curio_container.add_theme_constant_override("separation", 10)
	
	# Group by rarity
	var grouped_curios = {
		"Common": [],
		"Rare": [],
		"Legendary": [],
		"Corrupted": []
	}
	
	for curio in curios:
		var rarity = curio.get("rarity") if curio.get("rarity") else "Common"
		if not grouped_curios.has(rarity):
			grouped_curios[rarity] = []
		grouped_curios[rarity].append(curio)
	
	# Create rows
	for rarity in ["Common", "Rare", "Legendary", "Corrupted"]:
		var rarity_curios = grouped_curios[rarity]
		if rarity_curios.is_empty():
			continue
			
		# Rarity Label
		var label = Label.new()
		label.text = rarity
		label.add_theme_font_size_override("font_size", 14)
		curio_container.add_child(label)
		
		# Flow container for icons
		var flow = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		curio_container.add_child(flow)
		
		for curio in rarity_curios:
			var btn = TextureButton.new()
			btn.custom_minimum_size = Vector2(48, 48)
			btn.ignore_texture_size = true
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			btn.toggle_mode = true
			
			if curio.icon:
				btn.texture_normal = curio.icon
			else:
				# Fallback icon or placeholder
				btn.texture_normal = load("res://icon.svg")
			
			# Visual feedback for selection
			btn.modulate = Color(0.5, 0.5, 0.5) # Dim by default
			btn.toggled.connect(func(is_pressed): 
				btn.modulate = Color.WHITE if is_pressed else Color(0.5, 0.5, 0.5)
			)
			
			btn.tooltip_text = curio.curio_name + "\n" + curio.description
			btn.set_meta("curio_resource", curio)
			flow.add_child(btn)

func _setup_connections() -> void:
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	health_slider.value_changed.connect(_on_health_changed)
	energy_slider.value_changed.connect(_on_energy_changed)
	character_dropdown.item_selected.connect(_on_character_selected)
	deck_dropdown.item_selected.connect(_on_deck_selected)

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

func _on_deck_selected(index: int) -> void:
	_update_decklist(index)

func _update_decklist(index: int) -> void:
	# Clear existing
	for child in decklist_container.get_children():
		child.queue_free()
	
	if index < 0 or index >= decks.size():
		return
		
	var deck = decks[index]
	if not deck or not deck.get("card_paths"):
		return
		
	# Count card occurrences
	var card_counts = {}
	for card_path in deck.card_paths:
		if not card_counts.has(card_path):
			card_counts[card_path] = 0
		card_counts[card_path] += 1
		
	# Display cards
	for card_path in card_counts.keys():
		var card = load(card_path) as CardData
		if not card:
			continue
			
		var count = card_counts[card_path]
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		decklist_container.add_child(hbox)
		
		var cost_label = Label.new()
		cost_label.text = "[%d]" % card.energy_cost
		cost_label.custom_minimum_size = Vector2(35, 0)
		cost_label.add_theme_color_override("font_color", Color.YELLOW)
		hbox.add_child(cost_label)
		
		var name_label = Label.new()
		name_label.text = card.card_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		hbox.add_child(name_label)
		
		if count > 1:
			var count_label = Label.new()
			count_label.text = "x%d" % count
			count_label.add_theme_color_override("font_color", Color.AQUAMARINE)
			hbox.add_child(count_label)

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
	for rarity_row in curio_container.get_children():
		if rarity_row is HFlowContainer:
			for btn in rarity_row.get_children():
				if btn is TextureButton and btn.button_pressed:
					selected_curios.append(btn.get_meta("curio_resource"))

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
