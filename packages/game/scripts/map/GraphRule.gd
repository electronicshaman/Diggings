extends Resource
class_name GraphRule

const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

@export var rule_name: String = ""
@export var weight: float = 1.0  # Probability weight for rule application
@export var max_applications: int = -1  # -1 for unlimited

var applications_count: int = 0
var config: MapLayoutConfig  # Reference to layout configuration

# Pattern to match in the graph
class GraphPattern:
	var nodes: Array[Dictionary] = []  # Array of {type: NodeType, connections: Array}
	var edges: Array[Dictionary] = []  # Array of {from: int, to: int} (indices into nodes)
	
	func _init(pattern_nodes: Array[Dictionary] = [], pattern_edges: Array[Dictionary] = []):
		nodes = pattern_nodes
		edges = pattern_edges

# The pattern this rule looks for
var pattern: GraphPattern

# What to replace the pattern with  
var replacement: GraphPattern

# Additional conditions for rule application
var conditions: Array[Callable] = []

func _init(name: String = "", rule_weight: float = 1.0):
	rule_name = name
	weight = rule_weight

func can_apply(graph_state: Dictionary) -> bool:
	if max_applications > 0 and applications_count >= max_applications:
		return false
	
	# Check all conditions
	for condition in conditions:
		if not condition.call(graph_state):
			return false
	
	return true

func apply(graph: Dictionary, match_info: Dictionary) -> bool:
	if not can_apply(graph):
		return false
	
	# This will be implemented by specific rule subclasses
	# Each rule type will have its own application logic
	applications_count += 1
	return true

func find_matches(graph: Dictionary) -> Array[Dictionary]:
	# Find all locations in the graph where this rule's pattern matches
	# Returns array of match information for each valid match
	var matches: Array[Dictionary] = []
	
	# This is a simplified pattern matching - would need more sophisticated
	# graph matching for complex patterns
	
	return matches

func reset():
	applications_count = 0

# Factory methods for common rule types
static func create_linear_extension_rule() -> LinearExtensionRule:
	return LinearExtensionRule.new()

static func create_branch_rule() -> BranchCreationRule:
	return BranchCreationRule.new()

static func create_destination_rule() -> DestinationPlacementRule:
	return DestinationPlacementRule.new()


# Specific rule implementations
class LinearExtensionRule extends GraphRule:
	func _init():
		super("Linear Extension", 3.0)
		max_applications = 20  # Will be overridden by config
	
	func apply(graph: Dictionary, match_info: Dictionary) -> bool:
		if not can_apply(graph):
			return false
			
		# Extend from an existing node
		var from_node = match_info.get("from_node", "")
		if from_node == "":
			return false
		
		var nodes = graph.get("nodes", {})
		var edges = graph.get("edges", [])
		
		# Check if linear_create_junctions is enabled
		var create_junction = config.linear_create_junctions if config else true
		
		if not create_junction:
			# Skip creating junctions - directly create destination node
			var dest_type
			if config:
				dest_type = config.get_weighted_node_type()
			else:
				var dest_types = [MapNode.NodeType.CAMP, MapNode.NodeType.MINE, MapNode.NodeType.SETTLEMENT, MapNode.NodeType.POI]
				dest_type = dest_types[SeedManager.get_map_random_int(0, dest_types.size() - 1)]
			
			var dest_id = MapNode.NodeType.keys()[dest_type].to_lower() + "_" + str(Time.get_ticks_msec())
			
			# Position destination using config
			var angle = config.get_movement_angle() if config else (SeedManager.get_map_random_float() * PI - PI/2)
			var distance = config.linear_junction_distance if config else (SeedManager.get_map_random_float() * 80 + 100)
			var dest_pos = nodes[from_node].position + Vector2(cos(angle), sin(angle)) * distance
			
			# Find valid position with spacing constraints
			if config and config.bounds_auto_adjust_spacing:
				# Try to find a valid position that respects spacing
				dest_pos = _find_valid_position_with_spacing(graph, dest_pos, angle, distance, from_node)
			else:
				# Just clamp to bounds
				if config:
					dest_pos = config.clamp_to_bounds(dest_pos)
			
			# Check if position is valid for spacing
			if not _is_position_valid_for_spacing(graph, dest_pos):
				GLog.debug("LinearExtensionRule: Cannot place node at " + str(dest_pos) + " due to spacing constraints")
				return false
			
			var destination = MapNode.new(dest_id, dest_type, dest_pos)
			
			# Add node to graph
			nodes[dest_id] = destination
			
			# Create edge safely (checks for duplicates)
			_connect_nodes_safely(graph, from_node, dest_id, SeedManager.get_map_random_int(1, 4))
			
			applications_count += 1
			GLog.debug("Applied Linear Extension rule (no junction): " + from_node + " -> " + dest_id)
			return true
		
		# Original junction creation logic with spacing validation
		var junction_id = "junction_" + str(Time.get_ticks_msec())
		
		# Use config for positioning if available
		var angle = config.get_movement_angle() if config else (SeedManager.get_map_random_float() * PI - PI/2)
		var distance = config.linear_junction_distance if config else (SeedManager.get_map_random_float() * 80 + 100)
		var junction_pos = nodes[from_node].position + Vector2(cos(angle), sin(angle)) * distance
		
		# Find valid position with spacing constraints
		if config and config.bounds_auto_adjust_spacing:
			junction_pos = _find_valid_position_with_spacing(graph, junction_pos, angle, distance, from_node)
		else:
			if config:
				junction_pos = config.clamp_to_bounds(junction_pos)
			else:
				junction_pos.x = clamp(junction_pos.x, 50, 1230)
				junction_pos.y = clamp(junction_pos.y, 50, 670)
		
		# Check if position is valid for spacing
		if not _is_position_valid_for_spacing(graph, junction_pos):
			GLog.debug("LinearExtensionRule: Cannot place junction at " + str(junction_pos) + " due to spacing constraints")
			return false
		
		var junction = MapNode.new(junction_id, MapNode.NodeType.JUNCTION, junction_pos)
		
		# Create destination node using config
		var dest_type
		if config:
			dest_type = config.get_weighted_node_type()
		else:
			var dest_types = [MapNode.NodeType.CAMP, MapNode.NodeType.MINE, MapNode.NodeType.SETTLEMENT, MapNode.NodeType.POI]
			dest_type = dest_types[SeedManager.get_map_random_int(0, dest_types.size() - 1)]
		
		var dest_id = MapNode.NodeType.keys()[dest_type].to_lower() + "_" + str(Time.get_ticks_msec())
		
		# Position destination using config
		var dest_angle = angle + (SeedManager.get_map_random_float() - 0.5) * PI  # Vary by up to 90 degrees
		var dest_distance = config.linear_destination_distance if config else (SeedManager.get_map_random_float() * 80 + 60)
		var dest_pos = junction_pos + Vector2(cos(dest_angle), sin(dest_angle)) * dest_distance
		
		# Find valid position with spacing constraints
		if config and config.bounds_auto_adjust_spacing:
			dest_pos = _find_valid_position_with_spacing(graph, dest_pos, dest_angle, dest_distance, junction_id)
		else:
			if config:
				dest_pos = config.clamp_to_bounds(dest_pos)
		
		# Check if destination position is valid for spacing
		if not _is_position_valid_for_spacing(graph, dest_pos, junction_id):
			GLog.debug("LinearExtensionRule: Cannot place destination at " + str(dest_pos) + " due to spacing constraints")
			return false
		
		var destination = MapNode.new(dest_id, dest_type, dest_pos)
		
		# Add nodes to graph
		nodes[junction_id] = junction
		nodes[dest_id] = destination
		
		# Create edges safely (checks for duplicates)
		_connect_nodes_safely(graph, from_node, junction_id, SeedManager.get_map_random_int(1, 3))
		_connect_nodes_safely(graph, junction_id, dest_id, SeedManager.get_map_random_int(1, 4))
		
		applications_count += 1
		GLog.debug("Applied Linear Extension rule: " + from_node + " -> " + junction_id + " -> " + dest_id)
		return true


class BranchCreationRule extends GraphRule:
	func _init():
		super("Branch Creation", 2.0)
		max_applications = 10  # Will be overridden by config
	
	func apply(graph: Dictionary, match_info: Dictionary) -> bool:
		if not can_apply(graph):
			return false
			
		var junction_node = match_info.get("junction_node", "")
		if junction_node == "":
			return false
		
		var nodes = graph.get("nodes", {})
		var edges = graph.get("edges", [])
		
		# Only branch from junctions with few connections
		if nodes[junction_node].connections.size() >= 3:
			return false
		
		# Create new branch destination using config
		var dest_type
		if config:
			# Branches prefer mines and POIs
			var branch_types = [MapNode.NodeType.MINE, MapNode.NodeType.POI]
			dest_type = branch_types[SeedManager.get_map_random_int(0, branch_types.size() - 1)]
		else:
			var dest_types = [MapNode.NodeType.MINE, MapNode.NodeType.POI]
			dest_type = dest_types[SeedManager.get_map_random_int(0, dest_types.size() - 1)]
		
		var dest_id = MapNode.NodeType.keys()[dest_type].to_lower() + "_branch_" + str(Time.get_ticks_msec())
		var base_pos = nodes[junction_node].position
		
		# Create branches using config
		var branch_angle = SeedManager.get_map_random_float() * TAU
		var branch_distance = config.branch_distance if config else (SeedManager.get_map_random_float() * 60 + 80)
		var dest_pos = base_pos + Vector2(cos(branch_angle), sin(branch_angle)) * branch_distance
		
		# Find valid position with spacing constraints
		if config and config.bounds_auto_adjust_spacing:
			dest_pos = _find_valid_position_with_spacing(graph, dest_pos, branch_angle, branch_distance, junction_node)
		else:
			if config:
				dest_pos = config.clamp_to_bounds(dest_pos)
		
		# Check if position is valid for spacing
		if not _is_position_valid_for_spacing(graph, dest_pos):
			GLog.debug("BranchCreationRule: Cannot place branch at " + str(dest_pos) + " due to spacing constraints")
			return false
		
		var destination = MapNode.new(dest_id, dest_type, dest_pos)
		
		# Add to graph
		nodes[dest_id] = destination
		
		# Create edge safely with increased difficulty for branches
		var base_difficulty = SeedManager.get_map_random_int(1, 3)
		var difficulty_bonus = config.branch_difficulty_bonus if config else 2
		var branch_difficulty = base_difficulty + difficulty_bonus
		_connect_nodes_safely(graph, junction_node, dest_id, SeedManager.get_map_random_int(2, 5), branch_difficulty)
		
		applications_count += 1
		GLog.debug("Applied Branch Creation rule: " + junction_node + " -> " + dest_id)
		return true


class DestinationPlacementRule extends GraphRule:
	func _init():
		super("Destination Placement", 1.5)
	
	func apply(graph: Dictionary, match_info: Dictionary) -> bool:
		if not can_apply(graph):
			return false
			
		var junction_node = match_info.get("junction_node", "")
		if junction_node == "":
			return false
		
		var nodes = graph.get("nodes", {})
		
		# Convert junction to meaningful destination
		var junction = nodes[junction_node]
		if junction.type != MapNode.NodeType.JUNCTION:
			return false
		
		# Choose new type based on position and existing nearby nodes
		var new_types = [MapNode.NodeType.CAMP, MapNode.NodeType.SETTLEMENT]
		var new_type = new_types[SeedManager.get_map_random_int(0, new_types.size() - 1)]
		
		junction.type = new_type
		junction.id = MapNode.NodeType.keys()[new_type].to_lower() + "_" + str(Time.get_ticks_msec())
		
		# Update properties based on new type
		junction._init(junction.id, new_type, junction.position)
		
		applications_count += 1
		GLog.debug("Applied Destination Placement rule: converted junction to " + junction.get_type_name())
		return true

# Helper function to safely create connections without duplicates
func _connect_nodes_safely(graph: Dictionary, node_a: String, node_b: String, travel_time: int = -1, difficulty: int = -1):
	"""Safely connect two nodes, checking for duplicates and same-type restrictions first"""
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	# Check if edge already exists
	for edge in edges:
		if (edge.from_node == node_a and edge.to_node == node_b) or \
		   (edge.from_node == node_b and edge.to_node == node_a):
			GLog.debug("Skipping duplicate edge in rule: " + node_a + " <-> " + node_b)
			return
	
	# Prevent same node types from connecting (camps to camps, settlements to settlements)
	var node_a_obj = nodes.get(node_a)
	var node_b_obj = nodes.get(node_b)
	if node_a_obj and node_b_obj:
		# Check for same-type restriction (camps and settlements cannot connect to same type)
		if (node_a_obj.type == MapNode.NodeType.CAMP and node_b_obj.type == MapNode.NodeType.CAMP) or \
		   (node_a_obj.type == MapNode.NodeType.SETTLEMENT and node_b_obj.type == MapNode.NodeType.SETTLEMENT):
			GLog.debug("Preventing same-type connection: " + node_a + " (" + node_a_obj.get_type_name() + ") <-> " + node_b + " (" + node_b_obj.get_type_name() + ")")
			return
		
		# Check single connection limit for settlement types (shops)
		# Each node should only connect to one settlement at most
		if node_a_obj.type == MapNode.NodeType.SETTLEMENT and _has_settlement_connection(graph, node_b):
			GLog.debug("Preventing multiple settlement connections: " + node_b + " already connected to a settlement")
			return
		if node_b_obj.type == MapNode.NodeType.SETTLEMENT and _has_settlement_connection(graph, node_a):
			GLog.debug("Preventing multiple settlement connections: " + node_a + " already connected to a settlement")
			return
	
	# Create edge with random values if not specified
	if travel_time == -1:
		travel_time = SeedManager.get_map_random_int(2, 4)
	if difficulty == -1:
		difficulty = SeedManager.get_map_random_int(1, 3)
	
	var edge = MapEdge.new(node_a, node_b, travel_time, difficulty)
	edges.append(edge)
	
	# Connect nodes bidirectionally
	if nodes.has(node_a) and nodes.has(node_b):
		nodes[node_a].connect_to(node_b)
		nodes[node_b].connect_to(node_a)
	
	GLog.debug("Created edge in rule: " + node_a + " <-> " + node_b + " (travel: " + str(travel_time) + ", difficulty: " + str(difficulty) + ")")

# Helper function to check if a node already has a connection to a settlement
func _has_settlement_connection(graph: Dictionary, node_id: String) -> bool:
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	var target_node = nodes.get(node_id)
	if not target_node:
		return false
	
	# Check all edges to see if this node connects to any settlement
	for edge in edges:
		var connected_node_id: String = ""
		if edge.from_node == node_id:
			connected_node_id = edge.to_node
		elif edge.to_node == node_id:
			connected_node_id = edge.from_node
		
		if connected_node_id != "":
			var connected_node = nodes.get(connected_node_id)
			if connected_node and connected_node.type == MapNode.NodeType.SETTLEMENT:
				return true
	
	return false

# Helper functions for spacing validation - now non-static to access config
func _is_position_valid_for_spacing(graph: Dictionary, new_pos: Vector2, exclude_node_id: String = "") -> bool:
	"""Check if a position maintains minimum spacing from all existing nodes"""
	var nodes = graph.get("nodes", {})
	
	# Use config spacing if available, otherwise use default
	var min_spacing = config.spacing_min if config else 100.0
	
	for node_id in nodes:
		if node_id == exclude_node_id:
			continue
		
		var node = nodes[node_id]
		var distance = new_pos.distance_to(node.position)
		
		if distance < min_spacing:
			return false
	
	return true

func _find_valid_position_with_spacing(graph: Dictionary, base_pos: Vector2, preferred_angle: float, preferred_distance: float, source_node_id: String = "") -> Vector2:
	"""Find a valid position that respects spacing constraints"""
	var nodes = graph.get("nodes", {})
	
	# Use config values if available
	var min_spacing = config.spacing_min if config else 100.0
	var max_spacing = config.spacing_max if config else 180.0
	var max_attempts = 10
	var angle_step = PI / 6  # 30 degrees
	
	# Try the preferred position first
	if _is_position_valid_for_spacing(graph, base_pos, source_node_id):
		return base_pos
	
	# Auto-adjust spacing enabled - try different positions
	if config and config.bounds_auto_adjust_spacing:
		# Try different angles and distances
		for attempt in range(max_attempts):
			# Try different angles around the preferred angle
			for angle_offset in [0, angle_step, -angle_step, angle_step * 2, -angle_step * 2]:
				var test_angle = preferred_angle + angle_offset
				
				# Try different distances (start at preferred, decrease if needed)
				var distance = preferred_distance
				while distance >= min_spacing:
					var test_pos = base_pos + Vector2(cos(test_angle), sin(test_angle)) * distance
					
					# Clamp to bounds if config available
					if config:
						test_pos = config.clamp_to_bounds(test_pos)
					
					if _is_position_valid_for_spacing(graph, test_pos, source_node_id):
						return test_pos
					
					distance *= 0.9  # Reduce distance by 10%
		
		GLog.warn("Could not find valid position with auto-adjust spacing, using fallback")
	
	# Fallback: clamp to bounds and return
	if config:
		return config.clamp_to_bounds(base_pos)
	else:
		return base_pos


# Minimum Connection Rule - ensures nodes have at least 2 connections to prevent dead ends
class MinimumConnectionRule extends GraphRule:
	func _init():
		super("Minimum Connection", 0.0)  # This is a cleanup rule, not weighted
		max_applications = -1  # Unlimited applications
	
	func can_apply(graph_state: Dictionary) -> bool:
		# Always applicable - this is a cleanup rule
		return true
	
	func apply(graph: Dictionary, match_info: Dictionary) -> bool:
		var nodes = graph.get("nodes", {})
		var edges = graph.get("edges", [])
		var connections_added = 0
		
		# Find nodes with insufficient connections
		var under_connected_nodes = []
		var min_connections = 2
		
		for node_id in nodes:
			var node = nodes[node_id]
			# Skip start node and intentional endpoints (some node types should be endpoints)
			if node_id == graph.get("start_node", "") or node.connections.size() >= min_connections:
				continue
			
			# Allow some node types to be endpoints (like remote mines or special POIs)
			if node.type == MapNode.NodeType.POI and node.connections.size() >= 1:
				continue
			
			under_connected_nodes.append(node_id)
		
		GLog.debug("MinimumConnectionRule: Found " + str(under_connected_nodes.size()) + " under-connected nodes")
		
		# Connect under-connected nodes to nearby nodes
		for node_id in under_connected_nodes:
			var node = nodes[node_id]
			var connections_needed = min_connections - node.connections.size()
			
			# Find potential connection candidates (nodes not already connected)
			var candidates = []
			for other_id in nodes:
				if other_id == node_id or node.is_connected_to(other_id):
					continue
				
				var other_node = nodes[other_id]
				var distance = node.position.distance_to(other_node.position)
				var max_distance = config.connection_max_distance if config else 250.0
				
				if distance <= max_distance:
					candidates.append({"id": other_id, "distance": distance, "connections": other_node.connections.size()})
			
			# Sort candidates by distance and existing connection count (prefer less connected nodes)
			candidates.sort_custom(func(a, b): return a.distance + (a.connections * 20) < b.distance + (b.connections * 20))
			
			# Add connections to nearest suitable candidates
			var connections_to_add = min(connections_needed, candidates.size())
			for i in range(connections_to_add):
				var target_id = candidates[i].id
				var target_node = nodes[target_id]
				
				# Create connection safely (checks for duplicates)
				_connect_nodes_safely(graph, node_id, target_id, SeedManager.get_map_random_int(2, 4), SeedManager.get_map_random_int(1, 3))
				
				connections_added += 1
				GLog.debug("MinimumConnectionRule: Connected " + node_id + " to " + target_id + " (distance: " + str(candidates[i].distance) + ")")
		
		if connections_added > 0:
			applications_count += 1
			GLog.debug("MinimumConnectionRule: Added " + str(connections_added) + " connections to ensure minimum connectivity")
			return true
		
		return false
