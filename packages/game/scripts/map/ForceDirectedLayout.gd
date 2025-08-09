extends RefCounted
class_name ForceDirectedLayout

# Fruchterman-Reingold force-directed layout algorithm
# Optimizes node positions for better visual appearance

const DEBUG_ENABLED: bool = true
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

# Simulation parameters
var iterations: int = 200
var area: float = 0.0  # Will be calculated from viewport
var k_constant: float = 0.0  # Optimal distance between nodes
var temperature: float = 0.0  # Current "heat" for movement
var cooling_factor: float = 0.95
var repulsion_strength: float = 1.0
var attraction_strength: float = 0.8
var boundary_strength: float = 0.3

# Layout bounds
var bounds: Rect2
var center_pull_strength: float = 0.1

# Reference to configuration
var config: MapLayoutConfig

func _init():
	pass

func setup(layout_config: MapLayoutConfig = null):
	config = layout_config
	
	if config:
		iterations = config.physics_iterations
		repulsion_strength = config.physics_repulsion_strength
		attraction_strength = config.physics_attraction_strength
		cooling_factor = config.physics_cooling_rate
		boundary_strength = config.physics_boundary_strength

func apply_layout(graph: Dictionary) -> Dictionary:
	GLog.debug("Starting force-directed layout optimization...")
	
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	if nodes.is_empty():
		GLog.debug("No nodes to layout")
		return graph
	
	# Setup simulation parameters
	setup_simulation(nodes)
	
	# Store original positions for fallback
	var original_positions = {}
	for node_id in nodes:
		original_positions[node_id] = nodes[node_id].position
	
	# Run force-directed simulation
	for iteration in range(iterations):
		var forces = calculate_forces(nodes, edges)
		apply_forces(nodes, forces)
		
		# Cool down the system
		temperature *= cooling_factor
		
		# Debug output every 50 iterations
		if iteration % 50 == 0:
			GLog.debug("Layout iteration " + str(iteration) + "/" + str(iterations) + " - temp: " + str(temperature))
	
	# Validate final positions
	var valid_layout = validate_layout(nodes, original_positions)
	if not valid_layout:
		GLog.warn("Layout validation failed, reverting to original positions")
		# Restore original positions
		for node_id in nodes:
			nodes[node_id].position = original_positions[node_id]
	
	GLog.debug("Force-directed layout complete")
	return graph

func setup_simulation(nodes: Dictionary):
	# Calculate layout area from node positions or use config bounds
	if config and config.bounds_enforce_viewport:
		bounds = Rect2(
			Vector2(config.bounds_margin, config.bounds_margin),
			Vector2(
				config.viewport_size.x - 2 * config.bounds_margin,
				config.viewport_size.y - 2 * config.bounds_margin
			)
		)
		area = bounds.size.x * bounds.size.y
	else:
		# Calculate bounds from current node positions
		var min_pos = Vector2(INF, INF)
		var max_pos = Vector2(-INF, -INF)
		
		for node in nodes.values():
			min_pos.x = min(min_pos.x, node.position.x)
			min_pos.y = min(min_pos.y, node.position.y)
			max_pos.x = max(max_pos.x, node.position.x)
			max_pos.y = max(max_pos.y, node.position.y)
		
		var size = max_pos - min_pos
		# Expand bounds by 20% for breathing room
		size *= 1.2
		bounds = Rect2(min_pos - size * 0.1, size)
		area = size.x * size.y
	
	# Calculate optimal distance between nodes (Fruchterman-Reingold formula)
	k_constant = sqrt(area / nodes.size())
	
	# Initialize temperature (controls initial movement range)
	temperature = sqrt(area) / 10.0
	
	GLog.debug("Layout simulation setup - area: " + str(area) + ", k: " + str(k_constant) + ", initial temp: " + str(temperature))

func calculate_forces(nodes: Dictionary, edges: Array) -> Dictionary:
	var forces = {}
	
	# Initialize forces to zero
	for node_id in nodes:
		forces[node_id] = Vector2.ZERO
	
	# Calculate repulsive forces (all pairs)
	var node_ids = nodes.keys()
	for i in range(node_ids.size()):
		var node_a_id = node_ids[i]
		var node_a = nodes[node_a_id]
		
		for j in range(i + 1, node_ids.size()):
			var node_b_id = node_ids[j]
			var node_b = nodes[node_b_id]
			
			var repulsion = calculate_repulsive_force(node_a, node_b)
			forces[node_a_id] += repulsion
			forces[node_b_id] -= repulsion
	
	# Calculate attractive forces (connected pairs)
	for edge in edges:
		var node_a = nodes.get(edge.from_node)
		var node_b = nodes.get(edge.to_node)
		
		if node_a and node_b:
			var attraction = calculate_attractive_force(node_a, node_b)
			forces[edge.from_node] += attraction
			forces[edge.to_node] -= attraction
	
	# Calculate boundary forces to keep nodes within bounds
	for node_id in nodes:
		var node = nodes[node_id]
		var boundary_force = calculate_boundary_force(node)
		forces[node_id] += boundary_force
	
	return forces

func calculate_repulsive_force(node_a: MapNode, node_b: MapNode) -> Vector2:
	var delta = node_a.position - node_b.position
	var distance = delta.length()
	
	# Avoid division by zero
	if distance < 0.01:
		delta = Vector2(randf() - 0.5, randf() - 0.5).normalized()
		distance = 0.01
	
	# Fruchterman-Reingold repulsion: f_r(d) = k^2 / d
	var force_magnitude = (k_constant * k_constant) / distance * repulsion_strength
	return delta.normalized() * force_magnitude

func calculate_attractive_force(node_a: MapNode, node_b: MapNode) -> Vector2:
	var delta = node_b.position - node_a.position
	var distance = delta.length()
	
	# Fruchterman-Reingold attraction: f_a(d) = d^2 / k
	var force_magnitude = (distance * distance) / k_constant * attraction_strength
	return delta.normalized() * force_magnitude

func calculate_boundary_force(node: MapNode) -> Vector2:
	var force = Vector2.ZERO
	var pos = node.position
	var margin = 50.0  # Distance from boundary where force starts
	
	# Left boundary
	if pos.x < bounds.position.x + margin:
		var distance = bounds.position.x + margin - pos.x
		force.x += (distance / margin) * boundary_strength * k_constant
	
	# Right boundary
	if pos.x > bounds.position.x + bounds.size.x - margin:
		var distance = pos.x - (bounds.position.x + bounds.size.x - margin)
		force.x -= (distance / margin) * boundary_strength * k_constant
	
	# Top boundary
	if pos.y < bounds.position.y + margin:
		var distance = bounds.position.y + margin - pos.y
		force.y += (distance / margin) * boundary_strength * k_constant
	
	# Bottom boundary
	if pos.y > bounds.position.y + bounds.size.y - margin:
		var distance = pos.y - (bounds.position.y + bounds.size.y - margin)
		force.y -= (distance / margin) * boundary_strength * k_constant
	
	return force

func apply_forces(nodes: Dictionary, forces: Dictionary):
	for node_id in nodes:
		var node = nodes[node_id]
		var force = forces.get(node_id, Vector2.ZERO)
		
		# Limit displacement by current temperature
		var displacement = force.normalized() * min(force.length(), temperature)
		
		# Apply displacement
		node.position += displacement
		
		# Keep nodes within bounds (hard constraint)
		node.position = clamp_to_bounds(node.position)

func clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clamp(pos.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clamp(pos.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)

func validate_layout(nodes: Dictionary, original_positions: Dictionary) -> bool:
	# Check if any nodes moved to invalid positions
	for node_id in nodes:
		var node = nodes[node_id]
		
		# Check if position is finite
		if not is_finite(node.position.x) or not is_finite(node.position.y):
			GLog.warn("Node " + node_id + " has invalid position: " + str(node.position))
			return false
		
		# Check if position is within reasonable bounds
		if not bounds.has_point(node.position):
			# Allow some tolerance for boundary violations
			var tolerance = 100.0
			var expanded_bounds = Rect2(bounds.position - Vector2(tolerance, tolerance), bounds.size + Vector2(tolerance * 2, tolerance * 2))
			if not expanded_bounds.has_point(node.position):
				GLog.warn("Node " + node_id + " moved outside reasonable bounds: " + str(node.position))
				return false
	
	# Check for node overlaps (minimum distance validation)
	var min_distance = 20.0  # Minimum allowed distance between nodes
	var node_ids = nodes.keys()
	for i in range(node_ids.size()):
		var node_a = nodes[node_ids[i]]
		for j in range(i + 1, node_ids.size()):
			var node_b = nodes[node_ids[j]]
			var distance = node_a.position.distance_to(node_b.position)
			if distance < min_distance:
				GLog.warn("Nodes too close after layout: " + str(distance))
				return false
	
	return true
