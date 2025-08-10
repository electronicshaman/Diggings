extends MapNodeScene
class_name CampNodeScene

# Camp-specific node scene
# Camps are rest stops with healing and safety

func _ready():
	super._ready()
	setup_camp_visuals()

func setup_camp_visuals():
	"""Configure camp-specific visual elements"""
	
	# Camps have a green tint for safety/nature
	if background_icon:
		background_icon.modulate = Color.FOREST_GREEN

func get_background_color() -> Color:
	"""Camps have a green, natural color"""
	var base_color = Color.FOREST_GREEN
	var alpha = node_data.get_state_alpha() if node_data else 1.0
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func update_tooltip():
	"""Enhanced tooltip for camps with rest information"""
	if not node_button or not node_data:
		return
	
	var tooltip_text = node_data.get_description()
	
	# Add camp-specific info
	var heal_amount = node_data.properties.get("heal_amount", 15)
	var rest_time = node_data.properties.get("rest_time", 4)
	
	tooltip_text += "\nâ¢ Rest and heal " + str(heal_amount) + " HP"
	tooltip_text += "\nâ¢ Takes " + str(rest_time) + " hours"
	tooltip_text += "\nâ¢ Safe location"
	
	node_button.tooltip_text = tooltip_text