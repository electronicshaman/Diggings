extends RefCounted
class_name ForceDirectedLayout

# Fruchterman-Reingold force-directed layout algorithm
# Optimizes node positions for better visual appearance

const DEBUG_ENABLED: bool = false
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

# Edge crossing minimization parameters
var edge_crossing_penalty: float = 0.5
var angular_distribution_strength: float = 0.3
var edge_separation_distance: float = 30.0
var crossing_iterations: int = 50

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
		
		# Edge crossing minimization parameters (with fallbacks)
		edge_crossing_penalty = config.physics_edge_crossing_penalty if "physics_edge_crossing_penalty" in config else 0.5
		angular_distribution_strength = config.physics_angular_distribution_strength if "physics_angular_distribution_strength" in config else 0.3
		edge_separation_distance = config.physics_edge_separation_distance if "physics_edge_separation_distance" in config else 30.0
		crossing_iterations = config.physics_crossing_iterations if "physics_crossing_iterations" in config else 50

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
	
	# Run additional edge-crossing minimization phase if enabled
	if edge_crossing_penalty > 0.0 and crossing_iterations > 0:
		GLog.debug("Starting edge-crossing minimization phase...")
		minimize_edge_crossings(nodes, edges)
	
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

func minimize_edge_crossings(nodes: Dictionary, edges: Array):
	"""Additional optimization phase focused on reducing edge crossings"""
	var crossing_temperature = temperature * 0.5  # Start with lower temperature
	var initial_crossings = count_edge_crossings(edges, nodes)
	
	GLog.debug("Initial edge crossings: " + str(initial_crossings))
	
	for iteration in range(crossing_iterations):
		var forces = calculate_edge_crossing_forces(nodes, edges)
		
		# Apply forces with crossing-specific temperature
		for node_id in nodes:
			var node = nodes[node_id]
			var force = forces.get(node_id, Vector2.ZERO)
			
			# Limit displacement by crossing temperature
			var displacement = force.normalized() * min(force.length(), crossing_temperature)
			node.position += displacement
			node.position = clamp_to_bounds(node.position)
		
		# Cool down crossing temperature
		crossing_temperature *= cooling_factor
		
		if iteration % 25 == 0:
			var current_crossings = count_edge_crossings(edges, nodes)
			GLog.debug("Crossing iteration " + str(iteration) + "/" + str(crossing_iterations) + " - crossings: " + str(current_crossings))
	
	var final_crossings = count_edge_crossings(edges, nodes)
	GLog.debug("Final edge crossings: " + str(final_crossings) + " (reduced by " + str(initial_crossings - final_crossings) + ")")

func calculate_edge_crossing_forces(nodes: Dictionary, edges: Array) -> Dictionary:
	"""Calculate forces to minimize edge crossings and improve angular distribution"""
	var forces = {}
	
	# Initialize forces
	for node_id in nodes:
		forces[node_id] = Vector2.ZERO
	
	# Edge-crossing forces
	if edge_crossing_penalty > 0.0:
		add_crossing_reduction_forces(forces, nodes, edges)
	
	# Angular distribution forces
	if angular_distribution_strength > 0.0:
		add_angular_distribution_forces(forces, nodes, edges)
	
	# Edge separation forces
	if edge_separation_distance > 0.0:
		add_edge_separation_forces(forces, nodes, edges)
	
	return forces

func add_crossing_reduction_forces(forces: Dictionary, nodes: Dictionary, edges: Array):
	"""Add forces to reduce edge crossings"""
	for i in range(edges.size()):
		var edge1 = edges[i]
		var node1_a = nodes.get(edge1.from_node)
		var node1_b = nodes.get(edge1.to_node)
		
		if not node1_a or not node1_b:
			continue
		
		for j in range(i + 1, edges.size()):
			var edge2 = edges[j]
			var node2_a = nodes.get(edge2.from_node)
			var node2_b = nodes.get(edge2.to_node)
			
			if not node2_a or not node2_b:
				continue
			
			# Skip if edges share a node
			if edge1.from_node == edge2.from_node or edge1.from_node == edge2.to_node or \
			   edge1.to_node == edge2.from_node or edge1.to_node == edge2.to_node:
				continue
			
			# Check if edges cross
			var crossing_point = line_intersection(node1_a.position, node1_b.position, node2_a.position, node2_b.position)
			if crossing_point != Vector2.ZERO:
				# Apply forces to reduce crossing
				var force_magnitude = edge_crossing_penalty * k_constant * 0.5
				
				# Calculate force directions to separate the crossing
				var edge1_mid = (node1_a.position + node1_b.position) * 0.5
				var edge2_mid = (node2_a.position + node2_b.position) * 0.5
				var separation_dir = (edge1_mid - edge2_mid).normalized()
				
				if separation_dir.length() < 0.1:
					separation_dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
				
				var force_vec = separation_dir * force_magnitude
				
				# Apply forces to edge1 nodes
				forces[edge1.from_node] += force_vec
				forces[edge1.to_node] += force_vec
				
				# Apply opposite forces to edge2 nodes
				forces[edge2.from_node] -= force_vec
				forces[edge2.to_node] -= force_vec

func add_angular_distribution_forces(forces: Dictionary, nodes: Dictionary, edges: Array):
	"""Add forces to better distribute edge angles around nodes"""
	for node_id in nodes:
		var node = nodes[node_id]
		var connections = []
		
		# Find all connections for this node
		for edge in edges:
			if edge.from_node == node_id:
				var other_node = nodes.get(edge.to_node)
				if other_node:
					connections.append(other_node)
			elif edge.to_node == node_id:
				var other_node = nodes.get(edge.from_node)
				if other_node:
					connections.append(other_node)
		
		# Apply angular distribution forces if node has multiple connections
		if connections.size() >= 3:
			apply_angular_distribution_to_node(forces, nodes, node, connections, node_id)

func apply_angular_distribution_to_node(forces: Dictionary, nodes: Dictionary, center_node: MapNode, connected_nodes: Array, center_id: String):
	"""Apply forces to distribute connections more evenly around a node"""
	var angles = []
	var node_angles = {}
	
	# Calculate current angles
	for connected_node in connected_nodes:
		var direction = connected_node.position - center_node.position
		var angle = atan2(direction.y, direction.x)
		angles.append(angle)
		node_angles[connected_node] = angle
	
	# Sort angles
	angles.sort()
	
	# Calculate ideal angular separation
	var ideal_separation = TAU / connected_nodes.size()
	var force_magnitude = angular_distribution_strength * k_constant * 0.3
	
	# Apply forces to improve angular distribution
	for i in range(connected_nodes.size()):
		var current_angle = angles[i]
		var next_angle = angles[(i + 1) % angles.size()]
		var prev_angle = angles[(i - 1) % angles.size()]
		
		# Calculate angular gaps
		var gap_next = angle_difference(current_angle, next_angle)
		var gap_prev = angle_difference(prev_angle, current_angle)
		
		# Find the node with this angle
		var target_node = null
		var target_id = ""
		for node in connected_nodes:
			if abs(node_angles[node] - current_angle) < 0.1:
				target_node = node
				# Find the node ID
				for node_id in forces:
					if nodes.get(node_id) == node:
						target_id = node_id
						break
				break
		
		if not target_node or target_id == "":
			continue
		
		# Apply force to balance angular spacing
		var angle_adjustment = 0.0
		if gap_next < ideal_separation * 0.8:
			angle_adjustment -= 0.2  # Push away from next
		if gap_prev < ideal_separation * 0.8:
			angle_adjustment += 0.2  # Push away from previous
		
		if abs(angle_adjustment) > 0.01:
			var adjusted_angle = current_angle + angle_adjustment
			var force_direction = Vector2(cos(adjusted_angle), sin(adjusted_angle))
			var force_vec = force_direction * force_magnitude
			
			forces[target_id] += force_vec

func add_edge_separation_forces(forces: Dictionary, nodes: Dictionary, edges: Array):
	"""Add forces to separate parallel or nearly parallel edges"""
	for i in range(edges.size()):
		var edge1 = edges[i]
		var node1_a = nodes.get(edge1.from_node)
		var node1_b = nodes.get(edge1.to_node)
		
		if not node1_a or not node1_b:
			continue
		
		for j in range(i + 1, edges.size()):
			var edge2 = edges[j]
			var node2_a = nodes.get(edge2.from_node)
			var node2_b = nodes.get(edge2.to_node)
			
			if not node2_a or not node2_b:
				continue
			
			# Skip if edges share a node
			if edge1.from_node == edge2.from_node or edge1.from_node == edge2.to_node or \
			   edge1.to_node == edge2.from_node or edge1.to_node == edge2.to_node:
				continue
			
			# Check if edges are nearly parallel and close
			var edge1_dir = (node1_b.position - node1_a.position).normalized()
			var edge2_dir = (node2_b.position - node2_a.position).normalized()
			var dot_product = abs(edge1_dir.dot(edge2_dir))
			
			if dot_product > 0.8:  # Edges are nearly parallel
				var edge1_mid = (node1_a.position + node1_b.position) * 0.5
				var edge2_mid = (node2_a.position + node2_b.position) * 0.5
				var distance = edge1_mid.distance_to(edge2_mid)
				
				if distance < edge_separation_distance:
					# Apply separation forces
					var force_magnitude = (edge_separation_distance - distance) / edge_separation_distance * k_constant * 0.3
					var separation_dir = (edge1_mid - edge2_mid).normalized()
					
					if separation_dir.length() < 0.1:
						separation_dir = Vector2(randf() - 0.5, randf() - 0.5).normalized()
					
					var force_vec = separation_dir * force_magnitude
					
					forces[edge1.from_node] += force_vec
					forces[edge1.to_node] += force_vec
					forces[edge2.from_node] -= force_vec
					forces[edge2.to_node] -= force_vec

func count_edge_crossings(edges: Array, nodes: Dictionary) -> int:
	"""Count the number of edge crossings in the current layout"""
	var crossings = 0
	
	for i in range(edges.size()):
		var edge1 = edges[i]
		var node1_a = nodes.get(edge1.from_node)
		var node1_b = nodes.get(edge1.to_node)
		
		if not node1_a or not node1_b:
			continue
		
		for j in range(i + 1, edges.size()):
			var edge2 = edges[j]
			var node2_a = nodes.get(edge2.from_node)
			var node2_b = nodes.get(edge2.to_node)
			
			if not node2_a or not node2_b:
				continue
			
			# Skip if edges share a node
			if edge1.from_node == edge2.from_node or edge1.from_node == edge2.to_node or \
			   edge1.to_node == edge2.from_node or edge1.to_node == edge2.to_node:
				continue
			
			# Check if edges cross
			var crossing_point = line_intersection(node1_a.position, node1_b.position, node2_a.position, node2_b.position)
			if crossing_point != Vector2.ZERO:
				crossings += 1
	
	return crossings

func line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> Vector2:
	"""Calculate intersection point of two line segments, return Vector2.ZERO if no intersection"""
	var d1 = p2 - p1
	var d2 = p4 - p3
	var d3 = p1 - p3
	
	var cross_d1_d2 = d1.x * d2.y - d1.y * d2.x
	if abs(cross_d1_d2) < 0.001:  # Lines are parallel
		return Vector2.ZERO
	
	var t1 = (d3.x * d2.y - d3.y * d2.x) / cross_d1_d2
	var t2 = (d3.x * d1.y - d3.y * d1.x) / cross_d1_d2
	
	# Check if intersection is within both line segments
	if t1 >= 0.0 and t1 <= 1.0 and t2 >= 0.0 and t2 <= 1.0:
		return p1 + t1 * d1
	
	return Vector2.ZERO

func angle_difference(angle1: float, angle2: float) -> float:
	"""Calculate the smaller angle difference between two angles"""
	var diff = angle2 - angle1
	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return abs(diff)

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
