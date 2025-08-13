extends Control

# Simple force-directed graph layout experiment
# Press SPACE to generate a new random graph

class GraphNode:
	var id: String
	var position: Vector2
	var velocity: Vector2 = Vector2.ZERO
	var connections: Array[String] = []
	
	func _init(node_id: String, pos: Vector2):
		id = node_id
		position = pos

var nodes: Dictionary = {}  # id -> GraphNode
var edges: Array = []  # Array of [from_id, to_id] pairs

# Force-directed parameters
const REPULSION_STRENGTH: float = 5000.0
const SPRING_STRENGTH: float = 0.01
const SPRING_LENGTH: float = 150.0
const DAMPING: float = 0.9
const ITERATIONS: int = 100

# Visual parameters
const NODE_RADIUS: float = 12.0
const NODE_COLOR: Color = Color.WHITE
const EDGE_COLOR: Color = Color(0.5, 0.5, 0.5, 0.7)
const BACKGROUND_COLOR: Color = Color(0.1, 0.1, 0.15)

func _ready():
	print("=== Force-Directed Graph Test ===")
	print("Press SPACE to generate a new graph")
	
	# Set up full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Generate initial graph
	generate_random_graph()
	apply_force_directed_layout()

func generate_random_graph():
	nodes.clear()
	edges.clear()
	
	# Create 20-30 nodes
	var node_count = randi_range(20, 30)
	print("Generating graph with ", node_count, " nodes")
	
	# Create nodes with random initial positions
	for i in range(node_count):
		var node_id = "node_" + str(i)
		var random_pos = Vector2(
			randf_range(100, size.x - 100),
			randf_range(100, size.y - 100)
		)
		nodes[node_id] = GraphNode.new(node_id, random_pos)
	
	# Create random connections
	# Each node connects to 2-4 other nodes
	var node_ids = nodes.keys()
	for node_id in node_ids:
		var connection_count = randi_range(2, 4)
		var node = nodes[node_id]
		
		for j in range(connection_count):
			# Pick a random target that isn't already connected
			var attempts = 0
			while attempts < 10:
				var target_id = node_ids[randi() % node_ids.size()]
				
				# Don't connect to self or already connected nodes
				if target_id != node_id and target_id not in node.connections:
					# Add bidirectional connection
					node.connections.append(target_id)
					nodes[target_id].connections.append(node_id)
					
					# Add edge (avoid duplicates)
					var edge_exists = false
					for edge in edges:
						if (edge[0] == node_id and edge[1] == target_id) or \
						   (edge[0] == target_id and edge[1] == node_id):
							edge_exists = true
							break
					
					if not edge_exists:
						edges.append([node_id, target_id])
					break
				attempts += 1
	
	print("Created ", edges.size(), " edges")

func apply_force_directed_layout():
	print("Applying force-directed layout...")
	
	# Run simulation for fixed number of iterations
	for iteration in range(ITERATIONS):
		# Reset velocities
		for node in nodes.values():
			node.velocity = Vector2.ZERO
		
		# Apply repulsion forces between all node pairs
		var node_array = nodes.values()
		for i in range(node_array.size()):
			for j in range(i + 1, node_array.size()):
				var node_a = node_array[i]
				var node_b = node_array[j]
				
				var delta = node_b.position - node_a.position
				var distance = delta.length()
				
				if distance > 0 and distance < 500:  # Cutoff for performance
					var repulsion = delta.normalized() * (REPULSION_STRENGTH / (distance * distance))
					node_a.velocity -= repulsion
					node_b.velocity += repulsion
		
		# Apply spring forces along edges
		for edge in edges:
			var node_a = nodes[edge[0]]
			var node_b = nodes[edge[1]]
			
			var delta = node_b.position - node_a.position
			var distance = delta.length()
			
			if distance > 0:
				var spring_force = delta.normalized() * SPRING_STRENGTH * (distance - SPRING_LENGTH)
				node_a.velocity += spring_force
				node_b.velocity -= spring_force
		
		# Apply center gravity to keep graph on screen
		var center = size / 2
		for node in nodes.values():
			var to_center = center - node.position
			node.velocity += to_center * 0.0001
		
		# Update positions with damping
		for node in nodes.values():
			node.velocity *= DAMPING
			node.position += node.velocity
			
			# Keep nodes on screen
			node.position.x = clamp(node.position.x, NODE_RADIUS, size.x - NODE_RADIUS)
			node.position.y = clamp(node.position.y, NODE_RADIUS, size.y - NODE_RADIUS)
	
	print("Layout complete")
	queue_redraw()

func _draw():
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	
	# Draw edges
	for edge in edges:
		var from_pos = nodes[edge[0]].position
		var to_pos = nodes[edge[1]].position
		draw_line(from_pos, to_pos, EDGE_COLOR, 2.0)
	
	# Draw nodes
	for node in nodes.values():
		draw_circle(node.position, NODE_RADIUS, NODE_COLOR)
		
		# Draw node ID (optional - comment out for cleaner look)
		var font = ThemeDB.fallback_font
		var text_pos = node.position - Vector2(10, -20)
		draw_string(font, text_pos, node.id.split("_")[1], HORIZONTAL_ALIGNMENT_CENTER, -1, 12)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\nRegenerating graph...")
			generate_random_graph()
			apply_force_directed_layout()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()