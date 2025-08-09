extends Resource
class_name MapLayoutConfig

# MapLayoutConfig - Easy-to-edit parameters for map generation
# Edit this resource in the Godot inspector to fine-tune map layouts!

## BASIC GENERATION SETTINGS ##

@export_group("Generation Limits")
@export_range(5, 50, 1) var min_nodes: int = 20
@export_range(5, 50, 1) var max_nodes: int = 30
@export var viewport_size: Vector2 = Vector2(1280, 720)

@export_group("Starting Position")
@export_range(0.05, 0.5, 0.05) var start_x_ratio: float = 0.15  # How far from left edge (0.15 = 15% from left)
@export_range(0.2, 0.8, 0.1) var start_y_ratio: float = 0.5   # How far from top (0.5 = center)

## DISTANCE & SPACING CONTROLS ##

@export_group("Connection Distances", "connection_")
@export_range(50, 500, 10) var connection_max_distance: float = 250.0  # Maximum distance for edge connections
@export_range(20, 200, 5) var connection_min_distance: float = 60.0    # Minimum distance between connected nodes

@export_group("Node Spacing", "spacing_")
@export_range(80, 300, 10) var spacing_min: float = 100.0  # Minimum distance when placing new nodes
@export_range(100, 400, 10) var spacing_max: float = 180.0 # Maximum distance when placing new nodes

## LAYOUT DIRECTION CONTROLS ##

@export_group("Movement Patterns", "movement_")
@export_range(-1.0, 1.0, 0.1) var movement_rightward_bias: float = 0.5    # -1=leftward, 0=random, 1=rightward
@export_range(0.0, 180.0, 5.0) var movement_angle_variation: float = 90.0  # How much to vary from preferred direction (degrees)
@export var movement_preferred_angles: Array[float] = [0.0, 45.0, -45.0]   # Preferred angles in degrees (0=right, 90=down, -90=up)

## RULE CONFIGURATION ##

@export_group("Linear Extension Rule", "linear_")
@export_range(0.5, 5.0, 0.1) var linear_weight: float = 3.0           # How often this rule is chosen
@export_range(5, 30, 1) var linear_max_applications: int = 20          # Maximum times this rule can run
@export var linear_create_junctions: bool = true                       # Whether to create intermediate junction nodes
@export_range(50, 200, 5) var linear_junction_distance: float = 120.0  # Distance to junction from source node
@export_range(60, 200, 5) var linear_destination_distance: float = 100.0 # Distance from junction to final destination

@export_group("Branch Creation Rule", "branch_")
@export_range(0.5, 5.0, 0.1) var branch_weight: float = 2.0       # How often this rule is chosen
@export_range(2, 15, 1) var branch_max_applications: int = 10      # Maximum times this rule can run
@export_range(80, 200, 5) var branch_distance: float = 110.0       # How far branch destinations are from junctions
@export_range(2, 4, 1) var branch_difficulty_bonus: int = 2        # Extra difficulty for branch paths

@export_group("Destination Placement Rule", "destination_")
@export_range(0.5, 5.0, 0.1) var destination_weight: float = 1.5   # How often this rule is chosen
@export_range(-1, 20, 1) var destination_max_applications: int = -1 # Maximum times this rule can run (-1 = unlimited)

## VISUAL & LAYOUT CLEANUP ##

@export_group("Layout Bounds", "bounds_")
@export_range(10, 100, 5) var bounds_margin: float = 50.0  # Margin from viewport edges
@export var bounds_enforce_viewport: bool = true           # Keep all nodes within viewport
@export var bounds_auto_adjust_spacing: bool = true       # Reduce spacing if nodes don't fit

@export_group("Connection Cleanup", "cleanup_")
@export var cleanup_remove_long_connections: bool = true   # Remove connections longer than max_distance
@export var cleanup_prefer_nearest_connections: bool = true # When connecting isolated nodes, use nearest neighbor
@export_range(1, 5, 1) var cleanup_max_connections_per_node: int = 4  # Limit connections per node to avoid spaghetti

## NODE TYPE DISTRIBUTION ##

@export_group("Node Types", "types_")
@export var types_camp_weight: float = 2.0       # Relative frequency of camps
@export var types_mine_weight: float = 1.5       # Relative frequency of mines  
@export var types_settlement_weight: float = 1.0 # Relative frequency of settlements
@export var types_poi_weight: float = 1.2        # Relative frequency of points of interest

## FORCE-DIRECTED LAYOUT SYSTEM ##

@export_group("Physics Layout", "physics_")
@export var physics_enabled: bool = true                                  # Enable force-directed layout optimization
@export_range(50, 500, 10) var physics_iterations: int = 200             # Number of simulation iterations (more = better layout, slower)
@export_range(0.1, 3.0, 0.1) var physics_repulsion_strength: float = 1.0 # How strongly nodes push apart
@export_range(0.1, 3.0, 0.1) var physics_attraction_strength: float = 0.8 # How strongly connected nodes pull together
@export_range(0.8, 0.99, 0.01) var physics_cooling_rate: float = 0.95    # How quickly the system cools down (stabilizes)
@export_range(0.0, 1.0, 0.1) var physics_boundary_strength: float = 0.3  # How strongly nodes are pushed away from boundaries

## CURVED PATH LINES ##

@export_group("Path Appearance", "path_")
@export var path_enable_curves: bool = true                              # Enable curved paths instead of straight lines
@export_range(0.0, 1.0, 0.1) var path_curve_strength: float = 0.3       # Strength of path curves (0.0 = straight, 1.0 = max curve)
@export_range(0.0, 0.5, 0.05) var path_curve_randomness: float = 0.15   # Random variation in curve direction
@export_range(8.0, 30.0, 1.0) var path_dash_length: float = 18.0        # Length of dashes in path lines
@export_range(6.0, 25.0, 1.0) var path_gap_length: float = 12.0         # Length of gaps between dashes

# Helper function to get preferred angle in radians with variation
func get_movement_angle() -> float:
	if movement_preferred_angles.is_empty():
		# Fallback to rightward bias
		var base_angle = 0.0  # Right
		if movement_rightward_bias < 0:
			base_angle = PI  # Left
		elif abs(movement_rightward_bias) < 0.1:
			base_angle = randf() * TAU  # Random
		
		var variation_rad = deg_to_rad(movement_angle_variation)
		return base_angle + (randf() - 0.5) * variation_rad
	else:
		# Pick from preferred angles
		var base_angle = deg_to_rad(movement_preferred_angles.pick_random())
		var variation_rad = deg_to_rad(movement_angle_variation)
		return base_angle + (randf() - 0.5) * variation_rad

# Get starting position based on ratios
func get_start_position() -> Vector2:
	return Vector2(
		viewport_size.x * start_x_ratio,
		viewport_size.y * start_y_ratio
	)

# Clamp position to viewport bounds with margin
func clamp_to_bounds(pos: Vector2) -> Vector2:
	if not bounds_enforce_viewport:
		return pos
	
	return Vector2(
		clamp(pos.x, bounds_margin, viewport_size.x - bounds_margin),
		clamp(pos.y, bounds_margin, viewport_size.y - bounds_margin)
	)

# Get a weighted random node type
func get_weighted_node_type() -> int:  # Returns MapNode.NodeType
	var weights = [
		types_camp_weight,      # MapNode.NodeType.CAMP
		types_mine_weight,      # MapNode.NodeType.MINE
		types_settlement_weight, # MapNode.NodeType.SETTLEMENT
		types_poi_weight        # MapNode.NodeType.POI
	]
	
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i + 1  # MapNode.NodeType enum starts at 1
	
	return 1  # Fallback to CAMP

# Validation function to ensure config makes sense
func validate_config() -> Array[String]:
	var warnings: Array[String] = []
	
	if max_nodes <= min_nodes:
		warnings.append("max_nodes should be greater than min_nodes")
	
	if connection_max_distance <= connection_min_distance:
		warnings.append("connection_max_distance should be greater than connection_min_distance")
	
	if spacing_max <= spacing_min:
		warnings.append("spacing_max should be greater than spacing_min")
	
	if spacing_min > connection_max_distance:
		warnings.append("spacing_min is larger than connection_max_distance - nodes may not connect")
	
	return warnings