extends Control
class_name MapVisualizer

const DEBUG_ENABLED: bool = true

# Visual settings
@export var node_radius: float = 20.0
@export var edge_width: float = 3.0
@export var discovered_node_alpha: float = 1.0
@export var undiscovered_node_alpha: float = 0.3
@export var player_node_outline: float = 4.0

# Colors
var player_color: Color = Color.GOLD
var edge_color: Color = Color.WHITE
var edge_discovered_color: Color = Color.LIGHT_GRAY
var fog_color: Color = Color(0.1, 0.1, 0.1, 0.7)

# References
var map_generator: MapGenerator
var graph_data: Dictionary = {}

# Node buttons for interaction
var node_buttons: Dictionary = {}  # node_id -> Button
var edge_lines: Array[Line2D] = []

# Signals
signal node_clicked(node_id: String)
signal node_hovered(node_id: String)
signal node_unhovered()

func _init():
	name = "MapVisualizer"
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Set up basic position
	position = Vector2.ZERO
	
	# Debug output
	GLog.debug("MapVisualizer _init called")

func setup(generator: MapGenerator):
	map_generator = generator
	
	# Connect to generator signals
	if map_generator.map_generated.is_connected(_on_map_generated):
		map_generator.map_generated.disconnect(_on_map_generated)
	if map_generator.node_discovered.is_connected(_on_node_discovered):
		map_generator.node_discovered.disconnect(_on_node_discovered)
	if map_generator.player_moved.is_connected(_on_player_moved):
		map_generator.player_moved.disconnect(_on_player_moved)
	
	map_generator.map_generated.connect(_on_map_generated)
	map_generator.node_discovered.connect(_on_node_discovered)
	map_generator.player_moved.connect(_on_player_moved)
	
	GLog.debug("MapVisualizer setup complete - connected to generator")

func visualize_graph(graph: Dictionary):
	GLog.debug("Starting graph visualization...")
	GLog.debug("Graph has " + str(graph.get("nodes", {}).size()) + " nodes")
	
	clear_visualization()
	graph_data = graph
	
	# Ensure we have valid graph data
	if not graph_data.has("nodes") or graph_data.nodes.is_empty():
		GLog.debug("No nodes to visualize!")
		return
	
	# Set proper size based on graph bounds
	setup_container_size()
	
	# Create visual elements
	create_edges()
	create_nodes()
	
	# Initial update
	update_visibility()
	
	# Force visibility
	visible = true
	modulate = Color.WHITE
	
	GLog.debug("Graph visualization complete - visible: " + str(visible) + ", children: " + str(get_child_count()))

func clear_visualization():
	# Remove all node buttons
	for button in node_buttons.values():
		if button and is_instance_valid(button):
			button.queue_free()
	node_buttons.clear()
	
	# Remove all edge lines
	for line in edge_lines:
		if line and is_instance_valid(line):
			line.queue_free()
	edge_lines.clear()

func create_edges():
	for edge in graph_data.get("edges", []):
		create_edge_visual(edge)

func create_edge_visual(edge: MapEdge):
	var from_node = graph_data.nodes.get(edge.from_node)
	var to_node = graph_data.nodes.get(edge.to_node)
	
	if not from_node or not to_node:
		GLog.debug("Failed to create edge: missing nodes " + edge.from_node + " -> " + edge.to_node)
		return
	
	var line = Line2D.new()
	# Apply offset to ensure all edges are positioned within positive coordinates
	var graph_offset = get_meta("graph_offset", Vector2.ZERO)
	var from_pos = from_node.position - graph_offset
	var to_pos = to_node.position - graph_offset
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = edge_width
	line.default_color = edge_color
	line.z_index = 1  # Above background but below buttons
	line.visible = true  # Explicitly set visible
	line.modulate = Color.WHITE  # Ensure full opacity
	
	# Store edge reference for updates
	line.set_meta("edge_data", edge)
	
	add_child(line)
	edge_lines.append(line)
	
	GLog.debug("Created edge from " + str(from_pos) + " to " + str(to_pos) + " (width: " + str(edge_width) + ", color: " + str(edge_color) + ")")

func create_nodes():
	for node_id in graph_data.nodes:
		create_node_visual(node_id, graph_data.nodes[node_id])

func create_node_visual(node_id: String, node: MapNode):
	var button = Button.new()
	button.custom_minimum_size = Vector2(node_radius * 4, node_radius * 2)  # Wider for text
	
	# Apply offset to ensure all nodes are positioned within positive coordinates
	var graph_offset = get_meta("graph_offset", Vector2.ZERO)
	var adjusted_position = node.position - graph_offset - Vector2(node_radius, node_radius)
	button.position = adjusted_position
	
	button.flat = false  # Make buttons visible
	button.text = node.get_type_name()[0]  # Show full type name
	
	# Style the button based on node type
	style_node_button(button, node)
	
	# Connect signals
	button.pressed.connect(_on_node_button_pressed.bind(node_id))
	button.mouse_entered.connect(_on_node_button_hovered.bind(node_id))
	button.mouse_exited.connect(_on_node_button_unhovered)
	
	# Store reference
	button.set_meta("node_id", node_id)
	button.set_meta("node_data", node)
	
	add_child(button)
	node_buttons[node_id] = button
	
	GLog.debug("Created node visual: " + node_id + " at " + str(node.position) + " (" + node.get_type_name() + ")")

func style_node_button(button: Button, node: MapNode):
	var style_box = StyleBoxFlat.new()
	
	# Base color from node type
	style_box.bg_color = node.get_type_color()
	style_box.corner_radius_top_left = node_radius
	style_box.corner_radius_top_right = node_radius
	style_box.corner_radius_bottom_left = node_radius
	style_box.corner_radius_bottom_right = node_radius
	
	# Apply discovery visibility
	if not node.discovered:
		style_box.bg_color.a = undiscovered_node_alpha
	else:
		style_box.bg_color.a = discovered_node_alpha
	
	# Player position outline
	if graph_data.player_position == node.id:
		style_box.border_width_left = player_node_outline
		style_box.border_width_right = player_node_outline
		style_box.border_width_top = player_node_outline
		style_box.border_width_bottom = player_node_outline
		style_box.border_color = player_color
	
	# Different styles for different states
	button.add_theme_stylebox_override("normal", style_box)
	button.add_theme_stylebox_override("hover", style_box.duplicate())
	button.add_theme_stylebox_override("pressed", style_box.duplicate())
	
	# Tooltip
	if node.discovered:
		button.tooltip_text = node.get_description()
	else:
		button.tooltip_text = "Unexplored location"

func update_visibility():
	# Update all node visibilities
	for node_id in node_buttons:
		var button = node_buttons[node_id]
		var node = graph_data.nodes[node_id]
		
		if button and node:
			style_node_button(button, node)
			update_node_interactivity(button, node)
	
	# Update edge visibilities
	update_edge_visibility()

func update_node_interactivity(button: Button, node: MapNode):
	var current_player_node = graph_data.nodes.get(graph_data.player_position)
	
	if not node.discovered:
		button.disabled = true
	elif node.id == graph_data.player_position:
		button.disabled = true  # Can't move to current position
	elif current_player_node and current_player_node.is_connected_to(node.id):
		button.disabled = false  # Can move to connected discovered nodes
	else:
		button.disabled = true  # Can't move to unconnected nodes

func update_edge_visibility():
	for line in edge_lines:
		var edge = line.get_meta("edge_data", null) as MapEdge
		if not edge:
			continue
		
		var from_node = graph_data.nodes.get(edge.from_node)
		var to_node = graph_data.nodes.get(edge.to_node)
		
		if not from_node or not to_node:
			continue
		
		# Show edge if either node is discovered
		if from_node.discovered or to_node.discovered:
			line.default_color = edge_discovered_color
			line.visible = true
		else:
			line.visible = false

func _draw():
	# Draw fog of war overlay for undiscovered areas
	if not graph_data.has("nodes"):
		return
	
	# This could be enhanced to draw more sophisticated fog effects
	pass

# Event handlers
func _on_map_generated(graph: Dictionary):
	GLog.debug("Visualizing newly generated map")
	visualize_graph(graph)

func _on_node_discovered(node_id: String):
	GLog.debug("Node discovered, updating visualization: " + node_id)
	update_visibility()

func _on_player_moved(from_node: String, to_node: String):
	GLog.debug("Player moved, updating visualization: " + from_node + " -> " + to_node)
	update_visibility()

func _on_node_button_pressed(node_id: String):
	GLog.debug("Node button pressed: " + node_id)
	node_clicked.emit(node_id)

func _on_node_button_hovered(node_id: String):
	node_hovered.emit(node_id)

func _on_node_button_unhovered():
	node_unhovered.emit()

# Public interface
func get_node_position(node_id: String) -> Vector2:
	var node = graph_data.nodes.get(node_id)
	return node.position if node else Vector2.ZERO

func highlight_available_moves():
	var available_moves = map_generator.get_available_moves()
	
	for node_id in node_buttons:
		var button = node_buttons[node_id]
		var is_available = node_id in available_moves
		
		# Add visual highlighting for available moves
		if is_available:
			var style = button.get_theme_stylebox("normal").duplicate()
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color.YELLOW
			button.add_theme_stylebox_override("normal", style)

func clear_move_highlights():
	update_visibility()  # This will reset all styling

func setup_container_size():
	var bounds = get_graph_bounds()
	
	GLog.debug("Graph bounds: " + str(bounds))
	
	# Set custom minimum size to contain all nodes
	custom_minimum_size = bounds.size
	
	# Ensure we have a reasonable minimum size
	if custom_minimum_size.x < 600:
		custom_minimum_size.x = 600
	if custom_minimum_size.y < 400:
		custom_minimum_size.y = 400
	
	# Use set_deferred to avoid anchor conflicts
	set_deferred("size", custom_minimum_size)
	
	# Remove any existing background before adding new one
	for child in get_children():
		if child.name == "Background":
			child.queue_free()
	
	# Add a subtle background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.08, 0.05, 1)  # Dark green background
	bg.position = Vector2.ZERO
	bg.size = custom_minimum_size
	bg.z_index = -10  # Behind everything else
	add_child(bg)
	move_child(bg, 0)  # Ensure it's the first child
	
	GLog.debug("MapVisualizer size set to: " + str(custom_minimum_size))
	GLog.debug("Background added, total children: " + str(get_child_count()))

func get_graph_bounds() -> Rect2:
	if not graph_data.has("nodes") or graph_data.nodes.is_empty():
		GLog.debug("No nodes for bounds calculation, using default")
		return Rect2(0, 0, 800, 600)
	
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for node in graph_data.nodes.values():
		if node and node.has_method("get") and node.position:
			min_pos.x = min(min_pos.x, node.position.x)
			min_pos.y = min(min_pos.y, node.position.y)
			max_pos.x = max(max_pos.x, node.position.x)
			max_pos.y = max(max_pos.y, node.position.y)
	
	var padding = node_radius * 2
	# Ensure bounds always start at (0,0) to prevent negative positioning issues
	var result = Rect2(
		0,
		0,
		max_pos.x - min_pos.x + padding * 2,
		max_pos.y - min_pos.y + padding * 2
	)
	
	# Store offset for repositioning nodes
	set_meta("graph_offset", Vector2(min_pos.x - padding, min_pos.y - padding))
	
	GLog.debug("Calculated bounds: " + str(result))
	GLog.debug("Graph offset: " + str(Vector2(min_pos.x - padding, min_pos.y - padding)))
	return result

# Add a debug method to check current state
func debug_state():
	GLog.debug("=== MapVisualizer Debug State ===")
	GLog.debug("Visible: " + str(visible))
	GLog.debug("Modulate: " + str(modulate))
	GLog.debug("Size: " + str(size))
	GLog.debug("Position: " + str(position))
	GLog.debug("Children count: " + str(get_child_count()))
	GLog.debug("Node buttons: " + str(node_buttons.size()))
	GLog.debug("Edge lines: " + str(edge_lines.size()))
	GLog.debug("Graph data nodes: " + str(graph_data.get("nodes", {}).size()))
	GLog.debug("Parent: " + str(get_parent().name if get_parent() else "None"))
	if get_parent():
		GLog.debug("Parent size: " + str(get_parent().size))
		GLog.debug("Parent visible: " + str(get_parent().visible))
	GLog.debug("================================")

# Force visibility for debugging
func force_visibility():
	visible = true
	modulate = Color.WHITE
	z_index = 100  # Bring to front
	
	# Make all children visible
	for child in get_children():
		if child is Button:
			child.visible = true
			child.modulate = Color.WHITE
		elif child is Line2D:
			child.visible = true
			child.modulate = Color.WHITE
		elif child is ColorRect:
			child.visible = true
			child.modulate = Color.WHITE
	
	GLog.debug("Forced visibility on MapVisualizer and all children")
