extends Node
class_name MapGenerator

const DEBUG_ENABLED: bool = false
"""
Note: Classes are globally available via class_name; avoid shadowing preloads.
"""

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
var discovered_node_ids: Array[String] = []

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
		GLog.debug("Config viewport_size: " + str(layout_config.viewport_size))
		GLog.debug("Config spacing_min: " + str(layout_config.spacing_min) + ", spacing_max: " + str(layout_config.spacing_max))
	else:
		# Create a default config if none exists
		layout_config = MapLayoutConfig.new()
		GLog.debug("Created default map layout config")
		GLog.debug("Fallback viewport_size: " + str(layout_config.viewport_size))
	
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

func generate_map(gen_seed: int = -1) -> Dictionary:
	if gen_seed != -1:
		generation_seed = gen_seed
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
	
	# Check if planar graph generation is enabled
	if layout_config and layout_config.use_planar_graph_generation:
		return generate_planar_map()
	else:
		return generate_traditional_map()

func generate_traditional_map() -> Dictionary:
	# Fallback to planar generation if traditional path is called
	GLog.warn("Traditional map generation called - redirecting to planar generation")
	return generate_planar_map()

func generate_planar_map() -> Dictionary:
	GLog.debug("Using planar graph generation with Delaunay triangulation")
	
	# Create starting node
	create_start_node()
	
	# Generate additional nodes using Poisson Disk Sampling for positioning
	generate_nodes_with_poisson_sampling()
	
	# Create Delaunay triangulation for planar connectivity
	apply_delaunay_triangulation()
	
	# Prune edges to match game design requirements
	prune_triangulation_edges()
	
	# Post-process with planar graph constraints
	GLog.debug("Starting planar post-processing...")
	post_process_planar_graph()
	GLog.debug("Planar post-processing complete")
	
	GLog.debug("Planar map generation complete: " + str(graph.nodes.size()) + " nodes, " + str(graph.edges.size()) + " edges")
	
	# Validate planarity
	if DEBUG_ENABLED:
		var planarity_report = PlanarGraphValidator.generate_planarity_report(graph)
		GLog.debug("Planarity report: " + str(planarity_report))
	
	map_generated.emit(graph)
	return graph

func create_start_node():
	var start_id = "start_camp"
	# Position start node using config
	var start_pos = layout_config.get_start_position() if layout_config else Vector2(192, 360)
	var start_config = MapNodeRegistry.get_default_config_for_type(1)  # CAMP
	var start_node = MapNodeRegistry.create_node(start_id, start_config, start_pos)
	start_node.set_state(MapNode.NodeState.CURRENT)
	
	graph.nodes[start_id] = start_node
	graph.start_node = start_id
	graph.player_position = start_id
	current_player_node_id = start_id
	visited_node_ids.clear()
	visited_node_ids.append(start_id)
	discovered_node_ids.clear()
	discovered_node_ids.append(start_id)
	
	GLog.debug("Created starting node: " + start_id)

func create_city_node(city_name: String, city_position: Vector2):
	var city_id = "city_" + city_name.to_lower().replace(" ", "_")
	var city_config = MapNodeRegistry.get_default_config_for_type(0)  # CITY
	var city_node = MapNodeRegistry.create_node(city_id, city_config, city_position)
	city_node.set_state(MapNode.NodeState.CURRENT)  # City is current position since player starts there
	city_node.set_custom_property("city_name", city_name)
	
	graph.nodes[city_id] = city_node
	graph.start_node = city_id
	graph.player_position = city_id
	current_player_node_id = city_id
	visited_node_ids.clear()
	visited_node_ids.append(city_id)
	discovered_node_ids.clear()
	discovered_node_ids.append(city_id)
	
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
	
	# Final safety: if any step above disconnected the graph, reconnect
	var reachable_final = find_reachable_nodes(graph.start_node)
	if reachable_final.size() < graph.nodes.size():
		GLog.warn("Graph became disconnected after enforcement; running final connectivity pass")
		ensure_graph_connectivity()
    
	# Node positions already optimized during generation


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
				if node_id in find_reachable_nodes(graph.start_node):
					GLog.debug("Connected isolated node " + node_id + " to " + best_connection)
					reachable.append(node_id)
					continue
			# Fallback: connect to nearest reachable node ignoring distance constraints
			var fallback_target = find_nearest_node(node_id, reachable)
			if fallback_target != "":
				if not edge_exists(node_id, fallback_target):
					var travel_time = SeedManager.get_map_random_int(2, 4)
					var difficulty = SeedManager.get_map_random_int(1, 3)
					var edge = MapEdge.new(node_id, fallback_target, travel_time, difficulty)
					graph.edges.append(edge)
					graph.nodes[node_id].connect_to(fallback_target)
					graph.nodes[fallback_target].connect_to(node_id)
					GLog.warn("Added bridge to ensure connectivity (non-planar path): " + node_id + " <-> " + fallback_target)
				reachable = find_reachable_nodes(graph.start_node)

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
		
		# Get appropriate config for the new type and set it
		var new_config = MapNodeRegistry.get_random_config_for_type(target_type)
		junction.set_config(new_config)
		
		GLog.debug("Converted junction " + junction_id + " to " + junction.get_type_name())



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
	var _max_distance = layout_config.spacing_max
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
	
	# Handle state transitions and visitation tracking
	target_node.set_state(MapNode.NodeState.CURRENT)
	# Update previous current node to visited/completed state
	var previous_node = graph.nodes[old_position] 
	if previous_node:
		previous_node.set_state(MapNode.NodeState.COMPLETED)
	
	if target_node_id not in visited_node_ids:
		visited_node_ids.append(target_node_id)
	discover_adjacent_nodes(target_node_id, 2)
	
	player_moved.emit(old_position, target_node_id)
	GLog.debug("Player moved from " + old_position + " to " + target_node_id)
	
	return true

func discover_adjacent_nodes(node_id: String, max_distance: int = 1):
	if not graph.nodes.has(node_id):
		return
	
	var current_round: Array[String] = [node_id]
	var processed: Array[String] = [node_id]  # Don't rediscover starting node
	
	for distance in range(1, max_distance + 1):
		var next_round: Array[String] = []
		
		for current_node_id in current_round:
			var current_node = graph.nodes[current_node_id]
			
			for connected_id in current_node.connections:
				if connected_id not in processed:
					var connected_node = graph.nodes[connected_id]
					
					# Only reveal nodes that haven't been discovered yet
					if not is_node_discovered(connected_id):
						connected_node.set_state(MapNode.NodeState.AVAILABLE)
						add_discovered_node(connected_id)
						node_discovered.emit(connected_id)
					
					next_round.append(connected_id)
					processed.append(connected_id)
		
		current_round = next_round
		if current_round.is_empty():
			break  # No more nodes to discover

func get_current_player_node() -> MapNode:
	return graph.nodes.get(graph.player_position, null)

# Discovery tracking methods
func add_discovered_node(node_id: String):
	"""Mark a node as permanently discovered"""
	if node_id not in discovered_node_ids:
		discovered_node_ids.append(node_id)
		GLog.debug("Node permanently discovered: " + node_id)

func is_node_discovered(node_id: String) -> bool:
	"""Check if a node has been discovered"""
	return node_id in discovered_node_ids

func is_node_visited(node_id: String) -> bool:
	"""Check if a node has been visited"""
	return node_id in visited_node_ids

func is_currently_reachable(node_id: String) -> bool:
	"""Check if a node is currently reachable from the player's position"""
	var current_node = get_current_player_node()
	if not current_node:
		return false
	return current_node.is_connected_to(node_id)

func restore_persistent_visibility():
	"""Restore proper visibility for all nodes based on discovery and visit status"""
	if debug_show_all_nodes:
		GLog.debug("DEBUG MAP MODE: Overriding persistent visibility - all nodes set to AVAILABLE")
		for node_id in graph.nodes:
			var node = graph.nodes[node_id]
			if node_id == current_player_node_id:
				node.set_state(MapNode.NodeState.CURRENT)
			else:
				node.set_state(MapNode.NodeState.AVAILABLE)
		return
	
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		
		if node_id == current_player_node_id:
			# Current player position
			node.set_state(MapNode.NodeState.CURRENT)
		elif is_node_visited(node_id):
			# Previously visited nodes - check if still reachable
			if is_currently_reachable(node_id):
				node.set_state(MapNode.NodeState.AVAILABLE if node.can_revisit() else MapNode.NodeState.COMPLETED)
			else:
				node.set_state(MapNode.NodeState.COMPLETED)
		elif is_node_discovered(node_id):
			# Discovered but not visited nodes - check if currently reachable
			if is_currently_reachable(node_id):
				node.set_state(MapNode.NodeState.AVAILABLE)
			else:
				node.set_state(MapNode.NodeState.KNOWN)  # NEW: Visible but unreachable
		else:
			# Unknown nodes remain locked
			node.set_state(MapNode.NodeState.LOCKED)
	
	GLog.debug("Restored persistent visibility - " + str(discovered_node_ids.size()) + " discovered, " + str(visited_node_ids.size()) + " visited")

func get_available_moves() -> Array[String]:
	var current_node = get_current_player_node()
	if not current_node:
		return []
	
	var available: Array[String] = []
	
	for connected_id in current_node.connections:
		var connected_node = graph.nodes[connected_id]
		if connected_node.state == MapNode.NodeState.AVAILABLE or \
		   (connected_node.state == MapNode.NodeState.COMPLETED and connected_node.can_revisit()):
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
			"state": node.state
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
		"min_nodes": layout_config.min_nodes if layout_config else default_min_nodes,
		"visited_nodes": visited_node_ids.duplicate(),
		"discovered_nodes": discovered_node_ids.duplicate()
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
		var node_config = MapNodeRegistry.get_random_config_for_type(node_data.type)
		var node = MapNodeRegistry.create_node(node_id, node_config, position)
		
		node.connections = node_data.connections.duplicate()
		node.set_state(node_data.state)
		
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
	
	# Restore tracking arrays
	current_player_node_id = data.player_position
	if data.has("visited_nodes"):
		visited_node_ids = data.visited_nodes.duplicate()
	else:
		visited_node_ids = []
	
	if data.has("discovered_nodes"):
		discovered_node_ids = data.discovered_nodes.duplicate()
	else:
		discovered_node_ids = []
	
	GLog.debug("Map restored from serializable data: " + str(graph.nodes.size()) + " nodes, " + str(graph.edges.size()) + " edges")
	GLog.debug("Restored " + str(visited_node_ids.size()) + " visited nodes, " + str(discovered_node_ids.size()) + " discovered nodes")

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

# Removed apply_poisson_disk_layout() - redundant with initial Poisson sampling in generate_nodes_with_poisson_sampling()

# New planar graph generation methods

func generate_nodes_with_poisson_sampling():
	"""Generate nodes using Poisson Disk Sampling for even distribution"""
	var target_count = SeedManager.get_map_random_int(
		layout_config.min_nodes if layout_config else default_min_nodes,
		layout_config.max_nodes if layout_config else default_max_nodes
	)
	
	# We already have the start node, so generate target_count - 1 more
	var additional_nodes = target_count - 1
	
	GLog.debug("Generating " + str(additional_nodes) + " additional nodes with Poisson sampling")
	
	# Use Poisson Disk Sampling to get well-distributed positions
	var layout_optimizer = PoissonDiskLayout.new()
	layout_optimizer.setup(layout_config)
	
	# Generate positions for all nodes (including start)
	var all_positions = layout_optimizer.generate_poisson_positions(target_count)
	
	# First position goes to start node (might adjust it)
	if all_positions.size() > 0:
		var start_node = graph.nodes[graph.start_node]
		start_node.position = all_positions[0]
	
	# Create additional nodes at remaining positions
	for i in range(1, min(all_positions.size(), target_count)):
		var node_id = "node_" + str(i)
		var node_type = layout_config.get_weighted_node_type() if layout_config else MapNode.NodeType.POI
		var node_config = MapNodeRegistry.get_random_config_for_type(node_type)
		var new_node = MapNodeRegistry.create_node(node_id, node_config, all_positions[i])
		
		graph.nodes[node_id] = new_node
	
	GLog.debug("Created " + str(graph.nodes.size()) + " nodes with Poisson distribution")

func apply_delaunay_triangulation():
	"""Apply Delaunay triangulation to create planar connectivity"""
	GLog.debug("Applying Delaunay triangulation...")
	
	# Generate triangulation
	graph = DelaunayTriangulator.triangulate_map_nodes(graph)
	
	if DEBUG_ENABLED:
		var edge_count = graph.get("edges", []).size()
		GLog.debug("Delaunay triangulation created " + str(edge_count) + " edges")
		
		# Validate that the result is actually planar
		if PlanarGraphValidator.is_graph_planar(graph):
			GLog.debug("✓ Triangulation is planar (no edge crossings)")
		else:
			GLog.warn("✗ Triangulation has edge crossings - this shouldn't happen!")

func prune_triangulation_edges():
	"""Intelligently prune edges from triangulation to match game design"""
	GLog.debug("Pruning triangulation edges...")
	
	# Create pruning configuration
	var pruning_config = EdgePruner.PruningConfig.new()
	
	if layout_config:
		pruning_config.max_edge_length = layout_config.connection_max_distance
		pruning_config.min_edge_length = layout_config.connection_min_distance
		pruning_config.max_connections_per_node = layout_config.cleanup_max_connections_per_node
		pruning_config.pruning_intensity = layout_config.planar_pruning_intensity
	
	# Apply intelligent pruning
	graph = EdgePruner.prune_triangulation(graph, pruning_config)
	
	if DEBUG_ENABLED:
		var edge_count = graph.get("edges", []).size()
		GLog.debug("Pruning complete: " + str(edge_count) + " edges remaining")
		
		# Validate planarity is preserved
		if PlanarGraphValidator.is_graph_planar(graph):
			GLog.debug("✓ Graph remains planar after pruning")
		else:
			GLog.warn("✗ Graph has crossings after pruning!")

func post_process_planar_graph():
	"""Post-process a planar graph while maintaining planarity"""
	# Balance node types (this doesn't affect connectivity)
	balance_node_types()
	
	# Check connectivity and add minimal connections if needed (with planarity checking)
	ensure_planar_connectivity()
	
	# Final planarity validation
	validate_final_planarity()

func ensure_planar_connectivity():
	"""Ensure graph connectivity while maintaining planarity"""
	var reachable = find_reachable_nodes(graph.start_node)
	var all_nodes = graph.nodes.keys()
	var added_bridges: Array = []

	for node_id in all_nodes:
		if node_id not in reachable:
			# Try a planar connection first
			var best_connection = find_planar_connection(node_id, reachable)
			if best_connection != "":
				if connect_nodes_if_planar(node_id, best_connection):
					GLog.debug("Connected isolated node " + node_id + " to " + best_connection + " (planar)")
					reachable.append(node_id)
					continue

			# If no planar edge exists, connect to the nearest reachable node as a temporary bridge
			var fallback_target = find_nearest_node(node_id, reachable)
			if fallback_target != "":
				# Add the bridge ignoring planarity to guarantee connectivity
				if not edge_exists(node_id, fallback_target):
					var travel_time = SeedManager.get_map_random_int(2, 4)
					var difficulty = SeedManager.get_map_random_int(1, 3)
					var edge = MapEdge.new(node_id, fallback_target, travel_time, difficulty)
					graph.edges.append(edge)
					graph.nodes[node_id].connect_to(fallback_target)
					graph.nodes[fallback_target].connect_to(node_id)
					added_bridges.append({"from": node_id, "to": fallback_target})
					GLog.warn("Added non-planar bridge to ensure connectivity: " + node_id + " <-> " + fallback_target)
					# Update reachable set and continue
					reachable = find_reachable_nodes(graph.start_node)
				else:
					reachable.append(node_id)
			else:
				GLog.warn("No reachable fallback target found for node: " + node_id)

	# If we added any bridging edges that might create crossings, try to re-planarize while protecting those bridges
	if not added_bridges.is_empty() and layout_config and layout_config.auto_fix_crossings:
		GLog.debug("Replanarizing after adding bridges (protecting new edges)")
		graph = PlanarGraphValidator.make_graph_planar_greedy(graph, added_bridges)

func find_planar_connection(from_node_id: String, candidate_nodes: Array[String]) -> String:
	"""Find the best connection that won't create edge crossings"""
	if candidate_nodes.is_empty() or not graph.nodes.has(from_node_id):
		return ""
	
	var from_node = graph.nodes[from_node_id]
	var max_distance = layout_config.connection_max_distance if layout_config else 250.0
	
	# Find all candidates within reasonable distance
	var valid_candidates: Array = []
	
	for candidate_id in candidate_nodes:
		if graph.nodes.has(candidate_id):
			var candidate_node = graph.nodes[candidate_id]
			var distance = from_node.position.distance_to(candidate_node.position)
			
			if distance <= max_distance:
				# Check if this connection would create crossings
				if not PlanarGraphValidator.would_edge_create_crossing(graph, from_node_id, candidate_id):
					valid_candidates.append({"id": candidate_id, "distance": distance})
	
	if valid_candidates.is_empty():
		return ""
	
	# Sort by distance and return closest
	valid_candidates.sort_custom(func(a, b): return a.distance < b.distance)
	return valid_candidates[0].id

func connect_nodes_if_planar(node_a: String, node_b: String) -> bool:
	"""Connect two nodes only if it won't create edge crossings"""
	if PlanarGraphValidator.would_edge_create_crossing(graph, node_a, node_b):
		return false
	
	# Use the existing connect_nodes method but skip distance checks since we already validated
	if not graph.nodes.has(node_a) or not graph.nodes.has(node_b):
		return false
	
	# Check if already connected
	if edge_exists(node_a, node_b):
		return false
	
	# Create edge
	var travel_time = SeedManager.get_map_random_int(2, 4)
	var difficulty = SeedManager.get_map_random_int(1, 3)
	var edge = MapEdge.new(node_a, node_b, travel_time, difficulty)
	graph.edges.append(edge)
	
	# Update node connections
	graph.nodes[node_a].connect_to(node_b)
	graph.nodes[node_b].connect_to(node_a)
	
	GLog.debug("Connected " + node_a + " to " + node_b + " (planar)")
	return true

func validate_final_planarity():
	"""Validate that the final graph is planar and log any issues"""
	var report = PlanarGraphValidator.generate_planarity_report(graph)
	
	if report.is_planar:
		GLog.debug("✓ Final graph is planar with " + str(report.total_nodes) + " nodes and " + str(report.total_edges) + " edges")
	else:
		GLog.warn("✗ Final graph has " + str(report.total_crossings) + " edge crossings!")
		
		if DEBUG_ENABLED:
			for crossing in report.crossing_details:
				GLog.debug("  Crossing: " + crossing.edge1 + " ✗ " + crossing.edge2)
		
		# Attempt to fix crossings
		if layout_config and layout_config.auto_fix_crossings:
			GLog.debug("Attempting to fix crossings...")
			graph = PlanarGraphValidator.make_graph_planar_greedy(graph)
			
			var fixed_report = PlanarGraphValidator.generate_planarity_report(graph)
			if fixed_report.is_planar:
				GLog.debug("✓ Fixed all crossings - graph is now planar")
			else:
				GLog.warn("✗ Still have " + str(fixed_report.total_crossings) + " crossings after fix attempt")

func generate_map_for_region(config: MapRegionConfig, region_seed: int) -> Dictionary:
	"""Generate a complete map for a specific region"""
	GLog.debug("Generating map for region: " + config.region_id)
	
	# Set up configuration
	layout_config = MapLayoutConfig.new()
	layout_config.min_nodes = config.min_nodes
	layout_config.max_nodes = config.max_nodes
	layout_config.viewport_size = config.region_bounds
	
	# Initialize RNG with region-specific seed
	generation_seed = region_seed
	SeedManager.map_rng.seed = region_seed
	
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
	
	# Discover adjacent nodes from the starting city so they become selectable
	discover_adjacent_nodes(graph.start_node, 2)
	
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
			var node_config = MapNodeRegistry.get_random_config_for_type(node_type)
			var new_node = MapNodeRegistry.create_node(node_id, node_config, new_pos)
			
			graph.nodes[node_id] = new_node
			
			# Connect to previous node
			connect_nodes(last_node_id, node_id)
			
			# Occasionally create branches or connections
			if j > 0 and SeedManager.get_map_random_float() < 0.3:
				create_branch_connection(node_id, config)
			
			last_node_id = node_id

func create_branch_connection(from_node_id: String, _config: MapRegionConfig):
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
	
	var boss_config = MapNodeRegistry.get_random_config_for_type(6)  # BOSS
	var boss_node = MapNodeRegistry.create_node(boss_id, boss_config, boss_pos)
	boss_node.set_custom_property("boss_name", config.boss_name)
	boss_node.set_custom_property("boss_enemy_id", config.boss_enemy_id)
	
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
