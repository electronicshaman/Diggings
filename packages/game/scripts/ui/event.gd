extends Control

@onready var title_label = $MainContainer/TitleLabel
@onready var description_label = $MainContainer/DescriptionLabel
@onready var flavor_label = $MainContainer/FlavorLabel
@onready var choices_container = $MainContainer/ChoicesContainer
@onready var return_button = $MainContainer/ReturnToMapButton

var current_encounter: EncounterInstance = null

func _ready():
	return_button.pressed.connect(_on_return_pressed)
	
	# Check if EncounterManager has an active encounter
	var encounter_manager = get_node_or_null("/root/EncounterManager")
	if encounter_manager and encounter_manager.active_event:
		current_encounter = encounter_manager.active_event
		_display_encounter(current_encounter)
	else:
		_display_placeholder()

func _display_encounter(encounter: EncounterInstance):
	if not encounter or not encounter.encounter_data:
		_display_placeholder()
		return
	
	var data = encounter.encounter_data
	title_label.text = data.encounter_name
	description_label.text = data.description
	flavor_label.text = data.flavor_text if data.flavor_text else ""
	
	# Clear any existing choice buttons
	for child in choices_container.get_children():
		child.queue_free()
	
	# Create choice buttons
	var available_choices = data.get_available_choices({})
	for i in range(available_choices.size()):
		var choice = available_choices[i]
		var button = Button.new()
		button.text = choice.choice_text
		button.tooltip_text = choice.choice_description
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)
	
	# Hide return button while encounter is active
	return_button.visible = false

func _display_placeholder():
	title_label.text = "EVENT"
	description_label.text = "No active encounter found. This might be a random event or system error."
	flavor_label.text = "The wilderness holds many mysteries..."
	
	# Clear choices
	for child in choices_container.get_children():
		child.queue_free()
	
	# Show return button
	return_button.visible = true

func _on_choice_selected(choice_index: int):
	if not current_encounter:
		return

	var encounter_manager = get_node_or_null("/root/EncounterManager")
	if encounter_manager:
		encounter_manager.make_choice(choice_index)

		# Wait a moment for outcomes to process
		await get_tree().create_timer(1.0).timeout

		# Check if a duel was prepared by the choice outcome
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager and game_manager.is_duel_prepared():
			_start_combat()
		else:
			_on_return_pressed()


func _start_combat():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		# Start the prepared duel
		game_manager.start_prepared_duel()
	else:
		# Fallback: just load duel scene directly
		SceneManager.load_scene_by_name("duel")

func _on_return_pressed():
	# Clear encounter progress flag in player
	var hexmap_state = get_node_or_null("/root/HexmapState")
	if hexmap_state:
		# This will be handled by the scene transition
		pass
	
	SceneManager.load_scene_by_name("map")