extends Node
class_name MapGenerator

const DEBUG_ENABLED: bool = true
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

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
		GLog.warning("MapLayoutConfig: " + warning)

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
	
	rules.append(linear_rule)
	rules.append(branch_rule)
	rules.append(destination_rule)
	
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
	visited_node_ids = [start_id]
	
	GLog.debug("Created starting node: " + start_id)

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
	
	# Balance node types
	balance_node_types()
	
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

func connect_nodes(node_a: String, node_b: String):
	if not graph.nodes.has(node_a) or not graph.nodes.has(node_b):
		return
	
	# Check if they're already connected
	if graph.nodes[node_a].is_connected_to(node_b):
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

# Player movement and exploration
func move_player_to_node(target_node_id: String) -> bool:
	if not graph.nodes.has(target_node_id):
		GLog.warning("Cannot move to non-existent node: " + target_node_id)
		return false
	
	var current_node = graph.nodes[graph.player_position]
	var target_node = graph.nodes[target_node_id]
	
	# Check if nodes are connected
	if not current_node.is_connected_to(target_node_id):
		GLog.warning("Cannot move to unconnected node: " + target_node_id)
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
