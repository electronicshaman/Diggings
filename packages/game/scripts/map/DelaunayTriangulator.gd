extends RefCounted
class_name DelaunayTriangulator

const DEBUG_ENABLED: bool = false

# Triangle structure for Delaunay triangulation
class Triangle:
	var p1: Vector2
	var p2: Vector2 
	var p3: Vector2
	var circumcenter: Vector2
	var circumradius_squared: float
	
	func _init(point1: Vector2, point2: Vector2, point3: Vector2):
		p1 = point1
		p2 = point2
		p3 = point3
		calculate_circumcircle()
	
	func calculate_circumcircle():
		var ax = p1.x
		var ay = p1.y
		var bx = p2.x
		var by = p2.y
		var cx = p3.x
		var cy = p3.y
		
		var d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
		
		if abs(d) < 1e-10:
			# Degenerate triangle - points are collinear
			circumcenter = (p1 + p2 + p3) / 3.0
			circumradius_squared = INF
			return
		
		var ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
		var uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
		
		circumcenter = Vector2(ux, uy)
		circumradius_squared = circumcenter.distance_squared_to(p1)
	
	func contains_point_in_circumcircle(point: Vector2) -> bool:
		return circumcenter.distance_squared_to(point) < circumradius_squared - 1e-10
	
	func shares_edge_with(other: Triangle) -> bool:
		var shared_vertices = 0
		
		if has_vertex(other.p1):
			shared_vertices += 1
		if has_vertex(other.p2):
			shared_vertices += 1  
		if has_vertex(other.p3):
			shared_vertices += 1
		
		return shared_vertices >= 2
	
	func has_vertex(point: Vector2) -> bool:
		var epsilon = 1e-6
		return p1.distance_to(point) < epsilon or p2.distance_to(point) < epsilon or p3.distance_to(point) < epsilon
	
	func get_vertices() -> Array[Vector2]:
		return [p1, p2, p3]
	
	func _to_string() -> String:
		return "Triangle(" + str(p1) + ", " + str(p2) + ", " + str(p3) + ")"

# Edge structure
class Edge:
	var p1: Vector2
	var p2: Vector2
	
	func _init(point1: Vector2, point2: Vector2):
		# Ensure consistent ordering for edge comparison
		if point1.x < point2.x or (point1.x == point2.x and point1.y < point2.y):
			p1 = point1
			p2 = point2
		else:
			p1 = point2
			p2 = point1
	
	func equals(other: Edge) -> bool:
		var epsilon = 1e-6
		return p1.distance_to(other.p1) < epsilon and p2.distance_to(other.p2) < epsilon
	
	func _to_string() -> String:
		return "Edge(" + str(p1) + " -> " + str(p2) + ")"

# Generate Delaunay triangulation using Bowyer-Watson algorithm
static func triangulate(points: Array[Vector2]) -> Array[Triangle]:
	if points.size() < 3:
		if DEBUG_ENABLED:
			GLog.debug("Cannot triangulate with fewer than 3 points")
		return []
	
	if DEBUG_ENABLED:
		GLog.debug("Starting Delaunay triangulation of " + str(points.size()) + " points")
	
	# Create super triangle that contains all points
	var super_triangle = create_super_triangle(points)
	var triangles: Array[Triangle] = [super_triangle]
	
	if DEBUG_ENABLED:
		GLog.debug("Created super triangle: " + str(super_triangle))
	
	# Add points one by one
	for point in points:
		add_point_to_triangulation(triangles, point)
	
	# Remove triangles that share vertices with super triangle
	var final_triangles: Array[Triangle] = []
	for triangle in triangles:
		if not triangle_uses_super_triangle_vertex(triangle, super_triangle):
			final_triangles.append(triangle)
	
	if DEBUG_ENABLED:
		GLog.debug("Delaunay triangulation complete: " + str(final_triangles.size()) + " triangles")
	
	return final_triangles

# Create a super triangle that contains all points
static func create_super_triangle(points: Array[Vector2]) -> Triangle:
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for point in points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	var dx = max_x - min_x
	var dy = max_y - min_y
	var delta_max = max(dx, dy)
	var mid_x = (min_x + max_x) * 0.5
	var mid_y = (min_y + max_y) * 0.5
	
	# Create super triangle vertices with padding
	var padding = delta_max * 2.0
	var p1 = Vector2(mid_x - padding, mid_y - padding)
	var p2 = Vector2(mid_x + padding, mid_y - padding)
	var p3 = Vector2(mid_x, mid_y + padding)
	
	return Triangle.new(p1, p2, p3)

# Add a single point to existing triangulation
static func add_point_to_triangulation(triangles: Array[Triangle], point: Vector2):
	var bad_triangles: Array[Triangle] = []
	
	# Find all triangles whose circumcircle contains the new point
	for triangle in triangles:
		if triangle.contains_point_in_circumcircle(point):
			bad_triangles.append(triangle)
	
	# Find the boundary of the polygonal hole
	var polygon_edges: Array[Edge] = []
	
	for triangle in bad_triangles:
		var edges = [
			Edge.new(triangle.p1, triangle.p2),
			Edge.new(triangle.p2, triangle.p3),
			Edge.new(triangle.p3, triangle.p1)
		]
		
		for edge in edges:
			# Check if this edge is shared with another bad triangle
			var is_shared = false
			
			for other_triangle in bad_triangles:
				if other_triangle == triangle:
					continue
				
				var other_edges = [
					Edge.new(other_triangle.p1, other_triangle.p2),
					Edge.new(other_triangle.p2, other_triangle.p3),
					Edge.new(other_triangle.p3, other_triangle.p1)
				]
				
				for other_edge in other_edges:
					if edge.equals(other_edge):
						is_shared = true
						break
				
				if is_shared:
					break
			
			# If edge is not shared, it's part of the polygon boundary
			if not is_shared:
				polygon_edges.append(edge)
	
	# Remove bad triangles
	for bad_triangle in bad_triangles:
		triangles.erase(bad_triangle)
	
	# Create new triangles by connecting the point to polygon boundary
	for edge in polygon_edges:
		var new_triangle = Triangle.new(edge.p1, edge.p2, point)
		triangles.append(new_triangle)

# Check if triangle uses any vertex from super triangle
static func triangle_uses_super_triangle_vertex(triangle: Triangle, super_triangle: Triangle) -> bool:
	return triangle.has_vertex(super_triangle.p1) or \
		   triangle.has_vertex(super_triangle.p2) or \
		   triangle.has_vertex(super_triangle.p3)

# Convert triangulation to edges (removes duplicates)
static func triangulation_to_edges(triangles: Array[Triangle]) -> Array[Edge]:
	var edges: Array[Edge] = []
	var edge_set: Dictionary = {}  # Use dictionary to track unique edges
	
	for triangle in triangles:
		var triangle_edges = [
			Edge.new(triangle.p1, triangle.p2),
			Edge.new(triangle.p2, triangle.p3),
			Edge.new(triangle.p3, triangle.p1)
		]
		
		for edge in triangle_edges:
			var edge_key = str(edge.p1) + "->" + str(edge.p2)
			
			if not edge_set.has(edge_key):
				edges.append(edge)
				edge_set[edge_key] = true
	
	return edges

# Convert Delaunay edges to map edges with node IDs
static func edges_to_map_edges(edges: Array[Edge], node_positions: Dictionary) -> Array[MapEdge]:
	var map_edges: Array[MapEdge] = []
	var position_to_node: Dictionary = {}
	
	# Create position to node ID mapping
	for node_id in node_positions:
		var pos = node_positions[node_id]
		position_to_node[str(pos)] = node_id
	
	for edge in edges:
		var from_key = str(edge.p1)
		var to_key = str(edge.p2)
		
		var from_node_id = position_to_node.get(from_key)
		var to_node_id = position_to_node.get(to_key)
		
		if from_node_id and to_node_id:
			var map_edge = MapEdge.new(from_node_id, to_node_id, 2, 1)
			map_edges.append(map_edge)
		elif DEBUG_ENABLED:
			GLog.debug("Could not find node IDs for edge: " + str(edge))
	
	return map_edges

# Generate Delaunay triangulation for map nodes
static func triangulate_map_nodes(graph: Dictionary) -> Dictionary:
	var nodes = graph.get("nodes", {})
	
	if nodes.size() < 3:
		if DEBUG_ENABLED:
			GLog.debug("Cannot triangulate map with fewer than 3 nodes")
		return graph
	
	# Extract positions and create mapping
	var points: Array[Vector2] = []
	var node_positions: Dictionary = {}
	
	for node_id in nodes:
		var node = nodes[node_id]
		points.append(node.position)
		node_positions[node_id] = node.position
	
	# Generate triangulation
	var triangles = triangulate(points)
	var edges = triangulation_to_edges(triangles)
	var map_edges = edges_to_map_edges(edges, node_positions)
	
	if DEBUG_ENABLED:
		GLog.debug("Generated " + str(map_edges.size()) + " edges from Delaunay triangulation")
	
	# Create new graph with triangulated connections
	var new_graph = graph.duplicate(true)
	new_graph["edges"] = map_edges
	
	# Update node connections
	for node_id in nodes:
		var node = nodes[node_id]
		node.connections.clear()
	
	for edge in map_edges:
		var from_node = nodes[edge.from_node]
		var to_node = nodes[edge.to_node]
		
		if from_node and to_node:
			from_node.connections.append(edge.to_node)
			to_node.connections.append(edge.from_node)
	
	return new_graph

# Validate that the triangulation is actually Delaunay
static func validate_delaunay_property(triangles: Array[Triangle], points: Array[Vector2]) -> bool:
	for triangle in triangles:
		for point in points:
			if not triangle.has_vertex(point):
				if triangle.contains_point_in_circumcircle(point):
					if DEBUG_ENABLED:
						GLog.debug("Delaunay property violated: " + str(triangle) + " contains " + str(point))
					return false
	
	return true