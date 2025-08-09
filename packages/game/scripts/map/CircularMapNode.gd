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
	
	# Draw main circle
	draw_circle(center, node_radius, node_color)
	
	# Draw player position outline if needed
	if is_player_position:
		draw_arc(center, node_radius + outline_width/2, 0, TAU, 64, outline_color, outline_width)
	
	# Draw text label
	if node_text != "":
		var font = ThemeDB.fallback_font
		var font_size = 16
		var text_size = font.get_string_size(node_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos = center - text_size / 2
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
	mouse_filter = MOUSE_FILTER_PASS if can_interact else MOUSE_FILTER_IGNORE
	
	# Visual feedback for interactivity
	if can_interact:
		modulate = Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5, 0.8)  # Dim non-interactive nodes

func set_highlight(highlight: bool):
	if highlight:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE