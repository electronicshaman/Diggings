extends Control

const DEBUG_ENABLED: bool = true

signal modal_completed(result: Variant)

@onready var background_panel: Panel = $BackgroundPanel
@onready var modal_container: VBoxContainer = $BackgroundPanel/ModalContainer
@onready var title_label: Label = $BackgroundPanel/ModalContainer/TitleLabel
@onready var description_label: RichTextLabel = $BackgroundPanel/ModalContainer/DescriptionLabel
@onready var flavor_label: Label = $BackgroundPanel/ModalContainer/FlavorLabel
@onready var preview_container: VBoxContainer = $BackgroundPanel/ModalContainer/PreviewContainer
@onready var button_container: HBoxContainer = $BackgroundPanel/ModalContainer/ButtonContainer
@onready var enter_button: Button = $BackgroundPanel/ModalContainer/ButtonContainer/EnterButton
@onready var retreat_button: Button = $BackgroundPanel/ModalContainer/ButtonContainer/RetreatButton

var encounter_instance: EncounterInstance = null
var encounter_data: EncounterData = null

func _ready() -> void:
	GLog.debug("Encounter preview modal ready")
	
	# Set up modal appearance
	_setup_modal_appearance()
	
	# Connect buttons
	enter_button.pressed.connect(_on_enter_pressed)
	retreat_button.pressed.connect(_on_retreat_pressed)
	
	# Make modal focusable for keyboard input
	set_process_input(true)

func _setup_modal_appearance() -> void:
	"""Set up the visual appearance of the modal"""
	# Center the modal on screen
	modal_container.custom_minimum_size = Vector2(600, 400)
	
	# Ensure modal appears above everything
	z_index = 1000

func initialize(data: Dictionary) -> void:
	"""Initialize the modal with encounter data"""
	GLog.debug("Initializing encounter preview modal with data: %s" % str(data.keys()))
	
	if data.has("encounter") and data.encounter:
		encounter_instance = data.encounter as EncounterInstance
		encounter_data = encounter_instance.encounter_data if encounter_instance else null
	
	if encounter_data:
		_display_encounter_info()
	else:
		_display_error()

func _display_encounter_info() -> void:
	"""Display the encounter information"""
	title_label.text = encounter_data.encounter_name
	
	# Use RichTextLabel for description to support formatting
	description_label.text = encounter_data.description
	description_label.fit_content = true
	
	# Show flavor text if available
	if encounter_data.flavor_text and encounter_data.flavor_text != "":
		flavor_label.text = encounter_data.flavor_text
		flavor_label.visible = true
	else:
		flavor_label.visible = false
	
	# Show choice preview
	_display_choice_preview()
	
	GLog.debug("Displayed encounter: %s" % encounter_data.encounter_name)

func _display_choice_preview() -> void:
	"""Display a preview of available choices"""
	# Clear existing preview content
	for child in preview_container.get_children():
		if child.name.begins_with("Choice"):
			child.queue_free()
	
	if not encounter_data or not encounter_data.choices:
		return
	
	# Get available choices based on current game state
	var game_state = _get_current_game_state()
	var available_choices = encounter_data.get_available_choices(game_state)
	
	if available_choices.is_empty():
		var no_choices_label = Label.new()
		no_choices_label.name = "ChoiceNoChoices"
		no_choices_label.text = "No available choices"
		no_choices_label.add_theme_color_override("font_color", Color.GRAY)
		preview_container.add_child(no_choices_label)
		return
	
	# Add choices header
	var choices_header = Label.new()
	choices_header.name = "ChoicesHeader"
	choices_header.text = "Available Choices:"
	choices_header.add_theme_color_override("font_color", Color.YELLOW)
	preview_container.add_child(choices_header)
	
	# Display each choice as a preview
	for i in range(min(available_choices.size(), 4)):  # Limit to 4 choices for space
		var choice = available_choices[i]
		var choice_label = Label.new()
		choice_label.name = "Choice%d" % i
		choice_label.text = "• %s" % choice.choice_text
		choice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice_label.add_theme_color_override("font_color", Color.WHITE)
		preview_container.add_child(choice_label)
	
	if available_choices.size() > 4:
		var more_label = Label.new()
		more_label.name = "ChoiceMore"
		more_label.text = "... and %d more choices" % (available_choices.size() - 4)
		more_label.add_theme_color_override("font_color", Color.GRAY)
		preview_container.add_child(more_label)

func _display_error() -> void:
	"""Display error message when encounter data is invalid"""
	title_label.text = "Encounter Error"
	description_label.text = "Failed to load encounter data."
	flavor_label.visible = false
	
	# Disable enter button
	enter_button.disabled = true
	
	GLog.error("Encounter preview modal: invalid encounter data")

func _get_current_game_state() -> Dictionary:
	"""Get current game state for choice availability checks"""
	var state = {}
	
	if GameManager and GameManager.game_data:
		state["gold"] = GameManager.game_data.get("gold", 0)
		state["corruption"] = GameManager.game_data.get("corruption", 0)
		state["current_act"] = GameManager.game_data.get("current_act", 1)
		
		# Add player data if available
		if GameManager.game_data.has("player") and GameManager.game_data.player:
			var player_data = GameManager.game_data.player
			state["player_data"] = player_data
			state["karma"] = player_data.moral_karma
			state["karma_categories"] = player_data.karma_categories
	
	return state

func _input(event: InputEvent) -> void:
	"""Handle keyboard input"""
	if event.is_action_pressed("ui_accept"):
		_on_enter_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_retreat_pressed()

func _on_enter_pressed() -> void:
	"""Handle enter button - proceed to encounter"""
	GLog.debug("Player chose to enter encounter: %s" % (encounter_data.encounter_name if encounter_data else "unknown"))
	modal_completed.emit("enter")

func _on_retreat_pressed() -> void:
	"""Handle retreat button - cancel encounter"""
	GLog.debug("Player chose to retreat from encounter")
	modal_completed.emit("retreat")

func _notification(what: int) -> void:
	"""Handle notifications"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Treat window close as retreat
		_on_retreat_pressed()
