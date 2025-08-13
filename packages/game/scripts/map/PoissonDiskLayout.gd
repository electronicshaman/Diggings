extends RefCounted
class_name PoissonDiskLayout

# Simple Poisson Disk Sampling for even node distribution
# Guarantees minimum distance between nodes for clean, consistent layouts

const DEBUG_ENABLED: bool = true

# Sampling parameters
var min_distance: float = 120.0
var max_attempts_per_point: int = 30
var bounds: Rect2

# Reference to configuration
var config: MapLayoutConfig

func _init():
	pass

func setup(layout_config: MapLayoutConfig = null):
	config = layout_config
	
	if config:
		# Use config parameters with increased spacing for better visual separation
		min_distance = config.spacing_min * 1.4  # Increase spacing by 40%
		bounds = Rect2(Vector2.ZERO, config.viewport_size)
		
		# Add margin to keep nodes away from exact edges
		var margin = 30.0
		bounds = Rect2(
			Vector2(margin, margin),
			Vector2(config.viewport_size.x - 2 * margin, config.viewport_size.y - 2 * margin)
		)
	else:
		# Fallback values
		min_distance = 120.0
		bounds = Rect2(Vector2(30, 30), Vector2(1860, 840))
	
	GLog.debug("PoissonDiskLayout setup - bounds: " + str(bounds) + ", min_distance: " + str(min_distance))

func apply_layout(graph: Dictionary) -> Dictionary:
	GLog.debug("Starting Poisson Disk Sampling layout...")
	
	var nodes = graph.get("nodes", {})
	
	if nodes.is_empty():
		GLog.debug("No nodes to layout")
		return graph
	
	# Generate evenly distributed positions
	var target_count = nodes.size()
	var positions = generate_poisson_positions(target_count)
	
	if positions.size() != target_count:
		GLog.warn("Generated " + str(positions.size()) + " positions for " + str(target_count) + " nodes")
		
		# If we have fewer positions than nodes, fill remaining randomly
		while positions.size() < target_count:
			var random_pos = Vector2(
				bounds.position.x + randf() * bounds.size.x,
				bounds.position.y + randf() * bounds.size.y
			)
			if is_valid_position(random_pos, positions, min_distance * 0.7):  # Relax distance for fallback
				positions.append(random_pos)
	
	# Assign positions to nodes
	var node_ids = nodes.keys()
	for i in range(min(node_ids.size(), positions.size())):
		var node = nodes[node_ids[i]]
		node.position = positions[i]
		GLog.debug("Positioned " + node_ids[i] + " at " + str(positions[i]))
	
	GLog.debug("Poisson Disk layout complete - positioned " + str(positions.size()) + " nodes")
	return graph

func generate_poisson_positions(target_count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var active_list: Array[Vector2] = []
	
	# Start with a random point in the center area
	var center = bounds.position + bounds.size * 0.5
	var first_point = center + Vector2(
		(randf() - 0.5) * bounds.size.x * 0.3,
		(randf() - 0.5) * bounds.size.y * 0.3
	)
	first_point = clamp_to_bounds(first_point)
	
	points.append(first_point)
	active_list.append(first_point)
	
	GLog.debug("Starting Poisson sampling from: " + str(first_point))
	
	# Main sampling loop
	while active_list.size() > 0 and points.size() < target_count:
		# Pick a random active point
		var active_index = randi() % active_list.size()
		var active_point = active_list[active_index]
		
		var found_valid_point = false
		
		# Try to place a new point around this active point
		for attempt in range(max_attempts_per_point):
			var angle = randf() * TAU  # Random angle
			var distance = min_distance + randf() * min_distance  # Distance between min_distance and 2*min_distance
			
			var candidate = active_point + Vector2(cos(angle), sin(angle)) * distance
			candidate = clamp_to_bounds(candidate)
			
			if is_valid_position(candidate, points, min_distance):
				points.append(candidate)
				active_list.append(candidate)
				found_valid_point = true
				break
		
		# If no valid point found, remove this active point
		if not found_valid_point:
			active_list.remove_at(active_index)
	
	# If we need more points and ran out of active points, add some randomly
	# This ensures we always get close to target_count
	var safety_attempts = 0
	while points.size() < target_count and safety_attempts < target_count * 10:
		var random_point = Vector2(
			bounds.position.x + randf() * bounds.size.x,
			bounds.position.y + randf() * bounds.size.y
		)
		
		# Use slightly relaxed distance for filling
		if is_valid_position(random_point, points, min_distance * 0.8):
			points.append(random_point)
		
		safety_attempts += 1
	
	GLog.debug("Generated " + str(points.size()) + " Poisson disk positions")
	return points

func is_valid_position(candidate: Vector2, existing_points: Array[Vector2], min_dist: float) -> bool:
	# Check if candidate is too close to any existing point
	for point in existing_points:
		if candidate.distance_to(point) < min_dist:
			return false
	
	# Check if candidate is within bounds
	return bounds.has_point(candidate)

func clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clamp(pos.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)
