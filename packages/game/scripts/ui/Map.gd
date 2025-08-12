extends Control
class_name MapController

const DEBUG_ENABLED: bool = true

# Core map components we need
const MAP_NODE_SCENE = preload("res://scenes/map/MapNodeScene.tscn")
const DELAUNAY_TRIANGULATOR = preload("res://scripts/map/DelaunayTriangulator.gd")

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
		GLog.info("=== SIMPLE MAP SYSTEM INITIALIZED ===")
	
	# Generate a simple test map
	generate_simple_map()

func generate_simple_map():
	"""Generate a simple map using Delaunay triangulation"""
	if DEBUG_ENABLED:
		GLog.info("Generating simple map with Delaunay triangulation...")
	
	# Clear existing content
	clear_map()
	
	# Generate some random node positions using config
	var node_positions = generate_random_positions(map_config.total_nodes)
	
	# Apply Delaunay triangulation to get connections
	var triangulation = DELAUNAY_TRIANGULATOR.triangulate(node_positions)
	var edges_data = DELAUNAY_TRIANGULATOR.triangulation_to_edges(triangulation)
	
	if DEBUG_ENABLED:
		GLog.debug("Generated " + str(node_positions.size()) + " nodes with " + str(edges_data.size()) + " connections")
	
	# First pass: create initial node assignments
	var initial_assignments = assign_node_types_to_positions(node_positions)
	
	# Create Delaunay edges and filter them
	var filtered_edges = get_filtered_edges(edges_data, node_positions)
	
	# Ensure graph connectivity before finalizing
	filtered_edges = ensure_graph_connectivity(filtered_edges, edges_data, node_positions)
	
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
		GLog.info("Simple map generation complete!")

func generate_random_positions(count: int) -> Array[Vector2]:
	"""Generate random positions within the map area"""
	var positions: Array[Vector2] = []
	var map_size = get_viewport().get_visible_rect().size
	var margin = 100.0
	
	# Use a simple grid with random offset to ensure good distribution
	var grid_cols = int(ceil(sqrt(count)))
	var grid_rows = int(ceil(count / float(grid_cols)))
	var cell_width = (map_size.x - margin * 2) / grid_cols
	var cell_height = (map_size.y - margin * 2) / grid_rows
	
	for i in range(count):
		var row = int(i / float(grid_cols))
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
				GLog.debug("Reassigning dead-end node " + str(i) + " from " + str(final_assignments[i].type) + " to mine")
				
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
		var node_pos = positions[i]
		var node_type_info = assignments[i]
		
		# Create the MapNodeScene instance
		var node_scene = MAP_NODE_SCENE.instantiate()
		map_container.add_child(node_scene)
		
		# Position it
		node_scene.position = node_pos - Vector2(16, 16)  # Center the node
		node_scene.z_index = map_config.node_z_index  # Nodes above edges
		
		# Create real MapNode with proper config
		var map_node = create_node_with_config(node_id, node_type_info.config, node_pos)
		node_scene.setup_node(node_id, map_node)

		# Optional debug: preview outcome for MINE/POI without persisting, show small badge
		if map_config.show_outcome_debug_badges and (map_node.type == MapNode.NodeType.MINE or map_node.type == MapNode.NodeType.POI):
			var preview = _preview_outcome_for_debug(map_node)
			var label_text = "D" if preview == "duel" else "E"
			var label_color = Color(1.0, 0.35, 0.35) if preview == "duel" else Color(0.35, 0.9, 0.6)
			if node_scene.has_method("update_debug_badge"):
				node_scene.update_debug_badge(label_text, label_color)
		
		# Connect click signal
		node_scene.node_clicked.connect(_on_node_clicked)
		
		# Store in our nodes dictionary
		nodes[node_id] = {
			"position": node_pos,
			"scene": node_scene,
			"connections": [],
			"map_node": map_node,
			"type": node_type_info.type
		}
		
		if DEBUG_ENABLED:
			GLog.debug("Created " + node_type_info.type_name + " node: " + node_id + " at " + str(node_pos))
			if map_config.show_outcome_debug_badges and (map_node.type == MapNode.NodeType.MINE or map_node.type == MapNode.NodeType.POI):
				GLog.debug("\tOutcome preview => " + _preview_outcome_for_debug(map_node))

func create_connections_from_filtered(filtered_edges: Array):
	"""Create connections from pre-filtered edges"""
	for edge in filtered_edges:
		var from_node_id = "node_" + str(edge.from_idx + 1)
		var to_node_id = "node_" + str(edge.to_idx + 1)
		create_connection(from_node_id, to_node_id)

# Old create_nodes_from_positions is replaced by new flow:
# get_filtered_edges -> reassign_dead_ends_as_mines -> create_nodes_with_assignments

func create_node_with_config(node_id: String, node_config: MapNodeConfig, node_pos: Vector2) -> MapNode:
	"""Create a real MapNode with proper configuration"""
	var map_node = MapNode.new(node_id, node_pos, node_config)
	# Default to KNOWN (visible, not clickable); we'll unlock adjacency later
	map_node.set_state(MapNode.NodeState.KNOWN)
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
	
	# Step 3: Find the furthest position from city for boss placement
	var boss_index = find_furthest_position_from_city(positions, city_index, edge_indices)
	
	# Step 4: Calculate how many interior nodes we need to assign (excluding boss)
	var interior_indices = []
	for i in range(positions.size()):
		if i != city_index and i not in edge_indices and i != boss_index:
			interior_indices.append(i)
	
	# Step 5: Distribute interior node types using MapConfig limits (excluding boss)
	var interior_assignments = distribute_interior_node_types_excluding_boss(interior_indices.size())
	
	# Step 6: Assign types to all positions
	var interior_assignment_index = 0
	for i in range(positions.size()):
		var assignment = {}
		
		if i == city_index:
			# Central city
			assignment.type = "city"
			assignment.type_name = "City"
			assignment.config = node_configs.city
		elif i == boss_index:
			# Furthest node becomes boss
			assignment.type = "boss"
			assignment.type_name = "Boss"
			assignment.config = node_configs.boss
		elif i in edge_indices:
			# Edge settlement
			assignment.type = "settlement"
			assignment.type_name = "Settlement" 
			assignment.config = node_configs.settlement
		else:
			# Interior content - use distributed assignments
			var interior_type = interior_assignments[interior_assignment_index]
			assignment.type = interior_type
			assignment.type_name = interior_type.capitalize()
			assignment.config = node_configs[interior_type]
			interior_assignment_index += 1
		
		assignments.append(assignment)
	
	if DEBUG_ENABLED:
		GLog.debug("Assigned city to index: " + str(city_index))
		GLog.debug("Assigned boss to index: " + str(boss_index) + " (furthest from city)")
		GLog.debug("Assigned settlements to indices: " + str(edge_indices))
		GLog.debug("Interior node distribution: " + str(_count_node_types(interior_assignments)))
	
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

func distribute_interior_node_types(interior_count: int) -> Array[String]:
	"""Distribute interior node types respecting MapConfig min/max limits"""
	var types = ["camp", "mine", "poi", "junction", "boss"]
	var assignments: Array[String] = []
	
	# Get min/max for each type from config
	var type_limits = {
		"camp": {"min": map_config.min_camps, "max": map_config.max_camps},
		"mine": {"min": map_config.min_mines, "max": map_config.max_mines},
		"poi": {"min": map_config.min_pois, "max": map_config.max_pois},
		"junction": {"min": map_config.min_junctions, "max": map_config.max_junctions},
		"boss": {"min": map_config.min_bosses, "max": map_config.max_bosses}
	}
	
	# Validate that we have enough slots for minimum requirements
	var total_mins = 0
	for type in types:
		total_mins += type_limits[type].min
	
	if total_mins > interior_count:
		if DEBUG_ENABLED:
			GLog.warn("Total minimum requirements (" + str(total_mins) + ") exceed interior slots (" + str(interior_count) + ")")
		# Scale down minimums proportionally
		for type in types:
			type_limits[type].min = int(type_limits[type].min * float(interior_count) / float(total_mins))
	
	# Step 1: Assign minimums for each type
	var type_counts = {}
	for type in types:
		type_counts[type] = type_limits[type].min
		for i in range(type_limits[type].min):
			assignments.append(type)
	
	# Step 2: Distribute remaining slots randomly within max limits
	var remaining_slots = interior_count - assignments.size()
	
	for i in range(remaining_slots):
		# Find types that haven't reached their maximum
		var available_types = []
		for type in types:
			if type_counts[type] < type_limits[type].max:
				available_types.append(type)
		
		if available_types.is_empty():
			# All types at max, break early
			break
		
		# Randomly pick from available types
		var chosen_type = available_types[SeedManager.get_map_random_int(0, available_types.size() - 1)]
		assignments.append(chosen_type)
		type_counts[chosen_type] += 1
	
	# Step 3: Shuffle the assignments to randomize placement
	for i in range(assignments.size()):
		var j = SeedManager.get_map_random_int(0, assignments.size() - 1)
		var temp = assignments[i]
		assignments[i] = assignments[j]
		assignments[j] = temp
	
	GLog.debug("Interior distribution for " + str(interior_count) + " slots: " + str(type_counts))
	
	return assignments

func _count_node_types(assignments: Array) -> Dictionary:
	"""Helper function to count node types in an assignment array"""
	var counts = {}
	for type in assignments:
		counts[type] = counts.get(type, 0) + 1
	return counts

func find_furthest_position_from_city(positions: Array[Vector2], city_index: int, edge_indices: Array) -> int:
	"""Find the position furthest from the city (excluding edges and city itself)"""
	var city_pos = positions[city_index]
	var furthest_index = -1
	var max_distance = -1.0
	
	for i in range(positions.size()):
		# Skip city, edge settlements, and invalid indices
		if i == city_index or i in edge_indices:
			continue
			
		var distance = positions[i].distance_to(city_pos)
		if distance > max_distance:
			max_distance = distance
			furthest_index = i
	
	GLog.debug("Boss placed at index " + str(furthest_index) + " with distance " + str(max_distance) + " from city")
	
	return furthest_index

func distribute_interior_node_types_excluding_boss(interior_count: int) -> Array[String]:
	"""Distribute interior node types respecting MapConfig min/max limits, excluding boss"""
	var types = ["camp", "mine", "poi", "junction"]  # Removed "boss" since it's predetermined
	var assignments: Array[String] = []
	
	# Get min/max for each type from config (excluding boss)
	var type_limits = {
		"camp": {"min": map_config.min_camps, "max": map_config.max_camps},
		"mine": {"min": map_config.min_mines, "max": map_config.max_mines},
		"poi": {"min": map_config.min_pois, "max": map_config.max_pois},
		"junction": {"min": map_config.min_junctions, "max": map_config.max_junctions}
	}
	
	# Validate that we have enough slots for minimum requirements
	var total_mins = 0
	for type in types:
		total_mins += type_limits[type].min
	
	if total_mins > interior_count:
		if DEBUG_ENABLED:
			GLog.warn("Total minimum requirements (" + str(total_mins) + ") exceed interior slots (" + str(interior_count) + ")")
		# Scale down minimums proportionally
		for type in types:
			type_limits[type].min = int(type_limits[type].min * float(interior_count) / float(total_mins))
	
	# Step 1: Assign minimums for each type
	var type_counts = {}
	for type in types:
		type_counts[type] = type_limits[type].min
		for i in range(type_limits[type].min):
			assignments.append(type)
	
	# Step 2: Distribute remaining slots randomly within max limits
	var remaining_slots = interior_count - assignments.size()
	
	for i in range(remaining_slots):
		# Find types that haven't reached their maximum
		var available_types = []
		for type in types:
			if type_counts[type] < type_limits[type].max:
				available_types.append(type)
		
		if available_types.is_empty():
			# All types at max, break early
			break
		
		# Randomly pick from available types
		var chosen_type = available_types[SeedManager.get_map_random_int(0, available_types.size() - 1)]
		assignments.append(chosen_type)
		type_counts[chosen_type] += 1
	
	# Step 3: Shuffle the assignments to randomize placement
	for i in range(assignments.size()):
		var j = SeedManager.get_map_random_int(0, assignments.size() - 1)
		var temp = assignments[i]
		assignments[i] = assignments[j]
		assignments[j] = temp
	
	GLog.debug("Interior distribution for " + str(interior_count) + " slots (excluding boss): " + str(type_counts))
	
	return assignments

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
			
			GLog.debug("Node " + str(node_id) + " has " + str(connection_count[node_id]) + " connections, needs " + str(needed) + " more")
			
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
				
				GLog.debug("Added edge for minimum connections: " + str(candidates[i].from) + " -> " + str(candidates[i].to))
	
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
		GLog.warn("Connectivity check failed: visited " + str(visited.size()) + " of " + str(nodes.size()) + " nodes")
	
	return all_connected

func ensure_graph_connectivity(filtered_edges: Array, _all_edges_data: Array, positions: Array[Vector2]) -> Array:
	"""Ensure all nodes are connected by adding minimum necessary edges"""
	# Convert positions to indices for easier lookup
	var position_to_index = {}
	for i in range(positions.size()):
		position_to_index[str(positions[i])] = i
	
	# Build current connectivity graph from filtered edges
	var connectivity_graph = {}
	for i in range(positions.size()):
		connectivity_graph[i] = []
	
	# Add filtered edges to connectivity graph
	for edge in filtered_edges:
		var from_idx = edge.from_idx
		var to_idx = edge.to_idx
		connectivity_graph[from_idx].append(to_idx)
		connectivity_graph[to_idx].append(from_idx)
	
	# Find connected components using BFS
	var visited = {}
	var components = []
	
	for i in range(positions.size()):
		if not visited.has(i):
			var component = []
			var queue = [i]
			visited[i] = true
			
			while not queue.is_empty():
				var current = queue.pop_front()
				component.append(current)
				
				for neighbor in connectivity_graph[current]:
					if not visited.has(neighbor):
						visited[neighbor] = true
						queue.append(neighbor)
			
			components.append(component)
	
	if DEBUG_ENABLED:
		var comp_sizes = []
		for comp in components:
			comp_sizes.append(comp.size())
		GLog.debug("Found " + str(components.size()) + " connected components with sizes: " + str(comp_sizes))
	
	# If we have more than one component, we need to connect them
	if components.size() > 1:
		var result_edges = filtered_edges.duplicate()
		
		# Find the largest component (usually contains the city)
		var largest_component = components[0]
		for comp in components:
			if comp.size() > largest_component.size():
				largest_component = comp
		
		# Connect all other components to the largest one
		for comp in components:
			if comp == largest_component:
				continue
			
			# Find the shortest edge between this component and the largest component
			var shortest_edge = null
			var shortest_distance = float('inf')
			
			for from_idx in comp:
				for to_idx in largest_component:
					var distance = positions[from_idx].distance_to(positions[to_idx])
					if distance < shortest_distance:
						shortest_distance = distance
						shortest_edge = {"from_idx": from_idx, "to_idx": to_idx, "distance": distance}
			
			if shortest_edge:
				result_edges.append(shortest_edge)
				GLog.debug("Connected component of size " + str(comp.size()) + " to main component with edge length " + str(shortest_distance))
		
		return result_edges
	
	return filtered_edges

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
				GLog.debug("Filtered out long edge: " + str(from_node_id) + " -> " + str(to_node_id) + " distance: " + str(distance))
				continue
			
			# Store all edges that pass length check
			all_valid_edges.append({"from": from_node_id, "to": to_node_id, "distance": distance})
			
			# Check type rules
			if should_connect_node_types(from_node_id, to_node_id):
				filtered_edges.append({"from": from_node_id, "to": to_node_id})
			else:
				GLog.debug("Filtered out connection: " + str(nodes[from_node_id].type) + " -> " + str(nodes[to_node_id].type))
	
	if DEBUG_ENABLED:
		GLog.debug("Original edges: " + str(edges_data.size()) + " Filtered edges: " + str(filtered_edges.size()))
	
	# Don't add extra edges - we'll handle dead-ends by making them mines
	# filtered_edges already contains what we want
	
	# Validate connectivity before applying filtered edges
	if validate_graph_connectivity(filtered_edges):
		# Create connections from filtered edges
		for edge_data in filtered_edges:
			create_connection(edge_data.from, edge_data.to)
	else:
		GLog.warn("Filtered edges would break connectivity, falling back to original edges")
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
	
	GLog.debug("Drew line from " + str(from_pos) + " to " + str(to_pos) + " with color " + str(line.default_color) + " z_index " + str(line.z_index))
	
	# Store the connection
	edges.append({
		"from": from_node_id,
		"to": to_node_id,
		"line": line
	})
	
	# Add to node connection lists
	nodes[from_node_id].connections.append(to_node_id)
	nodes[to_node_id].connections.append(from_node_id)
	
	GLog.info("Connected " + str(from_node_id) + " to " + str(to_node_id))

func set_current_player_node(node_id: String):
	"""Set the current player position and update node states"""
	if not nodes.has(node_id):
		GLog.error("Attempted to set current player node to non-existent node: " + node_id)
		return
	
	if DEBUG_ENABLED:
		GLog.debug("Setting current player node to: " + node_id)
	
	# Reset previous current node state
	if current_player_node != "" and nodes.has(current_player_node):
		var old_node = nodes[current_player_node]
		# Set old node to completed state (can revisit)
		old_node.map_node.set_state(MapNode.NodeState.COMPLETED)
		old_node.scene.refresh()
		if DEBUG_ENABLED:
			GLog.debug("Set previous node " + current_player_node + " to COMPLETED state")
	
	# By default, set all nodes to KNOWN (visible, not clickable) except completed ones
	for other_node_id in nodes.keys():
		if other_node_id != node_id:
			var other_node = nodes[other_node_id]
			if other_node.map_node.get_state() != MapNode.NodeState.COMPLETED:
				other_node.map_node.set_state(MapNode.NodeState.KNOWN)
				other_node.scene.refresh()
	
	# Set new current node
	current_player_node = node_id
	var current_node = nodes[current_player_node]
	
	# Update current node state to CURRENT (resource colors will be applied automatically)
	current_node.map_node.set_state(MapNode.NodeState.CURRENT)
	current_node.scene.refresh()
	
	# Ensure connected nodes are AVAILABLE for interaction
	for connected_node_id in current_node.connections:
		if nodes.has(connected_node_id):
			var connected_node = nodes[connected_node_id]
			# Don't change completed nodes back to available
			if connected_node.map_node.get_state() != MapNode.NodeState.COMPLETED:
				connected_node.map_node.set_state(MapNode.NodeState.AVAILABLE)
				connected_node.scene.refresh()
			if DEBUG_ENABLED:
				GLog.debug("Connected node " + connected_node_id + " is available")
	
	if DEBUG_ENABLED:
		GLog.info("Player moved to: " + node_id + " (type: " + str(current_node.map_node.get_type_name()) + ")")

func _on_node_clicked(node_id: String, _event: InputEvent):
	"""Handle node click - move player if connected"""
	GLog.info("✅ MAP RECEIVED CLICK: " + node_id)
	
	if current_player_node == "":
		GLog.error("No current player node set")
		return
	
	if not nodes.has(node_id):
		GLog.error("Clicked node " + node_id + " does not exist")
		return
	
	if not nodes.has(current_player_node):
		GLog.error("Current player node " + current_player_node + " does not exist")
		return
	
	# Get node info for debugging
	var clicked_node = nodes[node_id]
	var clicked_state = clicked_node.map_node.get_state()
	var clicked_interactive = clicked_node.map_node.is_interactive()
	
	if DEBUG_ENABLED:
		GLog.debug("Clicked node state: " + str(clicked_state) + ", interactive: " + str(clicked_interactive))
		GLog.debug("Current player at: " + current_player_node)
	
	# Check if clicked node is connected to current position
	var current_connections = nodes[current_player_node].connections
	
	if DEBUG_ENABLED:
		GLog.debug("Current connections: " + str(current_connections))
	
	if node_id == current_player_node:
		GLog.info("Already at this node!")
		return
	
	if node_id in current_connections:
		GLog.info("Moving from " + current_player_node + " to " + node_id)
		set_current_player_node(node_id)

		# Determine destination scene for this node and transition
		var destination_scene = _choose_destination_scene(nodes[node_id].map_node)
		if destination_scene != "":
			if DEBUG_ENABLED:
				GLog.info("Loading scene for node '" + node_id + "': " + destination_scene)
			SceneManager.load_scene_by_name(destination_scene)
		else:
			GLog.warn("No destination scene mapped for node: " + node_id)
	else:
		GLog.warn("Cannot reach " + node_id + " from current position " + current_player_node)

func _choose_destination_scene(map_node: MapNode) -> String:
	"""Map node type to scene with deterministic Event/Duel roll where applicable."""
	var t = map_node.type
	match t:
		MapNode.NodeType.CITY:
			return "city_hub"
		MapNode.NodeType.CAMP:
			return "camp"
		MapNode.NodeType.SETTLEMENT:
			return "shop"
		MapNode.NodeType.JUNCTION:
			return "junction"
		MapNode.NodeType.BOSS:
			return "duel"  # Boss is always a duel
		MapNode.NodeType.MINE, MapNode.NodeType.POI:
			var outcome = _get_or_generate_outcome(map_node)
			return outcome
		_:
			return ""

func _get_or_generate_outcome(map_node: MapNode) -> String:
	"""Deterministically choose 'duel' or 'event' for a node and persist choice for this run/map."""
	# Identify current map/region if available
	var current_map_id: String = "default_map"
	if GameManager and GameManager.game_data.has("current_map") and not str(GameManager.game_data.current_map).is_empty():
		current_map_id = str(GameManager.game_data.current_map)

	# Prepare storage in GameManager for outcomes
	if not GameManager.game_data.has("map_node_outcomes"):
		GameManager.game_data.map_node_outcomes = {}
	var all_outcomes: Dictionary = GameManager.game_data.map_node_outcomes
	if not all_outcomes.has(current_map_id):
		all_outcomes[current_map_id] = {}
	var map_outcomes: Dictionary = all_outcomes[current_map_id]

	# Return persisted outcome if present
	if map_outcomes.has(map_node.id):
		return map_outcomes[map_node.id]

	# Determine base chances, allowing override via config.custom_properties
	var duel_chance := 0.5
	if map_node.config and map_node.config.custom_properties.has("duel_chance"):
		duel_chance = float(map_node.config.custom_properties["duel_chance"])
	else:
		match map_node.type:
			MapNode.NodeType.MINE:
				duel_chance = 0.6
			MapNode.NodeType.POI:
				duel_chance = 0.4
			_:
				duel_chance = 0.5

	# Seed-independent deterministic roll based on master seed + map + node id
	var hash_input = str(SeedManager.get_seed_string()) + "|" + current_map_id + "|" + map_node.id
	var roll = float(abs(hash_input.hash()) % 100) / 100.0
	var outcome = "duel" if roll < duel_chance else "event"

	# Persist and return
	map_outcomes[map_node.id] = outcome
	all_outcomes[current_map_id] = map_outcomes
	GameManager.game_data.map_node_outcomes = all_outcomes
	return outcome

# Debug helper: compute outcome like _get_or_generate_outcome but do not persist
func _preview_outcome_for_debug(map_node: MapNode) -> String:
	var current_map_id: String = "default_map"
	if GameManager and GameManager.game_data.has("current_map") and not str(GameManager.game_data.current_map).is_empty():
		current_map_id = str(GameManager.game_data.current_map)

	var duel_chance := 0.5
	if map_node.config and map_node.config.custom_properties.has("duel_chance"):
		duel_chance = float(map_node.config.custom_properties["duel_chance"])
	else:
		match map_node.type:
			MapNode.NodeType.MINE:
				duel_chance = 0.6
			MapNode.NodeType.POI:
				duel_chance = 0.4
			_:
				duel_chance = 0.5

	var hash_input = str(SeedManager.get_seed_string()) + "|" + current_map_id + "|" + map_node.id
	var roll = float(abs(hash_input.hash()) % 100) / 100.0
	return "duel" if roll < duel_chance else "event"

func clear_map():
	"""Clear all existing map content"""
	# Remove all children except background
	for child in map_container.get_children():
		child.queue_free()
	
	nodes.clear()
	edges.clear()
	current_player_node = ""
	
	GLog.info("Map cleared")

func get_available_moves() -> Array[String]:
	"""Get nodes the player can move to from current position"""
	if current_player_node == "" or not nodes.has(current_player_node):
		return []
	
	return nodes[current_player_node].connections
