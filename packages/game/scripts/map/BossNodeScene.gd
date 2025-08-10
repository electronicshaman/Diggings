extends MapNodeScene
class_name BossNodeScene

# Boss-specific node scene
# Boss nodes are major encounter locations with special visual treatment

@onready var menace_aura: Control
var pulse_tween: Tween

func _ready():
	super._ready()
	
	# Boss nodes are larger and more imposing
	node_size = Vector2(90, 90)
	
	setup_boss_visuals()

func setup_boss_visuals():
	"""Configure boss-specific visual elements"""
	
	# Bosses have a menacing red color
	if background_icon:
		background_icon.modulate = Color.DARK_RED
	
	# Create menacing aura effect
	create_menace_aura()
	
	# Start the pulsing effect
	start_pulse_animation()

func create_menace_aura():
	"""Create a visual aura around the boss node"""
	menace_aura = Control.new()
	menace_aura.name = "MenaceAura"
	menace_aura.size = node_size + Vector2(20, 20)
	menace_aura.position = Vector2(-10, -10)
	
	var aura_rect = ColorRect.new()
	aura_rect.size = menace_aura.size
	aura_rect.color = Color(Color.RED.r, Color.RED.g, Color.RED.b, 0.2)
	
	# Make it circular (or at least rounded)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(Color.RED.r, Color.RED.g, Color.RED.b, 0.2)
	style_box.corner_radius_top_left = menace_aura.size.x / 2
	style_box.corner_radius_top_right = menace_aura.size.x / 2
	style_box.corner_radius_bottom_left = menace_aura.size.x / 2
	style_box.corner_radius_bottom_right = menace_aura.size.x / 2
	
	var panel = Panel.new()
	panel.size = menace_aura.size
	panel.add_theme_stylebox_override("panel", style_box)
	
	menace_aura.add_child(panel)
	add_child(menace_aura)
	
	# Put aura behind everything else
	move_child(menace_aura, 0)

func start_pulse_animation():
	"""Start the menacing pulse animation"""
	if menace_aura and not pulse_tween:
		pulse_tween = create_tween()
		pulse_tween.set_loops()
		
		# Pulse the aura opacity
		pulse_tween.tween_method(_pulse_aura, 0.1, 0.4, 1.5)
		pulse_tween.tween_method(_pulse_aura, 0.4, 0.1, 1.5)

func _pulse_aura(alpha: float):
	"""Update the aura's alpha value"""
	if menace_aura:
		menace_aura.modulate = Color(1.0, 1.0, 1.0, alpha)

func get_background_color() -> Color:
	"""Bosses have a dark red, menacing color"""
	var base_color = Color.DARK_RED
	var alpha = node_data.get_state_alpha() if node_data else 1.0
	return Color(base_color.r, base_color.g, base_color.b, alpha)

func update_visuals():
	"""Override to provide boss-specific visual updates"""
	super.update_visuals()
	
	if not node_data:
		return
	
	# Boss name from properties
	if node_label and node_data.properties.has("boss_name"):
		node_label.text = node_data.properties["boss_name"]
		# Make boss names more prominent
		node_label.modulate = Color.RED

func update_tooltip():
	"""Enhanced tooltip for bosses with difficulty and reward information"""
	if not node_button or not node_data:
		return
	
	var tooltip_text = node_data.get_description()
	
	# Add boss-specific info
	var boss_name = node_data.properties.get("boss_name", "Boss")
	var difficulty = node_data.properties.get("difficulty", 3)
	var rewards_legendary = node_data.properties.get("rewards_legendary", false)
	
	tooltip_text += "\nâ¢ Boss: " + boss_name
	tooltip_text += "\nâ¢ Difficulty: " + str(difficulty) + "/5"
	if rewards_legendary:
		tooltip_text += "\nâ¢ Legendary rewards available"
	tooltip_text += "\nâ¢ Completing defeats this region"
	
	node_button.tooltip_text = tooltip_text

func play_select_animation():
	"""Override to add dramatic boss selection effects"""
	super.play_select_animation()
	
	# Dramatic flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(self, "modulate", Color.RED, 0.2)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _on_mouse_entered():
	"""Enhanced hover effect for bosses"""
	super._on_mouse_entered()
	
	# Intensify the pulse when hovered
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_method(_pulse_aura, 0.2, 0.6, 0.5)
		pulse_tween.tween_method(_pulse_aura, 0.6, 0.2, 0.5)

func _on_mouse_exited():
	"""Reset pulse intensity when hover ends"""
	super._on_mouse_exited()
	
	# Return to normal pulse
	if pulse_tween:
		pulse_tween.kill()
		start_pulse_animation()

func _exit_tree():
	"""Clean up when the node is removed"""
	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null