extends Control
class_name MapController

const DEBUG_ENABLED: bool = true

# Core map components we need
const MapNodeScene = preload("res://scenes/map/MapNodeScene.tscn")
const DelaunayTriangulator = preload("res://scripts/map/DelaunayTriangulator.gd")
const MapConfig = preload("res://scripts/map/MapConfig.gd")

# Map configuration
var map_config: MapConfig = load("res://data/map_config.tres") as MapConfig

# Simple map state
var nodes: Dictionary = {}  # node_id -> {position: Vector2, scene: MapNodeScene, connections: Array[String]}
var edges: Array[Dictionary] = []  # {from: String, to: String, line: Line2D}
var current_player_node: String = ""

# UI references
@onready var map_container = $MapViewport/MapContent

func _ready():
	if DEBUG_ENABLED:
		print("=== SIMPLE MAP SYSTEM INITIALIZED ===")
	
	# Generate a simple test map
	generate_simple_map()

func generate_simple_map():
	"""Generate a simple map using Delaunay triangulation"""
	if DEBUG_ENABLED:
		print("Generating simple map with Delaunay triangulation...")
	
	# Clear existing content
	clear_map()
	
	# Generate some random node positions using config
	var node_positions = generate_random_positions(map_config.total_nodes)
	
	# Apply Delaunay triangulation to get connections
	var triangulation = DelaunayTriangulator.triangulate(node_positions)
	var edges_data = DelaunayTriangulator.triangulation_to_edges(triangulation)
	
	if DEBUG_ENABLED:
		print("Generated", node_positions.size(), "nodes with", edges_data.size(), "connections")
	
	# First pass: create initial node assignments
	var initial_assignments = assign_node_types_to_positions(node_positions)
	
	# Create Delaunay edges and filter them
	var filtered_edges = get_filtered_edges(edges_data, node_positions)
	
	# Detect dead-ends and reassign them as mines
	var final_assignments = reassign_dead_ends_as_mines(node_positions, filtered_edges, initial_assignments)
	
	# Create nodes with final assignments
	create_nodes_with_assignments(node_positions, final_assignments)
	
	# Create connections
	create_connections_from_filtered(filtered_edges)
	
	# Set starting node to the city
	var city_node_id = find_city_node()
	if city_node_id != "":
		set_current_player_node(city_node_id)
	elif not nodes.is_empty():
		# Fallback to first node if no city found
		set_current_player_node(nodes.keys()[0])
	
	if DEBUG_ENABLED:
		print("Simple map generation complete!")

func generate_random_positions(count: int) -> Array[Vector2]:
	"""Generate random positions within the map area"""
	var positions: Array[Vector2] = []
	var map_size = get_viewport().get_visible_rect().size
	var margin = 100.0
	
	# Use a simple grid with random offset to ensure good distribution
	var grid_cols = int(sqrt(count)) + 1
	var grid_rows = int(count / grid_cols) + 1
	var cell_width = (map_size.x - margin * 2) / grid_cols
	var cell_height = (map_size.y - margin * 2) / grid_rows
	
	for i in range(count):
		var row = i / grid_cols
		var col = i % grid_cols
		
		var base_x = margin + col * cell_width + cell_width * 0.5
		var base_y = margin + row * cell_height + cell_height * 0.5
		
		# Add random offset within the cell
		var offset_x = (SeedManager.get_map_random_float() - 0.5) * cell_width * 0.6
		var offset_y = (SeedManager.get_map_random_float() - 0.5) * cell_height * 0.6
		
		var pos = Vector2(base_x + offset_x, base_y + offset_y)
		positions.append(pos)
	
	return positions

func get_filtered_edges(edges_data: Array, positions: Array[Vector2]) -> Array:
	"""Filter edges based on length and type rules, return filtered list"""
	var position_to_index = {}
	for i in range(positions.size()):
		position_to_index[str(positions[i])] = i
	
	var filtered = []
	for edge in edges_data:
		# Check edge length
		var distance = edge.p1.distance_to(edge.p2)
		if distance > map_config.max_edge_length:
			continue
		
		var from_idx = position_to_index.get(str(edge.p1))
		var to_idx = position_to_index.get(str(edge.p2))
		
		if from_idx != null and to_idx != null:
			filtered.append({"from_idx": from_idx, "to_idx": to_idx, "distance": distance})
	
	return filtered

func reassign_dead_ends_as_mines(positions: Array[Vector2], filtered_edges: Array, initial_assignments: Array) -> Array:
	"""Detect nodes with 1 connection and force them to be mines"""
	var final_assignments = initial_assignments.duplicate(true)
	
	# Count connections per node index
	var connection_count = {}
	for i in range(positions.size()):
		connection_count[i] = 0
	
	for edge in filtered_edges:
		connection_count[edge.from_idx] += 1
		connection_count[edge.to_idx] += 1
	
	# Load mine config for reassignment
	var mine_config = load("res://data/map_nodes/mines/default.tres") as MapNodeConfig
	
	# Reassign dead-ends as mines
	for i in range(positions.size()):
		if connection_count[i] == 1:  # Dead end
			# Don't reassign the city!
			if final_assignments[i].type != "city":
				if DEBUG_ENABLED:
					print("Reassigning dead-end node", i, "from", final_assignments[i].type, "to mine")
				
				final_assignments[i] = {
					"type": "mine",
					"type_name": "Mine",
					"config": mine_config
				}
	
	return final_assignments

func create_nodes_with_assignments(positions: Array[Vector2], assignments: Array):
	"""Create MapNodeScene instances with given assignments"""
	for i in range(positions.size()):
		var node_id = "node_" + str(i + 1)
		var position = positions[i]
		var node_type_info = assignments[i]
		
		# Create the MapNodeScene instance
		var node_scene = MapNodeScene.instantiate()
		map_container.add_child(node_scene)
		
		# Position it
		node_scene.position = position - Vector2(16, 16)  # Center the node
		node_scene.z_index = map_config.node_z_index  # Nodes above edges
		
		# Create real MapNode with proper config
		var map_node = create_node_with_config(node_id, node_type_info.config, position)
		node_scene.setup_node(node_id, map_node)
		
		# Connect click signal
		node_scene.node_clicked.connect(_on_node_clicked)
		
		# Store in our nodes dictionary
		nodes[node_id] = {
			"position": position,
			"scene": node_scene,
			"connections": [],
			"map_node": map_node,
			"type": node_type_info.type
		}
		
		if DEBUG_ENABLED:
			print("Created", node_type_info.type_name, "node:", node_id, "at", position)

func create_connections_from_filtered(filtered_edges: Array):
	"""Create connections from pre-filtered edges"""
	for edge in filtered_edges:
		var from_node_id = "node_" + str(edge.from_idx + 1)
		var to_node_id = "node_" + str(edge.to_idx + 1)
		create_connection(from_node_id, to_node_id)

# Old create_nodes_from_positions is replaced by new flow:
# get_filtered_edges -> reassign_dead_ends_as_mines -> create_nodes_with_assignments

func create_node_with_config(node_id: String, node_config: MapNodeConfig, position: Vector2) -> MapNode:
	"""Create a real MapNode with proper configuration"""
	var map_node = MapNode.new(node_id, position, node_config)
	map_node.set_state(MapNode.NodeState.AVAILABLE)
	return map_node

func assign_node_types_to_positions(positions: Array[Vector2]) -> Array:
	"""Assign node types strategically based on position and game rules"""
	var assignments = []
	var map_size = get_viewport().get_visible_rect().size
	var map_center = Vector2(map_size.x * 0.5, map_size.y * 0.5)
	
	# Load available node configurations
	var node_configs = load_node_configurations()
	
	# Step 1: Find the position closest to center for the city
	var city_index = find_center_position_index(positions, map_center)
	
	# Step 2: Find edge positions for settlements
	var edge_indices = find_edge_position_indices(positions, map_size)
	
	# Step 3: Assign types
	for i in range(positions.size()):
		var assignment = {}
		
		if i == city_index:
			# Central city
			assignment.type = "city"
			assignment.type_name = "City"
			assignment.config = node_configs.city
		elif i in edge_indices:
			# Edge settlement
			assignment.type = "settlement"
			assignment.type_name = "Settlement" 
			assignment.config = node_configs.settlement
		else:
			# Interior content - distribute randomly
			var interior_type = choose_interior_node_type()
			assignment.type = interior_type
			assignment.type_name = interior_type.capitalize()
			assignment.config = node_configs[interior_type]
		
		assignments.append(assignment)
	
	if DEBUG_ENABLED:
		print("Assigned city to index:", city_index)
		print("Assigned settlements to indices:", edge_indices)
	
	return assignments

func load_node_configurations() -> Dictionary:
	"""Load all the different node type configurations"""
	return {
		"city": load("res://data/map_nodes/cities/default.tres") as MapNodeConfig,
		"settlement": load("res://data/map_nodes/settlements/default.tres") as MapNodeConfig,
		"camp": load("res://data/map_nodes/camps/default.tres") as MapNodeConfig,
		"mine": load("res://data/map_nodes/mines/default.tres") as MapNodeConfig,
		"poi": load("res://data/map_nodes/pois/default.tres") as MapNodeConfig,
		"junction": load("res://data/map_nodes/junctions/default.tres") as MapNodeConfig,
		"boss": load("res://data/map_nodes/bosses/default.tres") as MapNodeConfig
	}

func find_center_position_index(positions: Array[Vector2], center: Vector2) -> int:
	"""Find the position closest to the map center"""
	var closest_index = 0
	var closest_distance = positions[0].distance_to(center)
	
	for i in range(1, positions.size()):
		var distance = positions[i].distance_to(center)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i
	
	return closest_index

func find_edge_position_indices(positions: Array[Vector2], map_size: Vector2) -> Array[int]:
	"""Find positions near the map edges for settlements"""
	var edge_indices: Array[int] = []
	var edge_threshold = 150.0  # Distance from edge to be considered "edge"
	var max_settlements = 4
	
	# Find positions near edges
	var edge_candidates = []
	for i in range(positions.size()):
		var pos = positions[i]
		var distance_to_edge = min(
			min(pos.x, map_size.x - pos.x),  # Distance to left/right edge
			min(pos.y, map_size.y - pos.y)   # Distance to top/bottom edge
		)
		
		if distance_to_edge <= edge_threshold:
			edge_candidates.append({"index": i, "distance": distance_to_edge})
	
	# Sort by distance to edge (closest first) and take up to max_settlements
	edge_candidates.sort_custom(func(a, b): return a.distance < b.distance)
	
	for i in range(min(max_settlements, edge_candidates.size())):
		edge_indices.append(edge_candidates[i].index)
	
	return edge_indices

func choose_interior_node_type() -> String:
	"""Randomly choose an interior node type with weighted distribution"""
	var rand = SeedManager.get_map_random_float()
	
	# Weighted distribution for interior nodes
	if rand < 0.35:		# 35% camps
		return "camp"
	elif rand < 0.55:	# 20% mines  
		return "mine"
	elif rand < 0.70:	# 15% POIs
		return "poi"
	elif rand < 0.90:	# 20% junctions
		return "junction"
	else:				# 10% boss (but we should limit to 1)
		return "boss"

func find_city_node() -> String:
	"""Find the node ID of the city"""
	for node_id in nodes:
		if nodes[node_id].type == "city":
			return node_id
	return ""

func should_connect_node_types(from_node_id: String, to_node_id: String) -> bool:
	"""Apply type-based connection rules"""
	var from_type = nodes[from_node_id].type
	var to_type = nodes[to_node_id].type
	
	# Rule 1: Same types shouldn't connect directly (except junctions)
	if from_type == to_type:
		if from_type != "junction":  # Junctions can connect to other junctions
			return false
	
	# Rule 2: Cities connect to everything (they're hubs)
	if from_type == "city" or to_type == "city":
		return true
	
	# Rule 3: Settlements (at edges) connect inward but not to other settlements
	if from_type == "settlement" and to_type == "settlement":
		return false
	
	# Rule 4: Mines should be more isolated - limit their connections
	# (This rule is applied by the mine having fewer edges in Delaunay, but we allow them)
	
	# Rule 5: Everything else can connect
	return true

func ensure_minimum_connections(filtered_edges: Array, all_valid_edges: Array) -> Array:
	"""Ensure each node has at least min_edges_per_node connections"""
	var result_edges = filtered_edges.duplicate()
	
	# Count connections per node
	var connection_count = {}
	for node_id in nodes:
		connection_count[node_id] = 0
	
	for edge in filtered_edges:
		connection_count[edge.from] += 1
		connection_count[edge.to] += 1
	
	# For nodes with insufficient connections, add shortest valid edges
	for node_id in nodes:
		if connection_count[node_id] < map_config.min_edges_per_node:
			var needed = map_config.min_edges_per_node - connection_count[node_id]
			
			if DEBUG_ENABLED:
				print("Node", node_id, "has", connection_count[node_id], "connections, needs", needed, "more")
			
			# Find candidate edges for this node from all_valid_edges
			var candidates = []
			for edge in all_valid_edges:
				if edge.from == node_id or edge.to == node_id:
					# Check if this edge is already in result
					var already_exists = false
					for existing in result_edges:
						if (existing.from == edge.from and existing.to == edge.to) or \
						   (existing.from == edge.to and existing.to == edge.from):
							already_exists = true
							break
					
					if not already_exists:
						candidates.append(edge)
			
			# Sort candidates by distance and add shortest ones
			candidates.sort_custom(func(a, b): return a.distance < b.distance)
			
			for i in range(min(needed, candidates.size())):
				result_edges.append({"from": candidates[i].from, "to": candidates[i].to})
				connection_count[candidates[i].from] += 1
				connection_count[candidates[i].to] += 1
				
				if DEBUG_ENABLED:
					print("Added edge for minimum connections:", candidates[i].from, "->", candidates[i].to)
	
	return result_edges

func validate_graph_connectivity(edge_list: Array) -> bool:
	"""Check if the filtered edges maintain graph connectivity"""
	if edge_list.is_empty():
		return false
	
	# Build adjacency list from edge_list
	var adj_list = {}
	for node_id in nodes:
		adj_list[node_id] = []
	
	for edge in edge_list:
		adj_list[edge.from].append(edge.to)
		adj_list[edge.to].append(edge.from)
	
	# Find city node as starting point (should be connected to everything)
	var city_node_id = find_city_node()
	if city_node_id == "":
		# If no city, use first node
		city_node_id = nodes.keys()[0]
	
	# BFS from city to check if all nodes are reachable
	var visited = {}
	var queue = [city_node_id]
	visited[city_node_id] = true
	
	while not queue.is_empty():
		var current = queue.pop_front()
		
		for neighbor in adj_list[current]:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	
	# Check if all nodes were visited
	var all_connected = visited.size() == nodes.size()
	
	if DEBUG_ENABLED and not all_connected:
		print("Connectivity check failed: visited", visited.size(), "of", nodes.size(), "nodes")
	
	return all_connected

func create_connections_from_edges(edges_data: Array):
	"""Create visual connections from Delaunay edges with type-based filtering"""
	# First, map positions back to node IDs
	var position_to_node = {}
	for node_id in nodes:
		var pos = nodes[node_id].position
		position_to_node[str(pos)] = node_id
	
	# Filter edges based on type rules and length before creating connections
	var filtered_edges = []
	var all_valid_edges = []  # Keep all valid edges for minimum connection enforcement
	
	for edge in edges_data:
		var from_key = str(edge.p1)
		var to_key = str(edge.p2)
		
		var from_node_id = position_to_node.get(from_key)
		var to_node_id = position_to_node.get(to_key)
		
		if from_node_id and to_node_id:
			# Check edge length
			var distance = edge.p1.distance_to(edge.p2)
			if distance > map_config.max_edge_length:
				if DEBUG_ENABLED:
					print("Filtered out long edge:", from_node_id, "->", to_node_id, "distance:", distance)
				continue
			
			# Store all edges that pass length check
			all_valid_edges.append({"from": from_node_id, "to": to_node_id, "distance": distance})
			
			# Check type rules
			if should_connect_node_types(from_node_id, to_node_id):
				filtered_edges.append({"from": from_node_id, "to": to_node_id})
			elif DEBUG_ENABLED:
				print("Filtered out connection:", nodes[from_node_id].type, "->", nodes[to_node_id].type)
	
	if DEBUG_ENABLED:
		print("Original edges:", edges_data.size(), "Filtered edges:", filtered_edges.size())
	
	# Don't add extra edges - we'll handle dead-ends by making them mines
	# filtered_edges already contains what we want
	
	# Validate connectivity before applying filtered edges
	if validate_graph_connectivity(filtered_edges):
		# Create connections from filtered edges
		for edge_data in filtered_edges:
			create_connection(edge_data.from, edge_data.to)
	else:
		print("WARNING: Filtered edges would break connectivity, falling back to original edges")
		# Fallback to original edges to maintain connectivity
		for edge in edges_data:
			var from_key = str(edge.p1)
			var to_key = str(edge.p2)
			
			var from_node_id = position_to_node.get(from_key)
			var to_node_id = position_to_node.get(to_key)
			
			if from_node_id and to_node_id:
				create_connection(from_node_id, to_node_id)

func create_connection(from_node_id: String, to_node_id: String):
	"""Create a visual connection between two nodes"""
	if not nodes.has(from_node_id) or not nodes.has(to_node_id):
		return
	
	var from_pos = nodes[from_node_id].position
	var to_pos = nodes[to_node_id].position
	
	# Create a simple Line2D for the connection
	var line = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = map_config.edge_width
	line.default_color = map_config.edge_color
	line.z_index = map_config.edge_z_index  # Above background
	
	map_container.add_child(line)
	
	if DEBUG_ENABLED:
		print("Drew line from", from_pos, "to", to_pos, "with color", line.default_color, "z_index", line.z_index)
	
	# Store the connection
	edges.append({
		"from": from_node_id,
		"to": to_node_id,
		"line": line
	})
	
	# Add to node connection lists
	nodes[from_node_id].connections.append(to_node_id)
	nodes[to_node_id].connections.append(from_node_id)
	
	if DEBUG_ENABLED:
		print("Connected", from_node_id, "to", to_node_id)

func set_current_player_node(node_id: String):
	"""Set the current player position"""
	if not nodes.has(node_id):
		return
	
	# Reset previous current node
	if current_player_node != "" and nodes.has(current_player_node):
		var old_node = nodes[current_player_node]
		old_node.scene.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Full white, full opacity
	
	# Set new current node
	current_player_node = node_id
	var current_node = nodes[current_player_node]
	current_node.scene.modulate = Color(1.0, 0.843, 0.0, 1.0)  # Gold with full opacity
	
	if DEBUG_ENABLED:
		print("Player moved to:", node_id)

func _on_node_clicked(node_id: String):
	"""Handle node click - move player if connected"""
	if DEBUG_ENABLED:
		print("Node clicked:", node_id)
	
	if current_player_node == "":
		return
	
	# Check if clicked node is connected to current position
	var current_connections = nodes[current_player_node].connections
	
	if node_id == current_player_node:
		print("Already at this node!")
		return
	
	if node_id in current_connections:
		set_current_player_node(node_id)
	else:
		print("Cannot reach", node_id, "from current position")

func clear_map():
	"""Clear all existing map content"""
	# Remove all children except background
	for child in map_container.get_children():
		child.queue_free()
	
	nodes.clear()
	edges.clear()
	current_player_node = ""
	
	if DEBUG_ENABLED:
		print("Map cleared")

func get_available_moves() -> Array[String]:
	"""Get nodes the player can move to from current position"""
	if current_player_node == "" or not nodes.has(current_player_node):
		return []
	
	return nodes[current_player_node].connections
