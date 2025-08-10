extends Control
class_name MapVisualizer

const DEBUG_ENABLED: bool = true

# Scene-based node preload
const MapNodeScene = preload("res://scenes/map/MapNodeScene.tscn")

# Visual settings
@export var node_radius: float = 20.0
@export var edge_width: float = 3.0
@export var visible_node_alpha: float = 1.0
@export var locked_node_alpha: float = 0.3
@export var player_node_outline: float = 4.0

# Colors
var player_color: Color = Color.GOLD
var edge_color: Color = Color.WHITE
var edge_visible_color: Color = Color.LIGHT_GRAY
var fog_color: Color = Color(0.1, 0.1, 0.1, 0.7)

# References
var map_generator: MapGenerator
var graph_data: Dictionary = {}
var layout_config: MapLayoutConfig  # Reference to layout config for path settings

# Node scenes for interaction
var node_scenes: Dictionary = {}  # node_id -> MapNodeScene
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
	layout_config = generator.layout_config  # Get reference to layout config
	
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
	# Remove all node scenes
	for scene in node_scenes.values():
		if scene and is_instance_valid(scene):
			scene.queue_free()
	node_scenes.clear()
	
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
	
	# Apply offset to ensure all edges are positioned within positive coordinates
	var graph_offset = get_meta("graph_offset", Vector2.ZERO)
	var from_pos = from_node.position - graph_offset
	var to_pos = to_node.position - graph_offset
	
	# Check if curved paths are enabled
	if layout_config and layout_config.path_enable_curves and layout_config.path_curve_strength > 0.0:
		create_curved_edge_visual(edge, from_pos, to_pos)
	else:
		create_straight_edge_visual(edge, from_pos, to_pos)

func create_straight_edge_visual(edge: MapEdge, from_pos: Vector2, to_pos: Vector2):
	# Use configurable dash parameters for consistent styling
	var dash_length = layout_config.path_dash_length if layout_config else 18.0
	var gap_length = layout_config.path_gap_length if layout_config else 12.0
	var total_length = from_pos.distance_to(to_pos)
	var direction = (to_pos - from_pos).normalized()
	
	var current_pos = from_pos
	var distance_covered = 0.0
	var is_dash = true
	
	while distance_covered < total_length:
		var segment_length = dash_length if is_dash else gap_length
		var remaining_distance = total_length - distance_covered
		segment_length = min(segment_length, remaining_distance)
		
		if is_dash and segment_length > 0:
			var line = Line2D.new()
			var end_pos = current_pos + direction * segment_length
			line.add_point(current_pos)
			line.add_point(end_pos)
			line.width = edge_width
			line.default_color = edge_color
			line.z_index = -1  # Behind nodes
			line.visible = true
			line.modulate = Color.WHITE
			
			# Store edge reference for updates
			line.set_meta("edge_data", edge)
			line.set_meta("is_dashed_segment", true)
			
			add_child(line)
			edge_lines.append(line)
		
		current_pos += direction * segment_length
		distance_covered += segment_length
		is_dash = !is_dash
	
	GLog.debug("Created straight edge from " + str(from_pos) + " to " + str(to_pos))

func create_curved_edge_visual(edge: MapEdge, from_pos: Vector2, to_pos: Vector2):
	# Calculate curve control point
	var midpoint = (from_pos + to_pos) * 0.5
	var distance = from_pos.distance_to(to_pos)
	var perpendicular = Vector2(-(to_pos.y - from_pos.y), to_pos.x - from_pos.x).normalized()
	
	# Add randomness and curve strength
	var curve_offset = distance * layout_config.path_curve_strength * 0.3
	var randomness = (randf() - 0.5) * layout_config.path_curve_randomness * distance
	var control_point = midpoint + perpendicular * (curve_offset + randomness)
	
	# Create curved path using multiple segments along Bezier curve
	var segments = max(int(distance / 15.0), 3)  # More segments for longer paths
	var dash_length = layout_config.path_dash_length if layout_config else 18.0
	var gap_length = layout_config.path_gap_length if layout_config else 12.0
	var current_distance = 0.0
	var total_curve_length = estimate_curve_length(from_pos, control_point, to_pos, segments)
	
	for i in range(segments):
		var t1 = float(i) / float(segments)
		var t2 = float(i + 1) / float(segments)
		
		var segment_start = quadratic_bezier(from_pos, control_point, to_pos, t1)
		var segment_end = quadratic_bezier(from_pos, control_point, to_pos, t2)
		var segment_length = segment_start.distance_to(segment_end)
		
		# Create dashed segments along the curve
		create_dashed_line_segment(edge, segment_start, segment_end, current_distance, dash_length, gap_length, total_curve_length)
		current_distance += segment_length

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	# Quadratic Bezier curve formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
	var u = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func estimate_curve_length(p0: Vector2, p1: Vector2, p2: Vector2, segments: int) -> float:
	var length = 0.0
	var prev_point = p0
	
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var current_point = quadratic_bezier(p0, p1, p2, t)
		length += prev_point.distance_to(current_point)
		prev_point = current_point
	
	return length

func create_dashed_line_segment(edge: MapEdge, start_pos: Vector2, end_pos: Vector2, distance_offset: float, dash_length: float, gap_length: float, total_length: float):
	var segment_length = start_pos.distance_to(end_pos)
	var direction = (end_pos - start_pos).normalized()
	
	var current_pos = start_pos
	var distance_covered = 0.0
	var cycle_length = dash_length + gap_length
	var offset_in_cycle = fmod(distance_offset, cycle_length)
	
	# Determine if we start with a dash or gap based on our position in the overall pattern
	var is_dash = offset_in_cycle < dash_length
	var remaining_in_current = (dash_length if is_dash else cycle_length) - offset_in_cycle
	
	while distance_covered < segment_length:
		var segment_to_draw = min(remaining_in_current, segment_length - distance_covered)
		
		if is_dash and segment_to_draw > 0.5:  # Only draw dashes longer than 0.5 pixels
			var line = Line2D.new()
			var dash_end = current_pos + direction * segment_to_draw
			line.add_point(current_pos)
			line.add_point(dash_end)
			line.width = edge_width
			line.default_color = edge_color
			line.z_index = -1  # Behind nodes
			line.visible = true
			line.modulate = Color.WHITE
			
			# Store edge reference for updates
			line.set_meta("edge_data", edge)
			line.set_meta("is_curved_segment", true)
			
			add_child(line)
			edge_lines.append(line)
		
		current_pos += direction * segment_to_draw
		distance_covered += segment_to_draw
		
		# Switch between dash and gap
		is_dash = !is_dash
		remaining_in_current = dash_length if is_dash else gap_length

func create_nodes():
	for node_id in graph_data.nodes:
		create_node_visual(node_id, graph_data.nodes[node_id])

func create_node_visual(node_id: String, node: MapNode):
	# Create appropriate scene based on node type
	var node_scene = create_node_scene_for_type(node.type)
	node_scene.name = "MapNode_" + node_id
	
	# Apply offset to ensure all nodes are positioned within positive coordinates
	var graph_offset = get_meta("graph_offset", Vector2.ZERO)
	var adjusted_position = node.position - graph_offset
	
	# Set up the node scene
	node_scene.setup_node(node_id, node)
	node_scene.set_position_centered(adjusted_position)
	node_scene.z_index = 1  # Above edges
	
	# Apply visibility based on state
	if node.state == MapNode.NodeState.LOCKED:
		node_scene.modulate.a = locked_node_alpha
	else:
		node_scene.modulate.a = visible_node_alpha
	
	# Connect signals
	node_scene.node_clicked.connect(_on_node_scene_clicked)
	node_scene.node_hovered.connect(_on_node_button_hovered)
	node_scene.node_unhovered.connect(_on_node_button_unhovered)
	
	# Store reference and metadata
	node_scene.set_meta("node_id", node_id)
	node_scene.set_meta("node_data", node)
	
	add_child(node_scene)
	node_scenes[node_id] = node_scene
	
	GLog.debug("Created node visual: " + node_id + " at " + str(node.position) + " (" + node.get_type_name() + ")")

func create_node_scene_for_type(node_type: MapNode.NodeType) -> MapNodeScene:
	"""Create the appropriate scene based on node type"""
	var scene_instance = MapNodeScene.instantiate()
	
	# The MapNodeScene will adapt its behavior based on the node data
	# when setup_node() is called with the actual MapNode data
	return scene_instance

func style_node_button(button: Button, node: MapNode):
	var style_box = StyleBoxFlat.new()
	
	# Base color from node type
	style_box.bg_color = node.get_type_color()
	style_box.corner_radius_top_left = node_radius
	style_box.corner_radius_top_right = node_radius
	style_box.corner_radius_bottom_left = node_radius
	style_box.corner_radius_bottom_right = node_radius
	
	# Apply visibility based on state
	if node.state == MapNode.NodeState.LOCKED:
		style_box.bg_color.a = locked_node_alpha
	else:
		style_box.bg_color.a = visible_node_alpha
	
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
	if node.state != MapNode.NodeState.LOCKED:
		button.tooltip_text = node.get_description()
	else:
		button.tooltip_text = "Unexplored location"

func update_visibility():
	# Update all node visibilities
	for node_id in node_scenes:
		var node_scene = node_scenes[node_id]
		var node = graph_data.nodes[node_id]
		
		if node_scene and node:
			update_node_interactivity(node_scene, node)
	
	# Update edge visibilities
	update_edge_visibility()

func update_node_interactivity(node_scene: MapNodeScene, node: MapNode):
	# IMPORTANT: Do NOT override node states - respect the persistent discovery system
	# Only update visual styling based on the node's current state
	
	var alpha = node.get_state_alpha()
	node_scene.modulate = Color(1, 1, 1, alpha)
	
	# Update visual styling based on node state
	match node.state:
		MapNode.NodeState.LOCKED:
			# Hidden/locked nodes (should not be visible)
			node_scene.modulate = Color(1, 1, 1, locked_node_alpha)
		MapNode.NodeState.KNOWN:
			# Visible but unreachable - use dimmed appearance
			node_scene.modulate = Color(0.8, 0.8, 1.0, 0.7)  # Slightly blue-tinted and dimmed
		MapNode.NodeState.AVAILABLE:
			# Fully visible and interactive
			node_scene.modulate = Color(1, 1, 1, visible_node_alpha)
		MapNode.NodeState.CURRENT:
			# Current position - highlighted
			node_scene.modulate = Color(1.2, 1.2, 0.8, visible_node_alpha)  # Slightly warm/bright
		MapNode.NodeState.COMPLETED:
			# Previously visited
			node_scene.modulate = Color(1, 1, 1, 0.6)
	
	# Refresh the scene's visuals and interactivity
	node_scene.refresh()

func update_edge_visibility():
	for line in edge_lines:
		var edge = line.get_meta("edge_data", null) as MapEdge
		if not edge:
			continue
		
		var from_node = graph_data.nodes.get(edge.from_node)
		var to_node = graph_data.nodes.get(edge.to_node)
		
		if not from_node or not to_node:
			continue
		
		# Show edge if either node is not locked (visible)
		if from_node.state != MapNode.NodeState.LOCKED or to_node.state != MapNode.NodeState.LOCKED:
			line.default_color = edge_visible_color
			line.visible = true
		else:
			line.visible = false

func _draw():
	# Draw fog of war overlay for locked areas
	if not graph_data.has("nodes"):
		return
	
	# This could be enhanced to draw more sophisticated fog effects
	pass

# Event handlers
func _on_map_generated(graph: Dictionary):
	GLog.debug("Visualizing newly generated map")
	visualize_graph(graph)

func _on_node_discovered(node_id: String):
	GLog.debug("Node revealed, updating visualization: " + node_id)
	
	# Update the revealed node
	var node_scene = node_scenes.get(node_id)
	if node_scene:
		node_scene.play_discover_animation()
		node_scene.refresh()
	
	update_visibility()

func _on_player_moved(from_node: String, to_node: String):
	GLog.debug("Player moved, updating visualization: " + from_node + " -> " + to_node)
	update_visibility()

func _on_node_scene_clicked(node_id: String, event: InputEvent):
	GLog.debug("Node scene clicked: " + node_id)
	node_clicked.emit(node_id)

func _on_node_area_input(event: InputEvent, node_id: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GLog.debug("Node area clicked: " + node_id)
		node_clicked.emit(node_id)

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
	var current_player_node = graph_data.nodes.get(graph_data.player_position)
	
	for node_id in node_scenes:
		var node_scene = node_scenes[node_id]
		var node = graph_data.nodes[node_id]
		var is_available = node_id in available_moves and node.state != MapNode.NodeState.LOCKED
		
		# Apply same logic as update_node_interactivity for consistency
		if node.state == MapNode.NodeState.COMPLETED:
			var can_revisit = node.can_revisit()
			is_available = is_available and can_revisit and current_player_node and current_player_node.is_connected_to(node.id)
		
		# Add visual highlighting for available moves
		node_scene.set_highlight(is_available)

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
	GLog.debug("Node scenes: " + str(node_scenes.size()))
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
		if child is MapNodeScene:
			child.visible = true
			child.modulate = Color.WHITE
		elif child is Line2D:
			child.visible = true
			child.modulate = Color.WHITE
		elif child is ColorRect:
			child.visible = true
			child.modulate = Color.WHITE
	
	GLog.debug("Forced visibility on MapVisualizer and all children")
