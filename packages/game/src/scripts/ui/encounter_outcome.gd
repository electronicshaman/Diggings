extends Control

const DEBUG_ENABLED: bool = true

@onready var title_label: Label = $MainContainer/TitleLabel
@onready var narrative_label: RichTextLabel = $MainContainer/NarrativeLabel
@onready var karma_narrative_label: Label = $MainContainer/KarmaNarrativeLabel
@onready var outcomes_container: VBoxContainer = $MainContainer/OutcomesContainer
@onready var continue_button: Button = $MainContainer/ContinueButton

var triggers_combat: bool = false


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)

	var encounter_manager = get_node_or_null("/root/EncounterManager")
	if encounter_manager and encounter_manager.last_outcome_data:
		_display_outcome(encounter_manager.last_outcome_data)
		triggers_combat = encounter_manager.last_triggers_combat
	else:
		_display_placeholder()

	continue_button.text = "To Battle!" if triggers_combat else "Continue"


func _display_outcome(outcome_data: EncounterOutcomeData) -> void:
	title_label.text = "What Happened..."

	# Display narrative text
	_display_narratives(outcome_data)

	# Display mechanical outcomes
	_display_mechanical_outcomes(outcome_data)


func _display_narratives(outcome_data: EncounterOutcomeData) -> void:
	# Combine all narrative descriptions
	var combined_narrative = outcome_data.get_combined_narrative()
	narrative_label.text = combined_narrative if combined_narrative != "" else "You continue on your way."

	# Display karma narrative if present (italicized flavor)
	var karma_narrative = outcome_data.get_primary_karma_narrative()
	if karma_narrative != "":
		karma_narrative_label.text = karma_narrative
		karma_narrative_label.visible = true
	else:
		karma_narrative_label.visible = false


func _display_mechanical_outcomes(outcome_data: EncounterOutcomeData) -> void:
	# Clear existing outcome displays
	for child in outcomes_container.get_children():
		child.queue_free()

	var has_outcomes = false

	# Gold change
	if outcome_data.gold_change != 0:
		_add_outcome_row("Gold", outcome_data.gold_change, Color.YELLOW)
		has_outcomes = true

	# Health change (positive = heal, negative = damage)
	if outcome_data.health_change != 0:
		var color = Color.GREEN if outcome_data.health_change > 0 else Color.RED
		var label_text = "Healed" if outcome_data.health_change > 0 else "Damage Taken"
		_add_outcome_row(label_text, abs(outcome_data.health_change), color)
		has_outcomes = true

	# Sanity change
	if outcome_data.sanity_change != 0:
		var color = Color.CYAN if outcome_data.sanity_change > 0 else Color.DARK_CYAN
		var label_text = "Sanity Restored" if outcome_data.sanity_change > 0 else "Sanity Lost"
		_add_outcome_row(label_text, abs(outcome_data.sanity_change), color)
		has_outcomes = true

	# Corruption change
	if outcome_data.corruption_change != 0:
		var color = Color.PURPLE if outcome_data.corruption_change > 0 else Color.MEDIUM_PURPLE
		_add_outcome_row("Corruption", outcome_data.corruption_change, color)
		has_outcomes = true

	# Karma changes by category
	for category in outcome_data.karma_changes:
		var amount = outcome_data.karma_changes[category]
		if amount != 0:
			var color = Color.GREEN if amount > 0 else Color.RED
			_add_outcome_row("%s Karma" % category.capitalize(), amount, color)
			has_outcomes = true

	# Curios gained
	for curio in outcome_data.curios_gained:
		var curio_name = curio.curio_name if curio.get("curio_name") else str(curio)
		_add_outcome_row_text("Curio Found", curio_name, Color.ORANGE)
		has_outcomes = true

	# Cards gained
	for card in outcome_data.cards_gained:
		var card_name = card.card_name if card.get("card_name") else str(card)
		_add_outcome_row_text("Card Added", card_name, Color.CYAN)
		has_outcomes = true

	# Combat triggered
	if outcome_data.combat_triggered:
		var enemy_text = outcome_data.enemy_name if outcome_data.enemy_name != "" else "an enemy"
		_add_outcome_row_text("Combat", "You must face %s!" % enemy_text, Color.ORANGE_RED)
		has_outcomes = true

	# If no mechanical outcomes, show a simple message
	if not has_outcomes:
		var no_change_label = Label.new()
		no_change_label.text = "No material changes."
		no_change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_change_label.add_theme_color_override("font_color", Color.GRAY)
		outcomes_container.add_child(no_change_label)


func _add_outcome_row(label_text: String, value: int, color: Color) -> void:
	var row = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = label_text + ":"
	name_label.custom_minimum_size.x = 150

	var value_label = Label.new()
	var sign_str = "+" if value > 0 else ""
	value_label.text = "%s%d" % [sign_str, value]
	value_label.add_theme_color_override("font_color", color)

	row.add_child(name_label)
	row.add_child(value_label)
	outcomes_container.add_child(row)


func _add_outcome_row_text(label_text: String, value_text: String, color: Color) -> void:
	var row = HBoxContainer.new()

	var name_label = Label.new()
	name_label.text = label_text + ":"
	name_label.custom_minimum_size.x = 150

	var value_label = Label.new()
	value_label.text = value_text
	value_label.add_theme_color_override("font_color", color)

	row.add_child(name_label)
	row.add_child(value_label)
	outcomes_container.add_child(row)


func _display_placeholder() -> void:
	title_label.text = "Outcome"
	narrative_label.text = "Something happened, but the details are unclear..."
	karma_narrative_label.visible = false

	# Clear outcomes
	for child in outcomes_container.get_children():
		child.queue_free()


func _on_continue_pressed() -> void:
	if triggers_combat:
		_start_combat()
	else:
		SceneManager.load_scene_by_name("map")


func _start_combat() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.start_prepared_duel()
	else:
		SceneManager.load_scene_by_name("duel")
