extends MapNodeScene
class_name CityNodeScene

# City-specific enhancements to the base MapNodeScene
# Cities are major hubs with special visual treatment and multiple services

func _ready():
	super._ready()
	
	# Override default settings for city nodes
	node_size = Vector2(80, 80)  # Larger than normal nodes
	
	# City-specific setup
	setup_city_visuals()

func setup_city_visuals():
	"""Configure city-specific visual elements"""
	
	# Cities get a special golden background
	if background_icon:
		background_icon.modulate = Color.GOLD
		
	# Larger label for city names
	if node_label:
		var label_style = StyleBoxFlat.new()
		label_style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
		label_style.corner_radius_top_left = 4
		label_style.corner_radius_top_right = 4
		label_style.corner_radius_bottom_left = 4
		label_style.corner_radius_bottom_right = 4
		node_label.add_theme_stylebox_override("normal", label_style)

func update_visuals():
	"""Override to provide city-specific visual updates"""
	super.update_visuals()
	
	if not node_data:
		return
	
	# City name from properties
	if node_label and node_data.properties.has("city_name"):
		node_label.text = node_data.properties["city_name"]
	
	# Cities always have a golden glow when active
	if node_data.get_state() == MapNode.NodeState.CURRENT:
		if outline:
			outline.color = Color(Color.GOLD.r, Color.GOLD.g, Color.GOLD.b, 1.0)

func get_background_color() -> Color:
	"""Cities always have a golden tint"""
	var base_color = Color.GOLD
	var alpha = node_data.get_state_alpha() if node_data else 1.0
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func update_tooltip():
	"""Enhanced tooltip for cities with service information"""
	if not node_button or not node_data:
		return
	
	var tooltip_text = node_data.get_description()
	
	# Add city services info
	if node_data.properties.get("has_shop", false):
		tooltip_text += "\nâ¢ Shop available"
	if node_data.properties.get("has_deck_management", false):
		tooltip_text += "\nâ¢ Deck management available"
	if node_data.properties.get("heal_to_full", false):
		tooltip_text += "\nâ¢ Full healing available"
	
	# City is always safe
	tooltip_text += "\nâ¢ Safe haven - always revisitable"
	
	node_button.tooltip_text = tooltip_text