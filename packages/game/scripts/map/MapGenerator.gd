extends Node
class_name MapGenerator

const DEBUG_ENABLED: bool = true
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")
const ForceDirectedLayout = preload("res://scripts/map/ForceDirectedLayout.gd")

# Map layout configuration
@export var layout_config: MapLayoutConfig
@export var generation_seed: int = -1
@export var debug_show_all_nodes: bool = false

# Fallback values if no config is loaded
var default_max_nodes: int = 30
var default_min_nodes: int = 20

# The generated graph
var graph: Dictionary = {
	"nodes": {},  # Dictionary of node_id -> MapNode
	"edges": [],  # Array of MapEdge
	"player_position": "",  # Current player node ID
	"start_node": ""  # Starting node ID
}

# Player tracking for persistence
var current_player_node_id: String = ""
var visited_node_ids: Array[String] = []

# Available rules for generation
var rules: Array[GraphRule] = []

signal map_generated(graph_data: Dictionary)
signal node_discovered(node_id: String)
signal player_moved(from_node: String, to_node: String)

func _init():
	load_default_config()
	initialize_rules()

func load_default_config():
	# Try to load the default config
	var config_path = "res://data/map_layout_config.tres"
	if ResourceLoader.exists(config_path):
		layout_config = load(config_path) as MapLayoutConfig
		GLog.debug("Loaded map layout config from: " + config_path)
	else:
		# Create a default config if none exists
		layout_config = MapLayoutConfig.new()
		GLog.debug("Created default map layout config")
	
	# Validate the config
	var warnings = layout_config.validate_config()
	for warning in warnings:
		GLog.warn("MapLayoutConfig: " + warning)

func initialize_rules():
	rules.clear()
	
	if not layout_config:
		load_default_config()
	
	# Create rule instances with config
	var linear_rule = GraphRule.LinearExtensionRule.new()
	linear_rule.weight = layout_config.linear_weight
	linear_rule.max_applications = layout_config.linear_max_applications
	linear_rule.config = layout_config  # Pass config reference
	
	var branch_rule = GraphRule.BranchCreationRule.new()
	branch_rule.weight = layout_config.branch_weight
	branch_rule.max_applications = layout_config.branch_max_applications
	branch_rule.config = layout_config
	
	var destination_rule = GraphRule.DestinationPlacementRule.new()
	destination_rule.weight = layout_config.destination_weight
	destination_rule.max_applications = layout_config.destination_max_applications
	destination_rule.config = layout_config
	
	# Add minimum connection rule (cleanup rule, not applied during generation)
	var min_connection_rule = GraphRule.MinimumConnectionRule.new()
	min_connection_rule.config = layout_config
	
	rules.append(linear_rule)
	rules.append(branch_rule)
	rules.append(destination_rule)
	rules.append(min_connection_rule)
	
	GLog.debug("Initialized " + str(rules.size()) + " graph generation rules with config")

func generate_map(seed: int = -1) -> Dictionary:
	if seed != -1:
		generation_seed = seed
	else:
		generation_seed = SeedManager.get_map_random_int(0, 2147483647)
	
	GLog.debug("Generating map with seed: " + str(generation_seed))
	
	# Reset graph
	graph = {
		"nodes": {},
		"edges": [],
		"player_position": "",
		"start_node": "",
		"generation_seed": generation_seed
	}
	
	# Reset rule counters
	for rule in rules:
		rule.reset()
	
	# Create starting node
	create_start_node()
	
	# Generate the rest of the map
	var generation_steps = 0
	var max_steps = 50  # Prevent infinite loops
	
	while should_continue_generation() and generation_steps < max_steps:
		apply_random_rule()
		generation_steps += 1
	
	# Post-process the graph
	post_process_graph()
	
	GLog.debug("Map generation complete: " + str(graph.nodes.size()) + " nodes, " + str(graph.edges.size()) + " edges")
	map_generated.emit(graph)
	return graph

func create_start_node():
	var start_id = "start_camp"
	# Position start node using config
	var start_pos = layout_config.get_start_position() if layout_config else Vector2(192, 360)
	var start_node = MapNode.new(start_id, MapNode.NodeType.CAMP, start_pos)
	start_node.discovered = true
	start_node.visited = true
	
	graph.nodes[start_id] = start_node
	graph.start_node = start_id
	graph.player_position = start_id
	current_player_node_id = start_id
	visited_node_ids.clear()
	visited_node_ids.append(start_id)
	
	GLog.debug("Created starting node: " + start_id)

func create_city_node(city_name: String, city_position: Vector2):
	var city_id = "city_" + city_name.to_lower().replace(" ", "_")
	var city_node = MapNode.new(city_id, MapNode.NodeType.CITY, city_position)
	city_node.discovered = true
	city_node.visited = false
	city_node.properties["city_name"] = city_name
	
	graph.nodes[city_id] = city_node
	graph.start_node = city_id
	graph.player_position = city_id
	current_player_node_id = city_id
	visited_node_ids.clear()
	visited_node_ids.append(city_id)
	
	GLog.debug("Created city node: " + city_name + " at " + str(city_position))

func should_continue_generation() -> bool:
	var node_count = graph.nodes.size()
	var min_nodes = layout_config.min_nodes if layout_config else default_min_nodes
	var max_nodes = layout_config.max_nodes if layout_config else default_max_nodes
	
	# Always continue if we haven't met minimum
	if node_count < min_nodes:
		return true
	
	# Stop if we've reached maximum
	if node_count >= max_nodes:
		return false
	
	# Continue with decreasing probability as we approach max
	var progress = float(node_count - min_nodes) / float(max_nodes - min_nodes)
	var continue_chance = 1.0 - (progress * progress)  # Quadratic decay
	
	return SeedManager.get_map_random_float() < continue_chance

func apply_random_rule() -> bool:
	# Calculate total weight
	var total_weight = 0.0
	var applicable_rules: Array[GraphRule] = []
	
	for rule in rules:
		if rule.can_apply(graph):
			applicable_rules.append(rule)
			total_weight += rule.weight
	
	if applicable_rules.is_empty():
		return false
	
	# Select rule based on weights
	var random_value = SeedManager.get_map_random_float() * total_weight
	var current_weight = 0.0
	
	for rule in applicable_rules:
		current_weight += rule.weight
		if random_value <= current_weight:
			return try_apply_rule(rule)
	
	return false

func try_apply_rule(rule: GraphRule) -> bool:
	# Find potential matches for this rule
	var matches = find_rule_matches(rule)
	
	if matches.is_empty():
		return false
	
	# Apply rule to random match
	var match = matches[SeedManager.get_map_random_int(0, matches.size() - 1)]
	return rule.apply(graph, match)

func find_rule_matches(rule: GraphRule) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	
	# This is simplified - in a full implementation, you'd have more
	# sophisticated pattern matching based on the rule type
	
	if rule is GraphRule.LinearExtensionRule:
		# Find nodes with few connections that can be extended
		for node_id in graph.nodes:
			var node = graph.nodes[node_id]
			if node.connections.size() <= 2:
				matches.append({"from_node": node_id})
	
	elif rule is GraphRule.BranchCreationRule:
		# Find junctions that can have branches added
		for node_id in graph.nodes:
			var node = graph.nodes[node_id]
			if node.type == MapNode.NodeType.JUNCTION and node.connections.size() < 3:
				matches.append({"junction_node": node_id})
	
	elif rule is GraphRule.DestinationPlacementRule:
		# Find junctions that can be converted to destinations
		for node_id in graph.nodes:
			var node = graph.nodes[node_id]
			if node.type == MapNode.NodeType.JUNCTION and node.connections.size() >= 1:
				matches.append({"junction_node": node_id})
	
	return matches

func post_process_graph():
	# Ensure connectivity
	ensure_graph_connectivity()
	
	# Apply minimum connections to prevent dead ends
	apply_minimum_connections()
	
	# Balance node types
	balance_node_types()
	
	# Enforce connection limits
	enforce_connection_limits()
	
	# Apply force-directed layout if enabled
	if layout_config and layout_config.physics_enabled:
		apply_force_directed_layout()
	
	# Set up fog of war (only start node discovered)
	setup_fog_of_war()

func ensure_graph_connectivity():
	# Enhanced connectivity check - ensure all nodes are reachable from start
	var reachable = find_reachable_nodes(graph.start_node)
	var all_nodes = graph.nodes.keys()
	
	for node_id in all_nodes:
		if node_id not in reachable:
			# Find the best local connection instead of just nearest
			var best_connection = find_best_local_connection(node_id, reachable)
			if best_connection != "":
				connect_nodes(node_id, best_connection)
				GLog.debug("Connected isolated node " + node_id + " to " + best_connection)
				# Update reachable list
				reachable.append(node_id)

func find_reachable_nodes(start_node: String) -> Array[String]:
	var visited: Array[String] = []
	var to_visit: Array[String] = [start_node]
	
	while not to_visit.is_empty():
		var current = to_visit.pop_front()
		if current in visited:
			continue
			
		visited.append(current)
		
		# Add connected nodes
		if graph.nodes.has(current):
			for connected in graph.nodes[current].connections:
				if connected not in visited:
					to_visit.append(connected)
	
	return visited

func find_nearest_node(from_node_id: String, candidate_nodes: Array[String]) -> String:
	if candidate_nodes.is_empty() or not graph.nodes.has(from_node_id):
		return ""
	
	var from_node = graph.nodes[from_node_id]
	var min_distance = INF
	var nearest_id = ""
	
	for candidate_id in candidate_nodes:
		if graph.nodes.has(candidate_id):
			var candidate_node = graph.nodes[candidate_id]
			var distance = from_node.position.distance_to(candidate_node.position)
			if distance < min_distance:
				min_distance = distance
				nearest_id = candidate_id
	
	return nearest_id

func find_best_local_connection(from_node_id: String, candidate_nodes: Array[String]) -> String:
	"""Find the best connection prioritizing local proximity and reasonable distances"""
	if candidate_nodes.is_empty() or not graph.nodes.has(from_node_id):
		return ""
	
	var from_node = graph.nodes[from_node_id]
	var max_reasonable_distance = layout_config.connection_max_distance * 0.7 if layout_config else 175.0
	var preferred_distance = layout_config.spacing_max if layout_config else 150.0
	
	# First, try to find nodes within reasonable distance
	var local_candidates: Array[String] = []
	for candidate_id in candidate_nodes:
		if graph.nodes.has(candidate_id):
			var candidate_node = graph.nodes[candidate_id]
			var distance = from_node.position.distance_to(candidate_node.position)
			
			# Only consider nodes within reasonable distance
			if distance <= max_reasonable_distance:
				local_candidates.append(candidate_id)
	
	# If we have local candidates, pick the best one (closest to preferred distance)
	if not local_candidates.is_empty():
		var best_id = ""
		var best_score = INF
		
		for candidate_id in local_candidates:
			var candidate_node = graph.nodes[candidate_id]
			var distance = from_node.position.distance_to(candidate_node.position)
			
			# Score based on how close to preferred distance (lower is better)
			var distance_score = abs(distance - preferred_distance)
			
			# Bonus for nodes with fewer connections (avoid creating hubs)
			var connection_penalty = candidate_node.connections.size() * 20.0
			
			var total_score = distance_score + connection_penalty
			
			if total_score < best_score:
				best_score = total_score
				best_id = candidate_id
		
		return best_id
	else:
		# Fallback to nearest node if no local candidates
		GLog.debug("No local connections found for " + from_node_id + ", using nearest fallback")
		return find_nearest_node(from_node_id, candidate_nodes)

func edge_exists(node_a: String, node_b: String) -> bool:
	"""Check if an edge already exists between two nodes (bidirectional)"""
	for edge in graph.edges:
		if (edge.from_node == node_a and edge.to_node == node_b) or \
		   (edge.from_node == node_b and edge.to_node == node_a):
			return true
	return false

func connect_nodes(node_a: String, node_b: String):
	if not graph.nodes.has(node_a) or not graph.nodes.has(node_b):
		return
	
	# Check if edge already exists to prevent duplicates
	if edge_exists(node_a, node_b):
		GLog.debug("Skipping duplicate edge: " + node_a + " <-> " + node_b)
		return
	
	# Check if they're already connected in node connection lists
	if graph.nodes[node_a].is_connected_to(node_b):
		GLog.debug("Nodes already connected in graph: " + node_a + " <-> " + node_b)
		return
	
	# Use config for distance limits
	var distance = graph.nodes[node_a].position.distance_to(graph.nodes[node_b].position)
	var max_distance = layout_config.connection_max_distance if layout_config else 250.0
	var min_distance = layout_config.connection_min_distance if layout_config else 60.0
	
	if distance > max_distance:
		if layout_config and layout_config.cleanup_remove_long_connections:
			GLog.debug("Skipping long connection between " + node_a + " and " + node_b + " (distance: " + str(distance) + ")")
			return
	
	if distance < min_distance:
		GLog.debug("Skipping short connection between " + node_a + " and " + node_b + " (distance: " + str(distance) + ")")
		return
	
	# Create edge  
	var travel_time = SeedManager.get_map_random_int(2, 4)
	var difficulty = SeedManager.get_map_random_int(1, 3)
	var edge = MapEdge.new(node_a, node_b, travel_time, difficulty)
	graph.edges.append(edge)
	
	# Update node connections
	graph.nodes[node_a].connect_to(node_b)
	graph.nodes[node_b].connect_to(node_a)
	
	GLog.debug("Connected " + node_a + " to " + node_b + " (distance: " + str(distance) + ")")

func balance_node_types():
	# Ensure we have at least one of each important type
	var type_counts = {}
	
	for node_id in graph.nodes:
		var node_type = graph.nodes[node_id].type
		type_counts[node_type] = type_counts.get(node_type, 0) + 1
	
	# Ensure at least one settlement and one mine
	if type_counts.get(MapNode.NodeType.SETTLEMENT, 0) == 0:
		convert_random_junction_to_type(MapNode.NodeType.SETTLEMENT)
	
	if type_counts.get(MapNode.NodeType.MINE, 0) == 0:
		convert_random_junction_to_type(MapNode.NodeType.MINE)

func convert_random_junction_to_type(target_type: MapNode.NodeType):
	var junctions = []
	
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		if node.type == MapNode.NodeType.JUNCTION:
			junctions.append(node_id)
	
	if not junctions.is_empty():
		var junction_id = junctions[SeedManager.get_map_random_int(0, junctions.size() - 1)]
		var junction = graph.nodes[junction_id]
		junction.type = target_type
		junction.id = MapNode.NodeType.keys()[target_type].to_lower() + "_" + str(Time.get_ticks_msec())
		junction._init(junction.id, target_type, junction.position)
		
		GLog.debug("Converted junction " + junction_id + " to " + junction.get_type_name())

func setup_fog_of_war():
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		if node_id == graph.start_node:
			node.discovered = true
			node.visited = true
		elif debug_show_all_nodes:
			# Debug mode: show all nodes but mark them as unvisited
			node.discovered = true
			node.visited = false
		else:
			node.discovered = false
			node.visited = false

func enforce_connection_limits():
	"""Ensure no node exceeds the maximum connection limit"""
	if not layout_config:
		return
		
	var max_connections = layout_config.cleanup_max_connections_per_node
	
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		if node.connections.size() > max_connections:
			GLog.debug("Node " + node_id + " has " + str(node.connections.size()) + " connections, limiting to " + str(max_connections))
			
			# Sort connections by distance and keep only the closest ones
			var connections_with_distance = []
			for connected_id in node.connections:
				if graph.nodes.has(connected_id):
					var distance = node.position.distance_to(graph.nodes[connected_id].position)
					connections_with_distance.append({"id": connected_id, "distance": distance})
			
			connections_with_distance.sort_custom(func(a, b): return a.distance < b.distance)
			
			# Keep only the closest connections
			var new_connections = []
			for i in range(min(max_connections, connections_with_distance.size())):
				new_connections.append(connections_with_distance[i].id)
			
			# Remove excess connections
			for connected_id in node.connections:
				if connected_id not in new_connections:
					remove_connection(node_id, connected_id)
			
			# Clear and rebuild connections array (can't assign directly to Resource property)
			node.connections.clear()
			for connection in new_connections:
				node.connections.append(connection)

func remove_connection(node_a: String, node_b: String):
	"""Remove a connection between two nodes"""
	if graph.nodes.has(node_a):
		graph.nodes[node_a].connections.erase(node_b)
	if graph.nodes.has(node_b):
		graph.nodes[node_b].connections.erase(node_a)
	
	# Remove the edge
	for i in range(graph.edges.size() - 1, -1, -1):
		var edge = graph.edges[i]
		if (edge.from_node == node_a and edge.to_node == node_b) or \
		   (edge.from_node == node_b and edge.to_node == node_a):
			graph.edges.remove_at(i)

func is_position_valid_for_spacing(new_pos: Vector2, exclude_node_id: String = "") -> bool:
	"""Check if a position maintains minimum spacing from all existing nodes"""
	if not layout_config:
		return true
	
	var min_spacing = layout_config.spacing_min
	
	for node_id in graph.nodes:
		if node_id == exclude_node_id:
			continue
		
		var node = graph.nodes[node_id]
		var distance = new_pos.distance_to(node.position)
		
		if distance < min_spacing:
			return false
	
	return true

func find_valid_position_with_spacing(base_pos: Vector2, preferred_angle: float, preferred_distance: float, source_node_id: String = "") -> Vector2:
	"""Find a valid position that respects spacing constraints"""
	if not layout_config:
		return base_pos
	
	var min_spacing = layout_config.spacing_min
	var max_distance = layout_config.spacing_max
	var auto_adjust = layout_config.bounds_auto_adjust_spacing
	
	# Try the preferred position first
	if is_position_valid_for_spacing(base_pos, source_node_id):
		return base_pos
	
	# If auto-adjust is enabled, try different distances and angles
	if auto_adjust:
		var max_attempts = 10
		var angle_step = PI / 6  # 30 degrees
		
		for attempt in range(max_attempts):
			# Try different angles around the preferred angle
			for angle_offset in [0, angle_step, -angle_step, angle_step * 2, -angle_step * 2]:
				var test_angle = preferred_angle + angle_offset
				
				# Try different distances (start at preferred, decrease if needed)
				var distance = preferred_distance
				while distance >= min_spacing:
					var test_pos = base_pos + Vector2(cos(test_angle), sin(test_angle)) * distance
					test_pos = layout_config.clamp_to_bounds(test_pos)
					
					if is_position_valid_for_spacing(test_pos, source_node_id):
						return test_pos
					
					distance *= 0.9  # Reduce distance by 10%
		
		GLog.warn("Could not find valid position with spacing constraints, using fallback")
	
	# Fallback: return the clamped base position even if it violates spacing
	return layout_config.clamp_to_bounds(base_pos)

# Player movement and exploration
func move_player_to_node(target_node_id: String) -> bool:
	if not graph.nodes.has(target_node_id):
		GLog.warn("Cannot move to non-existent node: " + target_node_id)
		return false
	
	var current_node = graph.nodes[graph.player_position]
	var target_node = graph.nodes[target_node_id]
	
	# Check if nodes are connected
	if not current_node.is_connected_to(target_node_id):
		GLog.warn("Cannot move to unconnected node: " + target_node_id)
		return false
	
	# Move player
	var old_position = graph.player_position
	graph.player_position = target_node_id
	current_player_node_id = target_node_id
	
	# Handle discovery and visitation
	target_node.visit()
	if target_node_id not in visited_node_ids:
		visited_node_ids.append(target_node_id)
	discover_adjacent_nodes(target_node_id)
	
	player_moved.emit(old_position, target_node_id)
	GLog.debug("Player moved from " + old_position + " to " + target_node_id)
	
	return true

func discover_adjacent_nodes(node_id: String):
	if not graph.nodes.has(node_id):
		return
	
	var node = graph.nodes[node_id]
	
	for connected_id in node.connections:
		var connected_node = graph.nodes[connected_id]
		if not connected_node.discovered:
			connected_node.discover()
			node_discovered.emit(connected_id)

func get_current_player_node() -> MapNode:
	return graph.nodes.get(graph.player_position, null)

func get_available_moves() -> Array[String]:
	var current_node = get_current_player_node()
	if not current_node:
		return []
	
	var available: Array[String] = []
	
	for connected_id in current_node.connections:
		var connected_node = graph.nodes[connected_id]
		if connected_node.discovered:  # Can only move to discovered nodes
			available.append(connected_id)
	
	return available

func get_graph_data() -> Dictionary:
	return graph.duplicate()

# Serialization methods for map persistence
func get_serializable_data() -> Dictionary:
	"""Get map data that can be stored and restored."""
	var serializable_nodes = {}
	
	# Serialize each node
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		serializable_nodes[node_id] = {
			"type": node.type,
			"position": [node.position.x, node.position.y],
			"connections": node.connections.duplicate(),
			"discovered": node.discovered,
			"visited": node.visited
		}
	
	var serializable_edges = []
	for edge in graph.edges:
		serializable_edges.append({
			"from": edge.from_node,
			"to": edge.to_node,
			"travel_time": edge.travel_time,
			"difficulty": edge.difficulty
		})
	
	return {
		"nodes": serializable_nodes,
		"edges": serializable_edges,
		"player_position": graph.player_position,
		"start_node": graph.start_node,
		"generation_seed": graph.get("generation_seed", generation_seed),
		"max_nodes": layout_config.max_nodes if layout_config else default_max_nodes,
		"min_nodes": layout_config.min_nodes if layout_config else default_min_nodes
	}

func load_from_serializable_data(data: Dictionary):
	"""Restore map from serialized data."""
	if not data.has("nodes") or not data.has("edges"):
		GLog.error("Invalid serializable data - missing nodes or edges")
		return
		
	# Clear current graph
	graph = {
		"nodes": {},
		"edges": [],
		"player_position": "",
		"start_node": ""
	}
	
	# Restore generation parameters to config if available
	if data.has("max_nodes") and layout_config:
		layout_config.max_nodes = data.max_nodes
	if data.has("min_nodes") and layout_config:
		layout_config.min_nodes = data.min_nodes
	if data.has("generation_seed"):
		generation_seed = data.generation_seed
		
	# Restore nodes
	for node_id in data.nodes:
		var node_data = data.nodes[node_id]
		var position = Vector2(node_data.position[0], node_data.position[1])
		var node = MapNode.new(node_id, node_data.type, position)
		
		node.connections = node_data.connections.duplicate()
		node.discovered = node_data.discovered
		node.visited = node_data.visited
		
		graph.nodes[node_id] = node
	
	# Restore edges
	for edge_data in data.edges:
		var travel_time = edge_data.get("travel_time", 2)
		var difficulty = edge_data.get("difficulty", 1)
		var edge = MapEdge.new(edge_data.from, edge_data.to, travel_time, difficulty)
		graph.edges.append(edge)
	
	# Restore graph properties
	graph.player_position = data.player_position
	graph.start_node = data.start_node
	graph.generation_seed = data.get("generation_seed", generation_seed)
	
	GLog.debug("Map restored from serializable data: " + str(graph.nodes.size()) + " nodes, " + str(graph.edges.size()) + " edges")

func apply_minimum_connections():
	"""Apply the minimum connection rule to prevent dead ends"""
	# Find the minimum connection rule
	var min_connection_rule = null
	for rule in rules:
		if rule is GraphRule.MinimumConnectionRule:
			min_connection_rule = rule
			break
	
	if min_connection_rule:
		GLog.debug("Applying minimum connection rule...")
		min_connection_rule.apply(graph, {})
	else:
		GLog.warn("No minimum connection rule found")

func apply_force_directed_layout():
	"""Apply force-directed layout to optimize node positions"""
	GLog.debug("Applying force-directed layout optimization...")
	
	var layout_optimizer = ForceDirectedLayout.new()
	layout_optimizer.setup(layout_config)
	
	# Apply the layout optimization
	graph = layout_optimizer.apply_layout(graph)
	
	GLog.debug("Force-directed layout optimization complete")

func generate_map_for_region(config: MapRegionConfig, seed: int) -> Dictionary:
	"""Generate a complete map for a specific region"""
	GLog.debug("Generating map for region: " + config.region_id)
	
	# Set up configuration
	layout_config = MapLayoutConfig.new()
	layout_config.min_nodes = config.min_nodes
	layout_config.max_nodes = config.max_nodes
	layout_config.viewport_size = config.region_bounds
	
	# Initialize RNG with region-specific seed
	generation_seed = seed
	SeedManager.map_rng.seed = seed
	
	# Reset graph
	graph = {
		"nodes": {},
		"edges": [],
		"player_position": "",
		"start_node": "",
		"generation_seed": generation_seed,
		"region_id": config.region_id
	}
	
	# Reset rule counters
	for rule in rules:
		rule.reset()
	
	# Create city node at center
	create_city_node(config.city_name, config.city_position)
	
	# Generate nodes radiating from city
	generate_radial_paths_from_city(config)
	
	# Add boss node at edge
	add_boss_node(config)
	
	# Post-process the graph
	post_process_graph()
	
	# Ensure player position sync
	ensure_player_position_sync()
	
	GLog.debug("Region map complete: " + str(graph.nodes.size()) + " nodes, " + str(graph.edges.size()) + " edges")
	
	# Return serializable data
	return get_serializable_data()

func generate_radial_paths_from_city(config: MapRegionConfig):
	"""Generate paths radiating outward from the central city"""
	var city_id = graph.start_node
	var city_pos = graph.nodes[city_id].position
	
	# Create 3-5 main paths from city
	var num_paths = SeedManager.get_map_random_int(3, 5)
	var angle_step = TAU / num_paths
	var base_angle = SeedManager.get_map_random_float() * TAU
	
	for i in range(num_paths):
		var angle = base_angle + (i * angle_step)
		var path_length = SeedManager.get_map_random_int(3, 5)
		var last_node_id = city_id
		
		for j in range(path_length):
			var distance = 80 + (j * 60) + SeedManager.get_map_random_float() * 30
			var angle_variance = (SeedManager.get_map_random_float() - 0.5) * 0.3
			var final_angle = angle + angle_variance
			
			var new_pos = city_pos + Vector2(cos(final_angle), sin(final_angle)) * distance
			new_pos = find_valid_position_with_spacing(new_pos, final_angle, distance, last_node_id)
			
			# Clamp to bounds
			new_pos.x = clamp(new_pos.x, 50, config.region_bounds.x - 50)
			new_pos.y = clamp(new_pos.y, 50, config.region_bounds.y - 50)
			
			# Create node with region-appropriate type
			var node_type = config.get_random_node_type(SeedManager.map_rng)
			var node_id = MapNode.NodeType.keys()[node_type].to_lower() + "_" + str(Time.get_ticks_msec()) + "_" + str(i) + "_" + str(j)
			var new_node = MapNode.new(node_id, node_type, new_pos)
			
			graph.nodes[node_id] = new_node
			
			# Connect to previous node
			connect_nodes(last_node_id, node_id)
			
			# Occasionally create branches or connections
			if j > 0 and SeedManager.get_map_random_float() < 0.3:
				create_branch_connection(node_id, config)
			
			last_node_id = node_id

func create_branch_connection(from_node_id: String, config: MapRegionConfig):
	"""Create a branch or cross-connection from a node"""
	var from_node = graph.nodes[from_node_id]
	
	# Find nearby nodes to potentially connect to
	var max_distance = 150.0
	var candidates = []
	
	for node_id in graph.nodes:
		if node_id == from_node_id:
			continue
		var node = graph.nodes[node_id]
		var distance = from_node.position.distance_to(node.position)
		
		if distance <= max_distance and not from_node.is_connected_to(node_id):
			# Don't connect to the city directly from branches
			if node.type != MapNode.NodeType.CITY:
				candidates.append(node_id)
	
	# Connect to a random candidate if available
	if not candidates.is_empty():
		var target_id = candidates[SeedManager.get_map_random_int(0, candidates.size() - 1)]
		connect_nodes(from_node_id, target_id)

func add_boss_node(config: MapRegionConfig):
	"""Add the boss node at the edge of the map"""
	var boss_pos = config.get_boss_position()
	var boss_id = "boss_" + config.region_id
	
	var boss_node = MapNode.new(boss_id, MapNode.NodeType.BOSS, boss_pos)
	boss_node.properties["boss_name"] = config.boss_name
	boss_node.properties["boss_enemy_id"] = config.boss_enemy_id
	
	graph.nodes[boss_id] = boss_node
	
	# Connect boss to the furthest nodes from city
	var city_pos = graph.nodes[graph.start_node].position
	var far_nodes = []
	
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		if node.type != MapNode.NodeType.CITY and node.type != MapNode.NodeType.BOSS:
			var distance_from_city = node.position.distance_to(city_pos)
			if distance_from_city > config.boss_distance_from_city * 0.7:
				far_nodes.append({"id": node_id, "distance": distance_from_city})
	
	# Sort by distance and connect to 2-3 furthest nodes
	far_nodes.sort_custom(func(a, b): return a.distance > b.distance)
	var connections_made = 0
	var max_connections = min(3, far_nodes.size())
	
	for i in range(min(max_connections, far_nodes.size())):
		connect_nodes(far_nodes[i].id, boss_id)
		connections_made += 1
	
	GLog.debug("Boss node added with " + str(connections_made) + " connections")

func ensure_player_position_sync():
	"""Ensure player position is always synchronized"""
	# Make sure graph.player_position matches current_player_node_id
	if current_player_node_id.is_empty() or not graph.nodes.has(current_player_node_id):
		current_player_node_id = graph.start_node
	
	graph.player_position = current_player_node_id
	
	# Validate visited nodes
	var valid_visited: Array[String] = []
	for node_id in visited_node_ids:
		if graph.nodes.has(node_id):
			valid_visited.append(node_id)
	visited_node_ids = valid_visited
	
	# Ensure start node is in visited list
	if graph.start_node not in visited_node_ids:
		visited_node_ids.insert(0, graph.start_node)
	
	GLog.debug("Player position synced: " + current_player_node_id)
