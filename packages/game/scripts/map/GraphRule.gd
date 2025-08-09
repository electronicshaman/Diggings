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
		
		# Create junction node using config
		var junction_id = "junction_" + str(Time.get_ticks_msec())
		
		# Use config for positioning if available
		var angle = config.get_movement_angle() if config else (SeedManager.get_map_random_float() * PI - PI/2)
		var distance = config.linear_junction_distance if config else (SeedManager.get_map_random_float() * 80 + 100)
		var junction_pos = nodes[from_node].position + Vector2(cos(angle), sin(angle)) * distance
		
		# Clamp to bounds using config
		if config:
			junction_pos = config.clamp_to_bounds(junction_pos)
		else:
			junction_pos.x = clamp(junction_pos.x, 50, 1230)
			junction_pos.y = clamp(junction_pos.y, 50, 670)
		
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
		
		if config:
			dest_pos = config.clamp_to_bounds(dest_pos)
		
		var destination = MapNode.new(dest_id, dest_type, dest_pos)
		
		# Add nodes to graph
		nodes[junction_id] = junction
		nodes[dest_id] = destination
		
		# Create edges
		var edge1 = MapEdge.new(from_node, junction_id, SeedManager.get_map_random_int(1, 3))
		var edge2 = MapEdge.new(junction_id, dest_id, SeedManager.get_map_random_int(1, 4))
		edges.append(edge1)
		edges.append(edge2)
		
		# Connect nodes
		nodes[from_node].connect_to(junction_id)
		junction.connect_to(from_node)
		junction.connect_to(dest_id)
		destination.connect_to(junction_id)
		
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
		
		if config:
			dest_pos = config.clamp_to_bounds(dest_pos)
		
		var destination = MapNode.new(dest_id, dest_type, dest_pos)
		
		# Add to graph
		nodes[dest_id] = destination
		
		# Create edge using config
		var edge = MapEdge.new(junction_node, dest_id, SeedManager.get_map_random_int(2, 5))
		var base_difficulty = SeedManager.get_map_random_int(1, 3)
		var difficulty_bonus = config.branch_difficulty_bonus if config else 2
		edge.difficulty = base_difficulty + difficulty_bonus  # Branches are often more dangerous
		edges.append(edge)
		
		# Connect nodes
		nodes[junction_node].connect_to(dest_id)
		destination.connect_to(junction_node)
		
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
