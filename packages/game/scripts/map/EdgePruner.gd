extends RefCounted
class_name EdgePruner

const DEBUG_ENABLED: bool = false

# Configuration for edge pruning
class PruningConfig:
	# Distance constraints
	var max_edge_length: float = 250.0
	var min_edge_length: float = 60.0
	
	# Connectivity constraints  
	var min_connections_per_node: int = 1
	var max_connections_per_node: int = 4
	var preserve_start_connections: bool = true
	
	# Gameplay flow constraints
	var preserve_critical_paths: bool = true
	var prevent_shortcuts: bool = true
	var maintain_progression: bool = true
	
	# Pruning aggressiveness (0.0 = minimal pruning, 1.0 = aggressive)
	var pruning_intensity: float = 0.6
	
	func _init():
		pass

# Edge priority for pruning decisions
class EdgePriority:
	var edge: MapEdge
	var priority_score: float  # Lower score = higher priority for removal
	var reasons: Array[String]
	
	func _init(e: MapEdge, score: float):
		edge = e
		priority_score = score
		reasons = []
	
	func add_reason(reason: String):
		reasons.append(reason)
	
	func _to_string() -> String:
		return edge.from_node + "->" + edge.to_node + " (score: " + str(priority_score) + ", reasons: " + str(reasons) + ")"

# Prune edges from a triangulated graph while maintaining important properties
static func prune_triangulation(graph: Dictionary, config: PruningConfig = null) -> Dictionary:
	if not config:
		config = PruningConfig.new()
	
	if DEBUG_ENABLED:
		GLog.debug("Starting edge pruning with " + str(graph.get("edges", []).size()) + " edges")
	
	var result_graph = graph.duplicate(true)
	
	# Phase 1: Remove edges that violate basic constraints
	remove_constraint_violating_edges(result_graph, config)
	
	# Phase 2: Remove edges to reduce density while maintaining connectivity
	reduce_graph_density(result_graph, config)
	
	# Phase 3: Ensure critical gameplay paths are preserved
	preserve_critical_gameplay_paths(result_graph, config)
	
	# Phase 4: Final validation and cleanup
	validate_connectivity(result_graph, config)
	
	if DEBUG_ENABLED:
		GLog.debug("Edge pruning complete: " + str(result_graph.get("edges", []).size()) + " edges remaining")
	
	return result_graph

# Remove edges that violate basic distance and geometric constraints
static func remove_constraint_violating_edges(graph: Dictionary, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	var edges_to_remove: Array[int] = []
	
	for i in range(edges.size()):
		var edge = edges[i]
		var from_node = nodes.get(edge.from_node)
		var to_node = nodes.get(edge.to_node)
		
		if not from_node or not to_node:
			edges_to_remove.append(i)
			continue
		
		var distance = from_node.position.distance_to(to_node.position)
		
		# Remove edges that are too long
		if distance > config.max_edge_length:
			edges_to_remove.append(i)
			if DEBUG_ENABLED:
				GLog.debug("Removing edge " + edge.from_node + "->" + edge.to_node + " (too long: " + str(distance) + ")")
		
		# Remove edges that are too short (likely overlapping nodes)
		elif distance < config.min_edge_length:
			edges_to_remove.append(i)
			if DEBUG_ENABLED:
				GLog.debug("Removing edge " + edge.from_node + "->" + edge.to_node + " (too short: " + str(distance) + ")")
	
	# Remove edges in reverse order to maintain indices
	edges_to_remove.reverse()
	for i in edges_to_remove:
		edges.remove_at(i)
	
	# Update node connections
	update_node_connections(graph)

# Reduce graph density by removing less important edges
static func reduce_graph_density(graph: Dictionary, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	# Calculate target number of edges based on pruning intensity
	var current_edge_count = edges.size()
	var min_edges = max(nodes.size() - 1, nodes.size() * config.min_connections_per_node / 2)  # Minimum for connectivity
	var max_edges = min(current_edge_count, nodes.size() * config.max_connections_per_node / 2)
	
	var target_edges = int(min_edges + (max_edges - min_edges) * (1.0 - config.pruning_intensity))
	
	if DEBUG_ENABLED:
		GLog.debug("Target edges: " + str(target_edges) + " (current: " + str(current_edge_count) + ", min: " + str(min_edges) + ", max: " + str(max_edges) + ")")
	
	if current_edge_count <= target_edges:
		return  # Already at target density
	
	# Prioritize edges for removal
	var edge_priorities = calculate_edge_priorities(graph, config)
	edge_priorities.sort_custom(func(a, b): return a.priority_score > b.priority_score)  # Higher score = more likely to remove
	
	# Remove edges until target is reached
	var edges_removed = 0
	var removal_limit = current_edge_count - target_edges
	
	for priority in edge_priorities:
		if edges_removed >= removal_limit:
			break
		
		# Check if removing this edge would disconnect the graph
		if would_disconnect_graph(graph, priority.edge):
			continue
		
		# Check if removing this edge would violate minimum connections
		if would_violate_min_connections(graph, priority.edge, config):
			continue
		
		# Remove the edge
		remove_edge_from_graph(graph, priority.edge.from_node, priority.edge.to_node)
		edges_removed += 1
		
		if DEBUG_ENABLED:
			GLog.debug("Removed edge: " + str(priority))

# Calculate priority scores for each edge (higher score = more likely to be removed)
static func calculate_edge_priorities(graph: Dictionary, config: PruningConfig) -> Array[EdgePriority]:
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	var priorities: Array[EdgePriority] = []
	
	for edge in edges:
		var from_node = nodes.get(edge.from_node)
		var to_node = nodes.get(edge.to_node)
		
		if not from_node or not to_node:
			continue
		
		var priority = EdgePriority.new(edge, 0.0)
		var distance = from_node.position.distance_to(to_node.position)
		
		# Distance factor - longer edges are more likely to be removed
		var distance_factor = distance / config.max_edge_length
		priority.priority_score += distance_factor * 2.0
		if distance_factor > 0.8:
			priority.add_reason("long_distance")
		
		# Connection density factor - edges connecting highly connected nodes are more likely to be removed
		var from_connections = from_node.connections.size()
		var to_connections = to_node.connections.size()
		var density_factor = (from_connections + to_connections) / float(config.max_connections_per_node * 2)
		priority.priority_score += density_factor * 1.5
		if density_factor > 0.7:
			priority.add_reason("high_density")
		
		# Shortcut factor - edges that create shortcuts might be removed
		if config.prevent_shortcuts and creates_shortcut(graph, edge):
			priority.priority_score += 1.0
			priority.add_reason("creates_shortcut")
		
		# Start node protection - edges from start node are less likely to be removed
		if config.preserve_start_connections and (edge.from_node == graph.get("start_node") or edge.to_node == graph.get("start_node")):
			priority.priority_score -= 2.0
			priority.add_reason("start_connection")
		
		# Node type importance - connections to important nodes are preserved
		var importance_bonus = calculate_node_importance_bonus(from_node, to_node)
		priority.priority_score -= importance_bonus
		if importance_bonus > 0:
			priority.add_reason("important_nodes")
		
		priorities.append(priority)
	
	return priorities

# Check if an edge creates a shortcut that bypasses important nodes
static func creates_shortcut(graph: Dictionary, edge: MapEdge) -> bool:
	var nodes = graph.get("nodes", {})
	var from_node = nodes.get(edge.from_node)
	var to_node = nodes.get(edge.to_node)
	
	if not from_node or not to_node:
		return false
	
	# Simple shortcut detection: if the direct distance is much shorter than
	# the shortest path through the graph, it might be a shortcut
	var direct_distance = from_node.position.distance_to(to_node.position)
	
	# This is a simplified check - a full implementation would use pathfinding
	# to find the shortest alternative path
	var has_alternative_path = from_node.connections.size() > 1 and to_node.connections.size() > 1
	
	# Consider it a potential shortcut if it's a long connection between well-connected nodes
	return has_alternative_path and direct_distance > 150.0

# Calculate importance bonus based on node types
static func calculate_node_importance_bonus(from_node: MapNode, to_node: MapNode) -> float:
	var bonus = 0.0
	
	# Important node types get higher preservation priority
	var important_types = [MapNode.NodeType.CITY, MapNode.NodeType.CAMP, MapNode.NodeType.BOSS]
	
	if from_node.type in important_types:
		bonus += 1.0
	if to_node.type in important_types:
		bonus += 1.0
	
	# Special bonus for connections between different important types
	if from_node.type in important_types and to_node.type in important_types and from_node.type != to_node.type:
		bonus += 0.5
	
	return bonus

# Check if removing an edge would disconnect the graph
static func would_disconnect_graph(graph: Dictionary, edge: MapEdge) -> bool:
	# Create a temporary graph without this edge
	var temp_graph = graph.duplicate(true)
	remove_edge_from_graph(temp_graph, edge.from_node, edge.to_node)
	
	# Check connectivity using simple BFS
	return not is_graph_connected(temp_graph)

# Check if removing an edge would violate minimum connection requirements
static func would_violate_min_connections(graph: Dictionary, edge: MapEdge, config: PruningConfig) -> bool:
	var nodes = graph.get("nodes", {})
	var from_node = nodes.get(edge.from_node)
	var to_node = nodes.get(edge.to_node)
	
	if not from_node or not to_node:
		return false
	
	# Check if either node would have too few connections after removal
	return from_node.connections.size() <= config.min_connections_per_node or \
		   to_node.connections.size() <= config.min_connections_per_node

# Preserve critical paths for gameplay progression
static func preserve_critical_gameplay_paths(graph: Dictionary, config: PruningConfig):
	if not config.preserve_critical_paths:
		return
	
	var nodes = graph.get("nodes", {})
	var start_node_id = graph.get("start_node", "")
	
	if start_node_id == "":
		return
	
	# Find important destination nodes (boss, city, etc.)
	var important_destinations: Array[String] = []
	
	for node_id in nodes:
		var node = nodes[node_id]
		if node.type in [MapNode.NodeType.BOSS, MapNode.NodeType.CITY]:
			important_destinations.append(node_id)
	
	# Ensure paths exist from start to all important destinations
	for dest_id in important_destinations:
		if not has_path(graph, start_node_id, dest_id):
			# Try to restore a minimal path
			restore_minimal_path(graph, start_node_id, dest_id, config)

# Check if a path exists between two nodes (simple BFS)
static func has_path(graph: Dictionary, from_id: String, to_id: String) -> bool:
	if from_id == to_id:
		return true
	
	var nodes = graph.get("nodes", {})
	var visited: Dictionary = {}
	var queue: Array[String] = [from_id]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current == to_id:
			return true
		
		if current in visited:
			continue
		
		visited[current] = true
		var node = nodes.get(current)
		
		if node:
			for connected in node.connections:
				if connected not in visited:
					queue.append(connected)
	
	return false

# Restore a minimal path between two nodes
static func restore_minimal_path(graph: Dictionary, from_id: String, to_id: String, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	var from_node = nodes.get(from_id)
	var to_node = nodes.get(to_id)
	
	if not from_node or not to_node:
		return
	
	# Simple approach: connect directly if distance allows
	var distance = from_node.position.distance_to(to_node.position)
	
	if distance <= config.max_edge_length:
		# Add direct connection
		var new_edge = MapEdge.new(from_id, to_id, 2, 1)
		graph.edges.append(new_edge)
		from_node.connections.append(to_id)
		to_node.connections.append(from_id)
		
		if DEBUG_ENABLED:
			GLog.debug("Restored direct path: " + from_id + " -> " + to_id)

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

# Update all node connections based on current edges
static func update_node_connections(graph: Dictionary):
	var nodes = graph.get("nodes", {})
	var edges = graph.get("edges", [])
	
	# Clear all connections
	for node_id in nodes:
		var node = nodes[node_id]
		node.connections.clear()
	
	# Rebuild connections from edges
	for edge in edges:
		var from_node = nodes.get(edge.from_node)
		var to_node = nodes.get(edge.to_node)
		
		if from_node and to_node:
			if edge.to_node not in from_node.connections:
				from_node.connections.append(edge.to_node)
			if edge.from_node not in to_node.connections:
				to_node.connections.append(edge.from_node)

# Check if graph is connected using BFS
static func is_graph_connected(graph: Dictionary) -> bool:
	var nodes = graph.get("nodes", {})
	
	if nodes.is_empty():
		return true
	
	var visited: Dictionary = {}
	var start_node = nodes.keys()[0]
	var queue: Array[String] = [start_node]
	
	while not queue.is_empty():
		var current = queue.pop_front()
		
		if current in visited:
			continue
		
		visited[current] = true
		var node = nodes[current]
		
		for connected in node.connections:
			if connected not in visited:
				queue.append(connected)
	
	return visited.size() == nodes.size()

# Final validation to ensure graph meets all constraints
static func validate_connectivity(graph: Dictionary, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	
	# Ensure minimum connections per node
	for node_id in nodes:
		var node = nodes[node_id]
		
		if node.connections.size() < config.min_connections_per_node:
			# Try to add connections to nearby nodes
			add_minimal_connections(graph, node_id, config)
	
	# Final connectivity check
	if not is_graph_connected(graph):
		GLog.warn("Graph became disconnected during pruning - attempting to reconnect")
		reconnect_graph(graph, config)

# Add minimal connections to ensure node meets minimum requirements
static func add_minimal_connections(graph: Dictionary, node_id: String, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	var node = nodes.get(node_id)
	
	if not node:
		return
	
	var needed_connections = config.min_connections_per_node - node.connections.size()
	if needed_connections <= 0:
		return
	
	# Find nearest unconnected nodes
	var candidates: Array = []
	
	for other_id in nodes:
		if other_id == node_id or other_id in node.connections:
			continue
		
		var other_node = nodes[other_id]
		var distance = node.position.distance_to(other_node.position)
		
		if distance <= config.max_edge_length:
			candidates.append({"id": other_id, "distance": distance})
	
	# Sort by distance and connect to nearest
	candidates.sort_custom(func(a, b): return a.distance < b.distance)
	
	var connections_added = 0
	for candidate in candidates:
		if connections_added >= needed_connections:
			break
		
		var new_edge = MapEdge.new(node_id, candidate.id, 2, 1)
		graph.edges.append(new_edge)
		node.connections.append(candidate.id)
		nodes[candidate.id].connections.append(node_id)
		connections_added += 1
		
		if DEBUG_ENABLED:
			GLog.debug("Added minimal connection: " + node_id + " -> " + candidate.id)

# Reconnect a disconnected graph
static func reconnect_graph(graph: Dictionary, config: PruningConfig):
	var nodes = graph.get("nodes", {})
	
	if nodes.is_empty():
		return
	
	# Find connected components
	var components = find_connected_components(graph)
	
	if components.size() <= 1:
		return  # Already connected
	
	if DEBUG_ENABLED:
		GLog.debug("Found " + str(components.size()) + " disconnected components")
	
	# Connect components by finding shortest connections between them
	for i in range(1, components.size()):
		var component_a = components[0]  # Main component
		var component_b = components[i]
		
		var shortest_connection = find_shortest_connection_between_components(graph, component_a, component_b, config)
		
		if shortest_connection.has("from") and shortest_connection.has("to"):
			var new_edge = MapEdge.new(shortest_connection.from, shortest_connection.to, 2, 1)
			graph.edges.append(new_edge)
			nodes[shortest_connection.from].connections.append(shortest_connection.to)
			nodes[shortest_connection.to].connections.append(shortest_connection.from)
			
			if DEBUG_ENABLED:
				GLog.debug("Reconnected components: " + shortest_connection.from + " -> " + shortest_connection.to)

# Find all connected components in the graph
static func find_connected_components(graph: Dictionary) -> Array[Array]:
	var nodes = graph.get("nodes", {})
	var visited: Dictionary = {}
	var components: Array[Array] = []
	
	for node_id in nodes:
		if node_id in visited:
			continue
		
		var component: Array[String] = []
		var queue: Array[String] = [node_id]
		
		while not queue.is_empty():
			var current = queue.pop_front()
			
			if current in visited:
				continue
			
			visited[current] = true
			component.append(current)
			var node = nodes[current]
			
			for connected in node.connections:
				if connected not in visited:
					queue.append(connected)
		
		components.append(component)
	
	return components

# Find shortest connection between two components
static func find_shortest_connection_between_components(graph: Dictionary, component_a: Array, component_b: Array, config: PruningConfig) -> Dictionary:
	var nodes = graph.get("nodes", {})
	var shortest_distance = INF
	var best_connection = {}
	
	for node_a_id in component_a:
		var node_a = nodes[node_a_id]
		
		for node_b_id in component_b:
			var node_b = nodes[node_b_id]
			var distance = node_a.position.distance_to(node_b.position)
			
			if distance < shortest_distance and distance <= config.max_edge_length:
				shortest_distance = distance
				best_connection = {"from": node_a_id, "to": node_b_id, "distance": distance}
	
	return best_connection