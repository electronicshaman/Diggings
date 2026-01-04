extends Control
class_name DeckManagementController

const DEBUG_ENABLED: bool = true

# Mode enumeration
enum DeckMode {
	RUN,        # During run - modify current deck from acquired cards
	SANDBOX,    # Main menu - full card pool access, save custom decks
	PREVIEW     # Class selection - view-only starting deck
}

# Scene references
var card_scene: PackedScene = preload("res://scenes/cards/card_ui.tscn")

# State
var current_mode: DeckMode = DeckMode.RUN
var current_deck: Array[CardData] = []
var available_cards: Array[CardData] = []
var selected_cards: Array[Node] = []  # Selected card nodes for removal
var active_filter: String = "All"
var active_sort: String = "Name"
var search_query: String = ""
var return_scene: String = "main_menu"
var character_class: String = ""

# Sandbox state
var sandbox_deck: Array[CardData] = []

# Node references - Header
@onready var title_label: Label = $MainContainer/ContentVBox/HeaderSection/TitleLabel
@onready var mode_indicator: Label = $MainContainer/ContentVBox/HeaderSection/ModeIndicator
@onready var close_button: Button = $MainContainer/ContentVBox/HeaderSection/CloseButton

# Node references - Stats Panel
@onready var deck_size_label: Label = $MainContainer/ContentVBox/StatsAndFiltersPanel/StatsPanel/StatsVBox/DeckSizeLabel
@onready var type_dist_container: VBoxContainer = $MainContainer/ContentVBox/StatsAndFiltersPanel/StatsPanel/StatsVBox/TypeDistributionContainer
@onready var energy_curve_container: VBoxContainer = $MainContainer/ContentVBox/StatsAndFiltersPanel/StatsPanel/StatsVBox/EnergyCurveContainer
@onready var validation_warnings: VBoxContainer = $MainContainer/ContentVBox/StatsAndFiltersPanel/StatsPanel/StatsVBox/ValidationWarnings

# Node references - Filters Panel
@onready var filter_all_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/FilterButtonsHBox/FilterAllButton
@onready var filter_attack_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/FilterButtonsHBox/FilterAttackButton
@onready var filter_skill_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/FilterButtonsHBox/FilterSkillButton
@onready var filter_power_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/FilterButtonsHBox/FilterPowerButton
@onready var filter_fortune_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/FilterButtonsHBox/FilterFortuneButton

# Node references - Sort Panel
@onready var sort_name_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/SortOptionsHBox/SortNameButton
@onready var sort_cost_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/SortOptionsHBox/SortCostButton
@onready var sort_type_button: Button = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/SortOptionsHBox/SortTypeButton
@onready var search_box: LineEdit = $MainContainer/ContentVBox/StatsAndFiltersPanel/FiltersPanel/SearchBox

# Node references - Card Grid
@onready var card_grid: GridContainer = $MainContainer/ContentVBox/CardGridScrollContainer/CardGrid

# Node references - Action Buttons
@onready var add_card_button: Button = $MainContainer/ContentVBox/BottomActionsPanel/LeftActions/AddCardButton
@onready var remove_selected_button: Button = $MainContainer/ContentVBox/BottomActionsPanel/LeftActions/RemoveSelectedButton
@onready var reset_button: Button = $MainContainer/ContentVBox/BottomActionsPanel/RightActions/ResetButton
@onready var back_button: Button = $MainContainer/ContentVBox/BottomActionsPanel/RightActions/BackButton

# Node references - Add Card Modal
@onready var add_card_modal: Control = $AddCardModal
@onready var add_card_search: LineEdit = $AddCardModal/ModalOverlay/ModalPanel/AddCardContent/AddCardSearch
@onready var available_cards_grid: GridContainer = $AddCardModal/ModalOverlay/ModalPanel/AddCardContent/AvailableCardsScroll/AvailableCardsGrid
@onready var cancel_add_button: Button = $AddCardModal/ModalOverlay/ModalPanel/AddCardContent/AddCardButtons/CancelAddButton

func _ready() -> void:
	_connect_signals()
	_setup_filter_button_text()
	_detect_mode_from_context()
	_setup_ui_for_mode()
	_load_deck_for_mode()
	_load_available_cards()
	_setup_progress_bar_colors()
	_refresh_display()

	GLog.debug("Deck Management loaded in %s mode" % DeckMode.keys()[current_mode])

func _connect_signals() -> void:
	"""Connect all button signals"""
	# Header
	close_button.pressed.connect(_on_back_pressed)

	# Filters
	filter_all_button.pressed.connect(_on_filter_changed.bind("All"))
	filter_attack_button.pressed.connect(_on_filter_changed.bind("Attack"))
	filter_skill_button.pressed.connect(_on_filter_changed.bind("Skill"))
	filter_power_button.pressed.connect(_on_filter_changed.bind("Power"))
	filter_fortune_button.pressed.connect(_on_filter_changed.bind("Fortune"))

	# Sort
	sort_name_button.pressed.connect(_on_sort_changed.bind("Name"))
	sort_cost_button.pressed.connect(_on_sort_changed.bind("Cost"))
	sort_type_button.pressed.connect(_on_sort_changed.bind("Type"))

	# Search
	search_box.text_changed.connect(_on_search_text_changed)

	# Actions
	add_card_button.pressed.connect(_on_add_card_button_pressed)
	remove_selected_button.pressed.connect(_on_remove_selected_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Modal
	cancel_add_button.pressed.connect(_on_cancel_add_pressed)
	add_card_search.text_changed.connect(_on_modal_search_changed)

func _setup_filter_button_text() -> void:
	"""Set filter button text to use direct card type names"""
	filter_all_button.text = "All"
	filter_attack_button.text = "Attack"
	filter_skill_button.text = "Skill"
	filter_power_button.text = "Power"
	filter_fortune_button.text = "Fortune"

func _detect_mode_from_context() -> void:
	"""Detect mode based on GameManager.game_data flags"""
	if GameManager.game_data.has("deck_management_mode"):
		var mode_string = GameManager.game_data.deck_management_mode
		match mode_string:
			"run":
				current_mode = DeckMode.RUN
				return_scene = GameManager.game_data.get("return_scene", "city_hub")
			"sandbox":
				current_mode = DeckMode.SANDBOX
				return_scene = "main_menu"
				character_class = GameManager.game_data.get("sandbox_class", "")
			"preview":
				current_mode = DeckMode.PREVIEW
				return_scene = GameManager.game_data.get("return_scene", "class_selection")
				character_class = GameManager.game_data.get("preview_class", "")

		# Clear the flag
		GameManager.game_data.erase("deck_management_mode")
	else:
		# Default fallback
		current_mode = DeckMode.SANDBOX
		return_scene = "main_menu"

	GLog.debug("Detected mode: %s, return scene: %s" % [DeckMode.keys()[current_mode], return_scene])

func _setup_ui_for_mode() -> void:
	"""Configure UI elements based on current mode"""
	match current_mode:
		DeckMode.RUN:
			title_label.text = "Deck Management"
			mode_indicator.text = "In Run"
			add_card_button.visible = true
			remove_selected_button.visible = true
			reset_button.visible = false
		DeckMode.SANDBOX:
			title_label.text = "Deck Builder"
			mode_indicator.text = "Sandbox Mode"
			add_card_button.visible = true
			remove_selected_button.visible = true
			reset_button.visible = true
		DeckMode.PREVIEW:
			title_label.text = "Starting Deck Preview"
			mode_indicator.text = "Preview Only"
			add_card_button.visible = false
			remove_selected_button.visible = false
			reset_button.visible = false

func _load_deck_for_mode() -> void:
	"""Load the appropriate deck based on mode"""
	current_deck.clear()

	match current_mode:
		DeckMode.RUN:
			# Load from DeckManager
			if DeckManager and DeckManager.has_method("get_current_deck"):
				current_deck = DeckManager.get_current_deck()
				GLog.debug("Loaded %d cards from DeckManager" % current_deck.size())
			else:
				GLog.error("DeckManager not available in run mode")

		DeckMode.SANDBOX:
			# Load saved sandbox deck or create default
			sandbox_deck = _load_sandbox_deck()
			current_deck = sandbox_deck.duplicate()
			GLog.debug("Loaded %d cards for sandbox mode" % current_deck.size())

		DeckMode.PREVIEW:
			# Load character starting deck
			current_deck = _load_preview_deck()
			GLog.debug("Loaded %d cards for preview mode" % current_deck.size())

func _load_available_cards() -> void:
	"""Load card pool based on mode"""
	available_cards.clear()

	match current_mode:
		DeckMode.RUN:
			# Only cards acquired during run
			if GameManager.game_data.has("acquired_cards"):
				for card_path in GameManager.game_data.acquired_cards:
					var card = load(card_path) as CardData
					if card:
						available_cards.append(card)
			GLog.debug("Loaded %d acquired cards for run mode" % available_cards.size())

		DeckMode.SANDBOX:
			# All cards in the game
			available_cards = _load_all_cards()
			# Filter by class if specified
			if not character_class.is_empty():
				available_cards = _filter_by_class(available_cards, character_class)
			GLog.debug("Loaded %d cards for sandbox mode" % available_cards.size())

		DeckMode.PREVIEW:
			# No available cards in preview mode
			available_cards = []

func _load_all_cards() -> Array[CardData]:
	"""Load all card resources from data/cards/"""
	var cards: Array[CardData] = []
	var categories = ["attack", "skill", "power", "fortune"]

	for category in categories:
		var dir_path = "res://data/cards/" + category
		var dir = DirAccess.open(dir_path)

		if not dir:
			GLog.warn("Failed to open directory: %s" % dir_path)
			continue

		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path = dir_path + "/" + file_name
				var card = load(full_path) as CardData
				if card:
					cards.append(card)
				else:
					GLog.warn("Failed to load card: %s" % full_path)
			file_name = dir.get_next()

		dir.list_dir_end()

	GLog.info("Loaded %d total cards from all categories" % cards.size())
	return cards

func _filter_by_class(cards: Array[CardData], char_class: String) -> Array[CardData]:
	"""Filter cards available to character class"""
	var filtered: Array[CardData] = []

	for card in cards:
		# Include if no class restrictions or if class matches
		if card.class_affinity.is_empty() or char_class in card.class_affinity:
			filtered.append(card)

	return filtered

func _load_sandbox_deck() -> Array[CardData]:
	"""Load saved sandbox deck or create default"""
	var deck_name = "default_sandbox"
	if not character_class.is_empty():
		deck_name = character_class.to_lower() + "_sandbox"

	var save_dir = "user://sandbox_decks/"
	var save_path = save_dir + deck_name + ".json"

	# Create directory if needed
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_absolute(save_dir)

	# Check if saved deck exists
	if not FileAccess.file_exists(save_path):
		GLog.info("No saved sandbox deck found, creating default")
		return _create_default_sandbox_deck()

	# Load JSON deck
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		GLog.error("Failed to open sandbox deck file: %s" % save_path)
		return _create_default_sandbox_deck()

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		GLog.error("Failed to parse sandbox deck JSON: %s" % json.get_error_message())
		return _create_default_sandbox_deck()

	var card_paths = json.data
	if not card_paths is Array:
		GLog.error("Invalid deck format: expected array of card paths")
		return _create_default_sandbox_deck()

	# Load cards from paths
	var loaded_deck: Array[CardData] = []
	for path in card_paths:
		var card = load(path) as CardData
		if card:
			loaded_deck.append(card)
		else:
			GLog.warn("Failed to load card from path: %s" % path)

	GLog.info("Loaded sandbox deck with %d cards from %s" % [loaded_deck.size(), deck_name])
	return loaded_deck

func _create_default_sandbox_deck() -> Array[CardData]:
	"""Create a basic starting deck for sandbox"""
	var deck: Array[CardData] = []

	if not character_class.is_empty():
		# Try to load class starting deck
		var char_path = "res://data/characters/" + character_class.to_lower() + ".tres"
		if ResourceLoader.exists(char_path):
			var char_resource = load(char_path)
			if char_resource and char_resource.has_method("load_starting_deck"):
				return char_resource.load_starting_deck()

	# Generic starter - just load a few common cards
	var starter_paths = [
		"res://data/cards/attack/quick_shot.tres",
		"res://data/cards/skill/take_cover.tres"
	]

	for path in starter_paths:
		if ResourceLoader.exists(path):
			var card = load(path) as CardData
			if card:
				for i in range(5):  # Add 5 of each
					deck.append(card)

	return deck

func _load_preview_deck() -> Array[CardData]:
	"""Load character starting deck for preview"""
	if character_class.is_empty():
		return []

	var char_path = "res://data/characters/" + character_class.to_lower() + ".tres"
	if not ResourceLoader.exists(char_path):
		GLog.error("Character resource not found: %s" % char_path)
		return []

	var char_resource = load(char_path)
	if char_resource and char_resource.has_method("load_starting_deck"):
		return char_resource.load_starting_deck()

	return []

func _setup_progress_bar_colors() -> void:
	"""Setup colors for type distribution and energy curve bars"""
	var type_colors = {
		"Attack": Color(0.95, 0.3, 0.2),    # Red/crimson
		"Skill": Color(0.2, 0.7, 0.3),      # Green
		"Power": Color(0.6, 0.3, 0.8),      # Purple
		"Fortune": Color(0.95, 0.8, 0.2)    # Gold/yellow
	}

	for type_name in type_colors:
		var bar_path = "TypeDistributionContainer/" + type_name + "Bar"
		var bar = type_dist_container.get_node_or_null(bar_path) as ProgressBar
		if bar:
			var style = StyleBoxFlat.new()
			style.bg_color = type_colors[type_name]
			bar.add_theme_stylebox_override("fill", style)

	var cost_colors = [
		Color(0.3, 0.9, 0.3),   # 0 cost - green
		Color(0.6, 0.8, 1.0),   # 1 cost - light blue
		Color(0.3, 0.5, 0.9),   # 2 cost - blue
		Color(0.8, 0.3, 0.3)    # 3+ cost - red
	]

	for i in range(4):
		var bar_path = "Cost%dBar" % i
		var bar = energy_curve_container.get_node_or_null(bar_path) as ProgressBar
		if bar:
			var style = StyleBoxFlat.new()
			style.bg_color = cost_colors[i]
			bar.add_theme_stylebox_override("fill", style)

func _refresh_display() -> void:
	"""Update all UI elements"""
	_update_statistics()
	_render_card_grid()
	_update_validation_warnings()

func _update_statistics() -> void:
	"""Update deck statistics panel"""
	var deck_size = current_deck.size()
	deck_size_label.text = "Deck: %d cards" % deck_size

	_update_type_distribution()
	_update_energy_curve()

func _update_type_distribution() -> void:
	"""Update type distribution progress bars"""
	var composition = _get_deck_composition()
	var total = current_deck.size()

	var types = ["Attack", "Skill", "Power", "Fortune"]
	for type_name in types:
		var count = composition.get(type_name, 0)
		var percentage = (float(count) / total * 100.0) if total > 0 else 0.0

		var bar_path = "TypeDistributionContainer/" + type_name + "Bar"
		var bar = type_dist_container.get_node_or_null(bar_path) as ProgressBar
		if bar:
			bar.value = percentage
			var label = bar.get_node_or_null(type_name + "Label") as Label
			if label:
				label.text = "%s: %d (%.0f%%)" % [type_name, count, percentage]

func _update_energy_curve() -> void:
	"""Update energy cost distribution bars"""
	var curve = _get_energy_curve()
	var total = current_deck.size()

	for cost in range(4):
		var count = curve.get(cost, 0)
		if cost == 3:  # 3+ category includes all costs >= 3
			for i in range(3, 10):
				if i != cost:
					count += curve.get(i, 0)

		var percentage = (float(count) / total * 100.0) if total > 0 else 0.0
		var label_text = "%d cost" % cost if cost < 3 else "3+ cost"

		var bar_path = "Cost%dBar" % cost
		var bar = energy_curve_container.get_node_or_null(bar_path) as ProgressBar
		if bar:
			bar.value = percentage
			var label = bar.get_node_or_null("Cost%dLabel" % cost) as Label
			if label:
				label.text = "%s: %d (%.0f%%)" % [label_text, count, percentage]

func _render_card_grid() -> void:
	"""Render filtered and sorted cards in grid"""
	# Clear existing cards
	for child in card_grid.get_children():
		child.queue_free()

	selected_cards.clear()

	# Get filtered and sorted deck
	var display_cards = _get_filtered_sorted_deck()
	GLog.debug("Rendering %d cards in deck grid" % display_cards.size())

	# Create card instances
	for card_data in display_cards:
		# Create CardUI instance
		var card_instance = card_scene.instantiate() as CardUI
		card_instance.set_card_data(card_data)

		# Scale to 0.7 for deck view (210x294)
		card_instance.scale = Vector2(0.7, 0.7)

		# Add to grid
		card_grid.add_child(card_instance)

		# Connect click signal (non-preview mode)
		if current_mode != DeckMode.PREVIEW:
			card_instance.card_clicked.connect(_on_card_clicked)

		GLog.debug("Added card to grid: %s" % card_data.card_name)

	GLog.debug("Card grid rendered successfully")

func _get_filtered_sorted_deck() -> Array[CardData]:
	"""Apply filters and sorting to deck"""
	var filtered: Array[CardData] = []

	for card in current_deck:
		# Apply type filter
		if active_filter != "All":
			var card_type = card.card_type if "card_type" in card else ""
			if card_type != active_filter:
				continue

		# Apply search filter
		if not search_query.is_empty():
			if not card.card_name.to_lower().contains(search_query.to_lower()):
				continue

		filtered.append(card)

	# Apply sorting
	match active_sort:
		"Name":
			filtered.sort_custom(func(a, b): return a.card_name < b.card_name)
		"Cost":
			filtered.sort_custom(func(a, b): return a.energy_cost < b.energy_cost)
		"Type":
			filtered.sort_custom(func(a, b):
				var type_a = a.card_type if "card_type" in a else ""
				var type_b = b.card_type if "card_type" in b else ""
				return type_a < type_b
			)

	return filtered

func _get_deck_composition() -> Dictionary:
	"""Get card type composition"""
	var composition = {}
	for card in current_deck:
		var type_name = card.card_type if "card_type" in card else "Unknown"
		# Use card type directly
		composition[type_name] = composition.get(type_name, 0) + 1
	return composition

func _get_energy_curve() -> Dictionary:
	"""Get energy cost distribution"""
	var curve = {}
	for card in current_deck:
		var cost = card.energy_cost
		curve[cost] = curve.get(cost, 0) + 1
	return curve

func _update_validation_warnings() -> void:
	"""Check deck validity and show warnings"""
	# Clear existing warnings
	for child in validation_warnings.get_children():
		child.queue_free()

	var issues: Array[String] = []

	# Validate based on mode
	match current_mode:
		DeckMode.RUN:
			if DeckManager and DeckManager.has_method("validate_current_deck"):
				issues = DeckManager.validate_current_deck()
		DeckMode.SANDBOX:
			issues = _validate_sandbox_deck()
		DeckMode.PREVIEW:
			# Just display info, no validation
			pass

	if issues.is_empty() and current_mode != DeckMode.PREVIEW:
		var ok_label = Label.new()
		ok_label.text = "✓ Deck is valid"
		ok_label.add_theme_color_override("font_color", Color.GREEN)
		validation_warnings.add_child(ok_label)
	else:
		for issue in issues:
			var warning_label = Label.new()
			warning_label.text = "⚠ " + issue
			warning_label.add_theme_color_override("font_color", Color.ORANGE)
			warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			validation_warnings.add_child(warning_label)

func _validate_sandbox_deck() -> Array[String]:
	"""Custom validation for sandbox decks"""
	var issues: Array[String] = []
	var deck_size = sandbox_deck.size()

	if deck_size < 10:
		issues.append("Deck must have at least 10 cards (current: %d)" % deck_size)
	elif deck_size > 50:
		issues.append("Deck cannot exceed 50 cards (current: %d)" % deck_size)

	return issues

# Signal handlers - Filters
func _on_filter_changed(filter_type: String) -> void:
	active_filter = filter_type
	_highlight_active_filter_button()
	_refresh_display()
	GLog.debug("Filter changed to: %s" % filter_type)

func _highlight_active_filter_button() -> void:
	"""Update button states to show active filter"""
	var buttons = {
		"All": filter_all_button,
		"Attack": filter_attack_button,
		"Skill": filter_skill_button,
		"Power": filter_power_button,
		"Fortune": filter_fortune_button
	}

	for filter_name in buttons:
		var button = buttons[filter_name]
		button.button_pressed = (filter_name == active_filter)

# Signal handlers - Sort
func _on_sort_changed(sort_type: String) -> void:
	active_sort = sort_type
	_highlight_active_sort_button()
	_refresh_display()
	GLog.debug("Sort changed to: %s" % sort_type)

func _highlight_active_sort_button() -> void:
	"""Update button states to show active sort"""
	sort_name_button.button_pressed = (active_sort == "Name")
	sort_cost_button.button_pressed = (active_sort == "Cost")
	sort_type_button.button_pressed = (active_sort == "Type")

# Signal handlers - Search
func _on_search_text_changed(new_text: String) -> void:
	search_query = new_text
	_refresh_display()

# Signal handlers - Card interaction
func _on_card_clicked(card_ui: CardUI) -> void:
	"""Toggle card selection"""
	# Toggle selection state
	if card_ui in selected_cards:
		selected_cards.erase(card_ui)
		card_ui.set_selected(false)
		GLog.debug("Deselected card: %s" % card_ui.card_data.card_name)
	else:
		selected_cards.append(card_ui)
		card_ui.set_selected(true)
		GLog.debug("Selected card: %s" % card_ui.card_data.card_name)

	# Update remove button state
	if selected_cards.size() > 0:
		remove_selected_button.disabled = false
		remove_selected_button.text = "Remove Selected (%d)" % selected_cards.size()
	else:
		remove_selected_button.disabled = true
		remove_selected_button.text = "Remove Selected"

# Signal handlers - Actions
func _on_add_card_button_pressed() -> void:
	"""Open modal to select card to add"""
	if current_mode == DeckMode.PREVIEW:
		return

	add_card_modal.visible = true
	_populate_add_card_modal()
	GLog.debug("Opening add card modal with %d available cards" % available_cards.size())

func _populate_add_card_modal() -> void:
	"""Fill modal with available cards"""
	# Clear existing
	for child in available_cards_grid.get_children():
		child.queue_free()

	# Filter cards by modal search
	var modal_search = add_card_search.text.to_lower()
	var filtered_available = available_cards.duplicate()

	if not modal_search.is_empty():
		filtered_available = filtered_available.filter(
			func(card): return card.card_name.to_lower().contains(modal_search)
		)

	GLog.debug("Populating modal with %d available cards" % filtered_available.size())

	# Create card instances
	for card_data in filtered_available:
		var card_instance = card_scene.instantiate() as CardUI
		card_instance.set_card_data(card_data)

		# Scale to 0.6 for modal (180x252)
		card_instance.scale = Vector2(0.6, 0.6)

		# Add to grid
		available_cards_grid.add_child(card_instance)

		# Connect for adding to deck (bind card_data for handler)
		card_instance.card_clicked.connect(_on_add_card_selected.bind(card_data))

func _on_add_card_selected(_card_ui: CardUI, card_data: CardData) -> void:
	"""Add selected card to deck"""
	match current_mode:
		DeckMode.RUN:
			if DeckManager and DeckManager.has_method("add_card"):
				if DeckManager.add_card(card_data):
					current_deck = DeckManager.get_current_deck()
					available_cards.erase(card_data)
					EventBus.emit_ui_notification("Added %s to deck" % card_data.card_name, "success")
				else:
					EventBus.emit_ui_notification("Failed to add card", "error")
		DeckMode.SANDBOX:
			sandbox_deck.append(card_data)
			current_deck = sandbox_deck.duplicate()
			EventBus.emit_ui_notification("Added %s to deck" % card_data.card_name, "success")

	add_card_modal.visible = false
	_refresh_display()
	GLog.info("Added card to deck: %s" % card_data.card_name)

func _on_remove_selected_button_pressed() -> void:
	"""Remove selected cards from deck"""
	if selected_cards.is_empty():
		EventBus.emit_ui_notification("No cards selected", "warning")
		return

	var removed_count = 0

	for card_node in selected_cards:
		var card_data = card_node.card_data

		match current_mode:
			DeckMode.RUN:
				if DeckManager and DeckManager.has_method("remove_card"):
					if DeckManager.remove_card(card_data):
						available_cards.append(card_data)
						removed_count += 1
			DeckMode.SANDBOX:
				if card_data in sandbox_deck:
					sandbox_deck.erase(card_data)
					removed_count += 1

	selected_cards.clear()

	# Refresh deck reference
	if current_mode == DeckMode.RUN:
		current_deck = DeckManager.get_current_deck() if DeckManager else []
	else:
		current_deck = sandbox_deck.duplicate()

	_refresh_display()
	EventBus.emit_ui_notification("Removed %d card(s)" % removed_count, "success")
	GLog.info("Removed %d cards from deck" % removed_count)

func _on_reset_button_pressed() -> void:
	"""Reset sandbox deck to default"""
	sandbox_deck = _create_default_sandbox_deck()
	current_deck = sandbox_deck.duplicate()
	_refresh_display()
	EventBus.emit_ui_notification("Deck reset to default", "info")
	GLog.info("Reset sandbox deck to default")

func _on_back_pressed() -> void:
	"""Return to previous scene"""
	# Save sandbox deck if in sandbox mode
	if current_mode == DeckMode.SANDBOX:
		_save_sandbox_deck()

	SceneManager.load_scene_by_name(return_scene)
	GLog.debug("Returning to: %s" % return_scene)

func _on_cancel_add_pressed() -> void:
	"""Close add card modal"""
	add_card_modal.visible = false

func _on_modal_search_changed(_new_text: String) -> void:
	"""Update modal card list when search changes"""
	_populate_add_card_modal()

func _save_sandbox_deck() -> void:
	"""Save current sandbox deck to file"""
	var save_dir = "user://sandbox_decks/"
	DirAccess.make_dir_recursive_absolute(save_dir)

	var deck_name = "default_sandbox"
	if not character_class.is_empty():
		deck_name = character_class.to_lower() + "_sandbox"

	var save_path = save_dir + deck_name + ".json"

	# Save as JSON with card paths
	var save_data = {
		"deck_name": deck_name,
		"card_paths": []
	}

	for card in sandbox_deck:
		save_data.card_paths.append(card.resource_path)

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		GLog.info("Sandbox deck saved to: %s" % save_path)
		EventBus.emit_ui_notification("Deck saved!", "success")
	else:
		GLog.error("Failed to save sandbox deck")
		EventBus.emit_ui_notification("Failed to save deck", "error")
