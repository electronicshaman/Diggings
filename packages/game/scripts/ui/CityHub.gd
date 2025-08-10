extends Control
class_name CityHub

const DEBUG_ENABLED: bool = true

# UI References
@onready var city_name_label = $VBoxContainer/CityNameLabel
@onready var description_label = $VBoxContainer/DescriptionLabel
@onready var buttons_container = $VBoxContainer/ButtonsContainer
@onready var return_button = $VBoxContainer/ReturnButton

# City services buttons
var shop_button: Button
var rest_button: Button
var deck_button: Button
var leave_button: Button

func _ready():
	GLog.debug("City Hub scene ready")
	setup_city_info()
	create_service_buttons()
	connect_signals()
	
	# Full heal on entering city
	if GameManager.game_data and GameManager.game_data.has("player"):
		GLog.info("City provides full healing")
		# TODO: Heal player to full when player data is available

func setup_city_info():
	# Get current city info from the map
	var current_region = GameManager.game_data.get("current_map", "")
	var city_name = "City"
	var description = "A safe haven in a dangerous world."
	
	if not current_region.is_empty() and GameManager.game_data.maps.has(current_region):
		var map_data = GameManager.game_data.maps[current_region]
		if map_data.has("config"):
			var config = map_data.config
			city_name = config.city_name
			description = config.city_description
	
	if city_name_label:
		city_name_label.text = "Welcome to " + city_name
		city_name_label.add_theme_font_size_override("font_size", 28)
	
	if description_label:
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func create_service_buttons():
	if not buttons_container:
		return
	
	# Shop button
	shop_button = create_button("Visit Shop", "Browse weapons, items, and upgrades")
	shop_button.pressed.connect(_on_shop_pressed)
	buttons_container.add_child(shop_button)
	
	# Rest button
	rest_button = create_button("Rest at Inn", "Rest and manage your deck")
	rest_button.pressed.connect(_on_rest_pressed)
	buttons_container.add_child(rest_button)
	
	# Deck management button
	deck_button = create_button("Manage Deck", "View and organize your cards")
	deck_button.pressed.connect(_on_deck_pressed)
	buttons_container.add_child(deck_button)
	
	# Leave city button
	leave_button = create_button("Return to Map", "Continue your journey")
	leave_button.pressed.connect(_on_leave_pressed)
	buttons_container.add_child(leave_button)

func create_button(text: String, tooltip: String) -> Button:
	var button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(300, 50)
	
	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	
	button.add_theme_stylebox_override("normal", style)
	
	var style_hover = style.duplicate()
	style_hover.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	button.add_theme_stylebox_override("hover", style_hover)
	
	return button

func connect_signals():
	if return_button:
		return_button.text = "Leave City"
		return_button.pressed.connect(_on_leave_pressed)

func _on_shop_pressed():
	GLog.info("Opening shop")
	SceneManager.load_scene_by_name("shop")

func _on_rest_pressed():
	GLog.info("Resting at inn")
	SceneManager.load_scene_by_name("camp")

func _on_deck_pressed():
	GLog.info("Opening deck viewer")
	SceneManager.load_scene_by_name("deck_viewer")

func _on_leave_pressed():
	GLog.info("Returning to map")
	SceneManager.load_scene_by_name("map")