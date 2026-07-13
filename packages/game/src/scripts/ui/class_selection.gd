extends Control
class_name ClassSelectionController

const CLASS_PATHS: Array[String] = [
	"res://data/characters/bushranger.tres",
	"res://data/characters/prospector.tres",
	"res://data/characters/tracker.tres",
	"res://data/characters/publican.tres",
	"res://data/characters/preacher.tres"
]

@onready var class_container: HBoxContainer = $MainContainer/ClassScroll/ClassContainer
@onready var back_button: Button = $MainContainer/BackButton
@onready var seed_label: Label = $SeedContainer/SeedLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	SeedManager.hash_seed_changed.connect(_on_hash_seed_changed)
	update_seed_display()
	for path in CLASS_PATHS:
		var character := load(path) as CharacterClass
		if character:
			class_container.add_child(_create_class_card(character))


func _create_class_card(character: CharacterClass) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 400)
	var content := VBoxContainer.new()
	panel.add_child(content)

	var title := Label.new()
	title.text = character.character_class_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var description := Label.new()
	description.text = character.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)

	var stats := Label.new()
	stats.text = "Health: %d | Sanity: %d | Energy: %d\nStarting Gold: %d\nDifficulty: %d/4" % [
		character.base_health,
		character.base_sanity,
		character.base_energy,
		character.starting_gold,
		character.difficulty_rating
	]
	content.add_child(stats)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var select_button := Button.new()
	select_button.text = "Select %s" % character.character_class_name
	select_button.pressed.connect(_on_character_selected.bind(character))
	content.add_child(select_button)
	return panel


func update_seed_display() -> void:
	var hash_seed := SeedManager.get_hash_seed_string()
	var is_thematic := SeedManager.is_thematic_seed(hash_seed)
	if hash_seed.is_empty():
		seed_label.text = "Seed: Not Set"
	elif is_thematic:
		seed_label.text = "Seed: %s ✨" % hash_seed
	else:
		seed_label.text = "Seed: %s" % hash_seed


func _on_hash_seed_changed(_new_hash_seed: String) -> void:
	update_seed_display()


func _on_character_selected(character: CharacterClass) -> void:
	if not GameManager.start_new_run(character):
		EventBus.emit_ui_notification("Could not start the curated run", "error")


func _on_back_pressed() -> void:
	SceneManager.load_scene_by_name("main_menu")
