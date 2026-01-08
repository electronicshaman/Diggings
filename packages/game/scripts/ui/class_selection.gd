extends Control
class_name ClassSelectionController

@onready var class_container = $MainContainer/ClassContainer
@onready var back_button = $MainContainer/BackButton
@onready var title_label = $MainContainer/TitleLabel
@onready var seed_label = $VBoxContainer/SeedLabel

var generated_characters: Array[GeneratedCharacter] = []
var character_cards: Array[Control] = []

func _ready():
	setup_button_connections()
	setup_seed_display()
	# Defer character generation until after scene is fully loaded and seed is established
	call_deferred("setup_character_generation")

func setup_character_generation():
	# Ensure seed is established before generating characters
	if not SeedManager.is_run_active() or SeedManager.get_seed_string() == "0":
		GLog.warn("ClassSelection: No active seed detected, character generation may not be deterministic")
	
	# Generate characters for all 4 classes using the established seed
	var classes: Array[String] = ["Bushranger", "Prospector", "Tracker", "Publican"]
	generated_characters = CharacterGenerator.generate_character_set(classes)
	
	GLog.debug("Generated characters with seed: " + SeedManager.get_seed_string())
	
	# Update seed display with current seed
	update_seed_display()
	
	# Clear existing cards and create new ones
	clear_character_cards()
	create_character_cards()
	
	# Update title
	title_label.text = "Choose Your Character"

func clear_character_cards():
	# Remove all existing children from class container
	for child in class_container.get_children():
		child.queue_free()
	character_cards.clear()

func create_character_cards():
	for i in range(generated_characters.size()):
		var character = generated_characters[i]
		var card = create_character_card(character, i)
		class_container.add_child(card)
		character_cards.append(card)

func create_character_card(character: GeneratedCharacter, index: int) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(280, 420)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var content = VBoxContainer.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = 10
	content.offset_right = -10
	content.offset_top = 10
	content.offset_bottom = -10
	card.add_child(content)
	
	# Character name and class
	var name_label = Label.new()
	name_label.text = character.formatted_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	content.add_child(name_label)
	
	var class_label = Label.new()
	class_label.text = character.character_class.to_upper()
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.add_theme_font_size_override("font_size", 14)
	content.add_child(class_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	content.add_child(spacer1)
	
	# Backstory summary
	var backstory_label = Label.new()
	backstory_label.text = get_backstory_summary(character)
	backstory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backstory_label.custom_minimum_size = Vector2(0, 60)
	backstory_label.add_theme_font_size_override("font_size", 12)
	content.add_child(backstory_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	content.add_child(spacer2)
	
	# Stats with modifiers
	var stats_label = Label.new()
	stats_label.text = get_stats_display(character)
	stats_label.add_theme_font_size_override("font_size", 11)
	content.add_child(stats_label)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	content.add_child(spacer3)
	
	# Starting curio
	var curio_label = Label.new()
	curio_label.text = get_starting_curio_display(character)
	curio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	curio_label.custom_minimum_size = Vector2(0, 40)
	curio_label.add_theme_font_size_override("font_size", 10)
	content.add_child(curio_label)
	
	# Spacer to push button to bottom
	var spacer4 = Control.new()
	spacer4.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer4)
	
	# Select button
	var select_button = Button.new()
	select_button.text = "Select " + character.full_name
	select_button.pressed.connect(_on_character_selected.bind(index))
	content.add_child(select_button)
	
	return card

func get_backstory_summary(character: GeneratedCharacter) -> String:
	return character.backstory_summary

func get_stats_display(character: GeneratedCharacter) -> String:
	var display = ""
	display += "Health: " + str(character.base_health)
	display += " | Sanity: " + str(character.base_sanity)
	display += " | Energy: " + str(character.base_energy)
	display += "\nGold: " + str(character.starting_gold)
	
	# Show significant modifiers
	var mod_text = []
	for mod in character.stat_modifiers:
		var value = character.stat_modifiers[mod]
		if abs(value) >= 5: # Only show significant modifiers
			var sign_str = "+" if value > 0 else ""
			mod_text.append(mod.capitalize() + " " + sign_str + str(value))
	
	if not mod_text.is_empty():
		display += "\nModifiers: " + ", ".join(mod_text)
	
	return display

func get_base_stats(character_class: String) -> Dictionary:
	"""Get base stats for a character class from the character resource"""
	var character_path = "res://data/characters/" + character_class.to_lower() + ".tres"
	
	if ResourceLoader.exists(character_path):
		var character_resource = load(character_path) as CharacterClass
		if character_resource:
			return character_resource.get_starting_stats()
	
	GLog.warn("Failed to load character resource for %s, using fallback stats" % character_class)
	# Fallback stats if resource loading fails
	return {"base_health": 50, "base_sanity": 100, "base_energy": 3, "starting_gold": 10}

func get_starting_curio_display(character: GeneratedCharacter) -> String:
	# Get the curio resource 
	if character.starting_curio:
		var curio_resource = character.starting_curio
		if curio_resource.has_method("get") and curio_resource.curio_name:
			var curio_name = curio_resource.curio_name if curio_resource.curio_name else "Unknown Curio"
			var curio_desc = curio_resource.description if curio_resource.description else "No description"
			return "Starting Curio: " + curio_name + "\n" + curio_desc

	return "Starting Curio: Unknown"

func setup_button_connections():
	back_button.pressed.connect(_on_back_pressed)

func setup_seed_display():
	# Connect to seed change signals to update display dynamically
	if SeedManager.hash_seed_changed.is_connected(_on_hash_seed_changed):
		SeedManager.hash_seed_changed.disconnect(_on_hash_seed_changed)
	SeedManager.hash_seed_changed.connect(_on_hash_seed_changed)
	
	# Initial seed display update
	update_seed_display()

func update_seed_display():
	var hash_seed = SeedManager.get_hash_seed_string()
	var is_thematic = SeedManager.is_thematic_seed(hash_seed)
	
	if hash_seed.is_empty():
		seed_label.text = "Seed: Not Set"
	elif is_thematic:
		seed_label.text = "Seed: " + hash_seed + " ✨" # Special indicator for thematic seeds
	else:
		seed_label.text = "Seed: " + hash_seed

func _on_hash_seed_changed(_new_hash_seed: String):
	update_seed_display()

func _on_character_selected(character_index: int):
	var character = generated_characters[character_index]
	GLog.info("Selected character: " + character.formatted_name + " the " + character.character_class)
	
	# Store selected character in GameManager
	GameManager.selected_character = character
	GameManager.start_new_run(character.character_class)

func _on_back_pressed():
	GLog.info("Returning to main menu")
	SceneManager.load_scene_by_name("main_menu")
