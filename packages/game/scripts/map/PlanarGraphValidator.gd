extends RefCounted
class_name PlanarGraphValidator

const DEBUG_ENABLED: bool = false
const LineSegment = preload("res://scripts/map/LineSegment.gd")

# Structure to store crossing information
class EdgeCrossing:
	var edge1: MapEdge
	var edge2: MapEdge
	var intersection_point: Vector2
	var segment1: LineSegment
	var segment2: LineSegment
	
	func _init(e1: MapEdge, e2: MapEdge, point: Vector2, seg1: LineSegment, seg2: LineSegment):
		edge1 = e1
		edge2 = e2
		intersection_point = point
		segment1 = seg1
		segment2 = seg2
	
	func _to_string() -> String:
		return "EdgeCrossing: " + edge1.from_node + "->" + edge1.to_node + " X " + edge2.from_node + "->" + edge2.to_node + " at " + str(intersection_point)

# Validate if a graph is planar (has no edge crossings)
static func is_graph_planar(graph: Dictionary) -> bool:
	var crossings = find_edge_crossings(graph)
	return crossings.is_empty()

# Find all edge crossings in a graph
static func find_edge_crossings(graph: Dictionary) -> Array[EdgeCrossing]:
	var crossings: Array[EdgeCrossing] = []
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	if nodes.is_empty() or edges.is_empty():
		return crossings
	
	# Create line segments for all edges
	var segments: Array[LineSegment] = []
	var segment_to_edge: Array[MapEdge] = []
	
	for edge in edges:
		var from_node = nodes.get(edge.from_node)
		var to_node = nodes.get(edge.to_node)
		
		if from_node and to_node:
			var segment = LineSegment.new(from_node.position, to_node.position)
			segments.append(segment)
			segment_to_edge.append(edge)
	
	# Check all pairs of segments for intersections
	for i in range(segments.size()):
		for j in range(i + 1, segments.size()):
			var seg1 = segments[i]
			var seg2 = segments[j]
			
			if seg1.intersects_with(seg2):
				var intersection_point = seg1.get_intersection_point(seg2)
				var crossing = EdgeCrossing.new(
					segment_to_edge[i], 
					segment_to_edge[j], 
					intersection_point, 
					seg1, 
					seg2
				)
				crossings.append(crossing)
	
	if DEBUG_ENABLED:
		GLog.debug("Found " + str(crossings.size()) + " edge crossings")
		for crossing in crossings:
			GLog.debug("  " + str(crossing))
	
	return crossings

# Check if adding a new edge would create crossings
static func would_edge_create_crossing(graph: Dictionary, from_node_id: String, to_node_id: String) -> bool:
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	var from_node = nodes.get(from_node_id)
	var to_node = nodes.get(to_node_id)
	
	if not from_node or not to_node:
		return false
	
	var new_segment = LineSegment.new(from_node.position, to_node.position)
	
	# Check if new segment intersects with any existing edge
	for edge in edges:
		var edge_from = nodes.get(edge.from_node)
		var edge_to = nodes.get(edge.to_node)
		
		if edge_from and edge_to:
			var existing_segment = LineSegment.new(edge_from.position, edge_to.position)
			
			if new_segment.intersects_with(existing_segment):
				if DEBUG_ENABLED:
					GLog.debug("New edge " + from_node_id + "->" + to_node_id + " would intersect with " + edge.from_node + "->" + edge.to_node)
				return true
	
	return false

# Get all edges that would be crossed by a potential new edge
static func get_crossing_edges(graph: Dictionary, from_node_id: String, to_node_id: String) -> Array[MapEdge]:
	var crossing_edges: Array[MapEdge] = []
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	var from_node = nodes.get(from_node_id)
	var to_node = nodes.get(to_node_id)
	
	if not from_node or not to_node:
		return crossing_edges
	
	var new_segment = LineSegment.new(from_node.position, to_node.position)
	
	for edge in edges:
		var edge_from = nodes.get(edge.from_node)
		var edge_to = nodes.get(edge.to_node)
		
		if edge_from and edge_to:
			var existing_segment = LineSegment.new(edge_from.position, edge_to.position)
			
			if new_segment.intersects_with(existing_segment):
				crossing_edges.append(edge)
	
	return crossing_edges

# Remove crossing edges to make graph planar (greedy approach)
static func make_graph_planar_greedy(graph: Dictionary) -> Dictionary:
	var result_graph = graph.duplicate(true)
	var removed_edges: Array[MapEdge] = []
	
	while true:
		var crossings = find_edge_crossings(result_graph)
		
		if crossings.is_empty():
			break  # Graph is now planar
		
		# Find the edge involved in the most crossings
		var edge_crossing_count: Dictionary = {}
		
		for crossing in crossings:
			var edge1_key = crossing.edge1.from_node + "->" + crossing.edge1.to_node
			var edge2_key = crossing.edge2.from_node + "->" + crossing.edge2.to_node
			
			edge_crossing_count[edge1_key] = edge_crossing_count.get(edge1_key, 0) + 1
			edge_crossing_count[edge2_key] = edge_crossing_count.get(edge2_key, 0) + 1
		
		# Find the edge with maximum crossings
		var max_crossings = 0
		var worst_edge_key = ""
		
		for edge_key in edge_crossing_count:
			if edge_crossing_count[edge_key] > max_crossings:
				max_crossings = edge_crossing_count[edge_key]
				worst_edge_key = edge_key
		
		# Remove the worst edge
		if worst_edge_key != "":
			var parts = worst_edge_key.split("->")
			if parts.size() == 2:
				remove_edge_from_graph(result_graph, parts[0], parts[1])
				
				if DEBUG_ENABLED:
					GLog.debug("Removed edge " + worst_edge_key + " (involved in " + str(max_crossings) + " crossings)")
	
	if DEBUG_ENABLED:
		GLog.debug("Made graph planar by removing " + str(removed_edges.size()) + " edges")
	
	return result_graph

# Remove an edge from the graph
static func remove_edge_from_graph(graph: Dictionary, from_node_id: String, to_node_id: String):
	var edges = graph.get("edges", [])
	var nodes = graph.get("nodes", {})
	
	# Remove from edges array
	for i in range(edges.size() - 1, -1, -1):
		var edge = edges[i]
		if (edge.from_node == from_node_id and edge.to_node == to_node_id) or \
		   (edge.from_node == to_node_id and edge.to_node == from_node_id):
			edges.remove_at(i)
	
	# Remove from node connections
	var from_node = nodes.get(from_node_id)
	var to_node = nodes.get(to_node_id)
	
	if from_node:
		from_node.connections.erase(to_node_id)
	if to_node:
		to_node.connections.erase(from_node_id)

# Generate a comprehensive planarity report
static func generate_planarity_report(graph: Dictionary) -> Dictionary:
	var crossings = find_edge_crossings(graph)
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	# Calculate statistics
	var total_possible_edges = nodes.size() * (nodes.size() - 1) / 2
	var planar_upper_bound = max(0, 3 * nodes.size() - 6) if nodes.size() >= 3 else total_possible_edges
	
	# Count edges with crossings
	var edges_with_crossings = {}
	for crossing in crossings:
		edges_with_crossings[crossing.edge1.from_node + "->" + crossing.edge1.to_node] = true
		edges_with_crossings[crossing.edge2.from_node + "->" + crossing.edge2.to_node] = true
	
	var report = {
		"is_planar": crossings.is_empty(),
		"total_nodes": nodes.size(),
		"total_edges": edges.size(),
		"total_crossings": crossings.size(),
		"edges_with_crossings": edges_with_crossings.size(),
		"planar_upper_bound": planar_upper_bound,
		"exceeds_planar_bound": edges.size() > planar_upper_bound,
		"crossing_details": []
	}
	
	# Add detailed crossing information
	for crossing in crossings:
		report.crossing_details.append({
			"edge1": crossing.edge1.from_node + "->" + crossing.edge1.to_node,
			"edge2": crossing.edge2.from_node + "->" + crossing.edge2.to_node,
			"intersection_point": crossing.intersection_point
		})
	
	return report

# Validate graph connectivity after making it planar
static func is_graph_connected(graph: Dictionary) -> bool:
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	if nodes.is_empty():
		return true
	
	if edges.is_empty() and nodes.size() > 1:
		return false
	
	# Use DFS to check connectivity
	var visited = {}
	var start_node = nodes.keys()[0]
	var stack = [start_node]
	
	while not stack.is_empty():
		var current = stack.pop_back()
		
		if current in visited:
			continue
		
		visited[current] = true
		
		# Add connected nodes to stack
		var node = nodes[current]
		if node and node.has_method("get") and "connections" in node:
			for connected in node.connections:
				if connected not in visited:
					stack.append(connected)
	
	return visited.size() == nodes.size()