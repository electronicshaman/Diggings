extends MapNodeScene
class_name MineNodeScene

# Mine-specific node scene
# Mines are dangerous but lucrative locations

@onready var danger_indicator: Control

func _ready():
	super._ready()
	setup_mine_visuals()

func setup_mine_visuals():
	"""Configure mine-specific visual elements"""
	
	# Mines have an orange/brown color for earth/danger
	if background_icon:
		background_icon.modulate = Color.ORANGE
	
	# Add danger indicator (optional visual enhancement)
	create_danger_indicator()

func create_danger_indicator():
	"""Add visual indicator for mine danger level"""
	danger_indicator = Control.new()
	danger_indicator.name = "DangerIndicator"
	danger_indicator.size = Vector2(12, 12)
	danger_indicator.position = Vector2(node_size.x - 12, 0)
	
	var danger_rect = ColorRect.new()
	danger_rect.size = Vector2(12, 12)
	danger_rect.color = Color.RED
	danger_indicator.add_child(danger_rect)
	
	add_child(danger_indicator)

func get_background_color() -> Color:
	"""Mines have an orange, earthy color with danger undertones"""
	var base_color = Color.ORANGE
	var alpha = node_data.get_state_alpha() if node_data else 1.0
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func update_visuals():
	"""Override to show danger level"""
	super.update_visuals()
	
	if not node_data:
		return
	
	# Update danger indicator based on mine's danger level
	if danger_indicator and node_data.properties.has("danger_level"):
		var danger_level = node_data.properties["danger_level"]
		var danger_rect = danger_indicator.get_child(0) as ColorRect
		
		if danger_rect:
			match danger_level:
				1:
					danger_rect.color = Color.YELLOW
				2:
					danger_rect.color = Color.ORANGE
				3:
					danger_rect.color = Color.RED
				_:
					danger_rect.color = Color.DARK_RED

func update_tooltip():
	"""Enhanced tooltip for mines with danger and resource information"""
	if not node_button or not node_data:
		return
	
	var tooltip_text = node_data.get_description()
	
	# Add mine-specific info
	var resource_type = node_data.properties.get("resource_type", "gold")
	var danger_level = node_data.properties.get("danger_level", 1)
	var exploration_time = node_data.properties.get("exploration_time", 6)
	
	tooltip_text += "\nâ¢ Mine for " + resource_type
	tooltip_text += "\nâ¢ Danger level: " + str(danger_level) + "/3"
	tooltip_text += "\nâ¢ Takes " + str(exploration_time) + " hours"
	tooltip_text += "\nâ¢ Risk vs reward location"
	
	node_button.tooltip_text = tooltip_text

func play_select_animation():
	"""Override to add mine-specific selection effects"""
	super.play_select_animation()
	
	# Add a shake effect for dangerous selections
	if danger_indicator:
		var tween = create_tween()
		tween.tween_method(_shake_danger_indicator, 0.0, 1.0, 0.2)

func _shake_danger_indicator(progress: float):
	"""Shake the danger indicator"""
	if danger_indicator:
		var shake_amount = sin(progress * PI * 6) * 3
		danger_indicator.position.x = node_size.x - 12 + shake_amount