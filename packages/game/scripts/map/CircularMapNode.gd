extends Control
class_name CircularMapNode

# Visual properties
var node_radius: float = 20.0
var node_color: Color = Color.WHITE
var outline_width: float = 4.0
var outline_color: Color = Color.GOLD
var text_color: Color = Color.WHITE
var node_text: String = ""

# State
var is_player_position: bool = false
var is_highlighted: bool = false
var is_hoverable: bool = false
var is_mouse_hovering: bool = false
var node_data: MapNode
var node_id: String

# Signals
signal node_clicked(event: InputEvent)

func setup(id: String, node: MapNode, radius: float, outline_w: float, outline_c: Color):
	node_id = id
	node_data = node
	node_radius = radius
	outline_width = outline_w
	outline_color = outline_c
	
	# Set visual properties
	node_color = node.get_type_color()
	node_text = node.get_type_name()[0]  # First letter
	
	# Set size to contain the full circle
	custom_minimum_size = Vector2(radius * 2, radius * 2)
	size = Vector2(radius * 2, radius * 2)
	
	# Position so circle is centered on (0,0)
	pivot_offset = Vector2(radius, radius)

func set_player_position(is_player: bool):
	is_player_position = is_player
	queue_redraw()  # Trigger a redraw

func _draw():
	var center = Vector2(node_radius, node_radius)
	
	# Draw highlight glow effect if highlighted (available move)
	if is_highlighted:
		var glow_color = Color.LIME_GREEN
		glow_color.a = 0.6
		# Draw multiple circles for glow effect
		for i in range(3):
			var glow_radius = node_radius + (i + 1) * 6
			var glow_alpha = 0.6 - (i * 0.2)
			glow_color.a = glow_alpha
			draw_arc(center, glow_radius, 0, TAU, 64, glow_color, 4.0)
	
	# Draw main circle
	draw_circle(center, node_radius, node_color)
	
	# Draw player position outline with pulse effect
	if is_player_position:
		var time = Engine.get_process_frames() * 0.016  # Approximate frame time
		var pulse_factor = (sin(time * 3.0) * 0.3 + 1.0)
		var pulsed_outline = outline_width * pulse_factor
		var pulsed_color = outline_color
		pulsed_color.a = 0.8 + (pulse_factor - 1.0) * 0.4
		draw_arc(center, node_radius + pulsed_outline/2, 0, TAU, 64, pulsed_color, pulsed_outline)
	
	# Draw hover outline if hoverable and mouse is over
	if is_hoverable and is_mouse_hovering:
		var hover_color = Color.YELLOW
		hover_color.a = 0.8
		draw_arc(center, node_radius + 3, 0, TAU, 64, hover_color, 2.0)
	
	# Draw text label
	if node_text != "":
		var font = ThemeDB.fallback_font
		var font_size = 16
		var text_size = font.get_string_size(node_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos = center - text_size / 2
		# Adjust vertical centering more precisely
		text_pos.y += font_size * 0.3  # Move down slightly for better visual centering
		draw_string(font, text_pos, node_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is within the circle
		var click_pos = event.position
		var center = Vector2(node_radius, node_radius)
		var distance = click_pos.distance_to(center)
		
		if distance <= node_radius:
			node_clicked.emit(event)

func update_interactivity(can_interact: bool):
	is_hoverable = can_interact
	mouse_filter = MOUSE_FILTER_PASS if can_interact else MOUSE_FILTER_IGNORE
	
	# Visual feedback for interactivity
	if can_interact:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)  # Dim non-interactive nodes
	
	queue_redraw()

func set_highlight(highlight: bool):
	is_highlighted = highlight
	queue_redraw()

func _process(_delta):
	# Handle mouse hover detection
	if is_hoverable:
		var mouse_in_area = get_global_rect().has_point(get_global_mouse_position())
		if mouse_in_area != is_mouse_hovering:
			is_mouse_hovering = mouse_in_area
			if is_mouse_hovering:
				mouse_entered.emit()
			else:
				mouse_exited.emit()
			queue_redraw()
	
	# Only queue redraw if we need animations (player position pulse)
	if is_player_position:
		queue_redraw()

func _ready():
	# Enable processing for animations
	set_process(true)
