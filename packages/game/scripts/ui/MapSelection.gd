extends Control
class_name MapSelection

const DEBUG_ENABLED: bool = true

# UI References
@onready var title_label = $VBoxContainer/TitleLabel
@onready var maps_container = $VBoxContainer/ScrollContainer/MapsContainer
@onready var back_button = $VBoxContainer/BackButton

# Map button scene (we'll create a simple button for each map)
var map_buttons: Dictionary = {}

func _ready():
	GLog.debug("Map Selection scene ready")
	setup_ui()
	display_available_maps()
	connect_signals()

func setup_ui():
	# Set up title
	if title_label:
		title_label.text = "Choose Your Destination"
		title_label.add_theme_font_size_override("font_size", 32)
	
	# Style the back button if it exists
	if back_button:
		back_button.text = "Main Menu"
		back_button.visible = false  # Hide for now since we can't go back during a run

func connect_signals():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func display_available_maps():
	if not GameManager.game_data or not GameManager.game_data.has("maps"):
		GLog.error("No map data available in GameManager")
		return
	
	# Clear existing buttons
	for child in maps_container.get_children():
		child.queue_free()
	map_buttons.clear()
	
	# Get available and completed maps
	var available_maps = GameManager.game_data.get("available_maps", [])
	var completed_maps = GameManager.game_data.get("completed_maps", [])
	
	GLog.debug("Available maps: " + str(available_maps))
	GLog.debug("Completed maps: " + str(completed_maps))
	
	# Create buttons for available maps
	for region_id in available_maps:
		create_map_button(region_id, false)
	
	# Create buttons for completed maps (disabled)
	for region_id in completed_maps:
		create_map_button(region_id, true)

func create_map_button(region_id: String, is_completed: bool):
	var map_data = GameManager.game_data.maps.get(region_id, {})
	var config = map_data.get("config")
	
	# Create a container for the map entry
	var map_entry = VBoxContainer.new()
	map_entry.add_theme_constant_override("separation", 10)
	
	# Create the button
	var button = Button.new()
	button.name = "MapButton_" + region_id
	button.custom_minimum_size = Vector2(600, 80)
	button.disabled = is_completed
	
	# Get region info from config
	var region_name = "Unknown Region"
	var city_name = "Unknown City"
	var description = ""
	
	if config:
		region_name = config.region_name
		city_name = config.city_name
		description = config.region_description
	else:
		# Fallback names
		match region_id:
			"goldfields":
				region_name = "The Goldfields"
				city_name = "Ballarat"
			"outback":
				region_name = "The Outback"
				city_name = "Broken Hill"
			"mountains":
				region_name = "The Alpine Reaches"
				city_name = "Mount Hotham"
			"coast":
				region_name = "The Haunted Coast"
				city_name = "Port Fairy"
	
	# Set button text
	if is_completed:
		button.text = region_name + " (COMPLETED)"
		button.modulate = Color(0.5, 0.5, 0.5, 0.8)
	else:
		button.text = region_name + " - " + city_name
	
	# Style the button
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.3, 0.9) if not is_completed else Color(0.1, 0.1, 0.1, 0.5)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	
	if config:
		style_normal.border_color = config.theme_color if not is_completed else Color(0.3, 0.3, 0.3)
	else:
		style_normal.border_color = Color.GOLD if not is_completed else Color(0.3, 0.3, 0.3)
	
	button.add_theme_stylebox_override("normal", style_normal)
	
	# Hover style for available maps
	if not is_completed:
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(0.3, 0.3, 0.4, 1.0)
		style_hover.border_width_left = 3
		style_hover.border_width_right = 3
		style_hover.border_width_top = 3
		style_hover.border_width_bottom = 3
		button.add_theme_stylebox_override("hover", style_hover)
		
		# Connect button signal
		button.pressed.connect(_on_map_selected.bind(region_id))
	
	# Add description label
	var desc_label = Label.new()
	desc_label.text = description if description else "A mysterious region awaits exploration..."
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(580, 0)
	desc_label.modulate = Color(0.8, 0.8, 0.8, 0.8) if not is_completed else Color(0.4, 0.4, 0.4, 0.5)
	
	# Add map stats if available
	if map_data.has("generator_data"):
		var node_count = map_data.generator_data.get("nodes", {}).size()
		var stats_label = Label.new()
		stats_label.text = "Locations: " + str(node_count)
		stats_label.modulate = Color(0.6, 0.6, 0.7, 0.8)
		stats_label.add_theme_font_size_override("font_size", 12)
		map_entry.add_child(stats_label)
	
	# Add everything to the container
	map_entry.add_child(button)
	map_entry.add_child(desc_label)
	
	# Add separator
	var separator = HSeparator.new()
	separator.modulate = Color(0.3, 0.3, 0.3, 0.5)
	map_entry.add_child(separator)
	
	maps_container.add_child(map_entry)
	map_buttons[region_id] = button
	
	GLog.debug("Created map button for: " + region_id + " (completed: " + str(is_completed) + ")")

func _on_map_selected(region_id: String):
	GLog.info("Map selected: " + region_id)
	
	# Disable all buttons to prevent double-clicking
	for button in map_buttons.values():
		button.disabled = true
	
	# Tell GameManager which map was selected
	GameManager.select_map(region_id)

func _on_back_pressed():
	GLog.debug("Back to main menu")
	SceneManager.load_scene_by_name("main_menu")