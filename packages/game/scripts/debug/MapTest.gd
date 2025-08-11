extends Control

const DEBUG_ENABLED: bool = true

# Import map system classes
const MapGenerator = preload("res://scripts/map/MapGenerator.gd")
const MapVisualizer = preload("res://scripts/map/MapVisualizer.gd")
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	print("=== MAP TEST SCENE STARTED ===")
	
	# Set up the scene size to full viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create and test the map generator
	setup_map_system()
	test_config_loading()
	generate_test_map()

func setup_map_system():
	print("Setting up map system...")
	
	# Create map generator
	map_generator = MapGenerator.new()
	add_child(map_generator)
	
	# Create visualizer
	map_visualizer = MapVisualizer.new()
	map_visualizer.setup(map_generator)
	add_child(map_visualizer)
	
	print("Map system setup complete")

func test_config_loading():
	print("=== TESTING CONFIG LOADING ===")
	
	# Test loading the config manually
	var config_path = "res://data/map_layout_config.tres"
	if ResourceLoader.exists(config_path):
		var config = load(config_path) as MapLayoutConfig
		print("Config loaded successfully:")
		print("  viewport_size: ", config.viewport_size)
		print("  spacing_min: ", config.spacing_min)
		print("  spacing_max: ", config.spacing_max)
		print("  connection_max_distance: ", config.connection_max_distance)
		print("  physics_enabled: ", config.physics_enabled)
		print("  bounds_enforce_viewport: ", config.bounds_enforce_viewport)
		print("  bounds_margin: ", config.bounds_margin)
	else:
		print("ERROR: Config file not found!")
	
	# Test the generator's loaded config
	if map_generator.layout_config:
		print("Generator config:")
		print("  viewport_size: ", map_generator.layout_config.viewport_size)
		print("  spacing_min: ", map_generator.layout_config.spacing_min)
		print("  spacing_max: ", map_generator.layout_config.spacing_max)
	else:
		print("ERROR: Generator has no config!")

func generate_test_map():
	print("=== GENERATING TEST MAP ===")
	
	# Generate map with a specific seed for debugging
	var test_seed = 42
	print("Using seed: ", test_seed)
	
	var generated_graph = map_generator.generate_map(test_seed)
	
	if not generated_graph or generated_graph.get("nodes", {}).is_empty():
		print("ERROR: Map generation failed!")
		return
	
	print("Map generated successfully!")
	print("  Node count: ", generated_graph.nodes.size())
	print("  Edge count: ", generated_graph.edges.size())
	
	# Print all node positions
	print("=== NODE POSITIONS ===")
	for node_id in generated_graph.nodes:
		var node = generated_graph.nodes[node_id]
		print("  ", node_id, ": ", node.position, " (", node.get_type_name(), ")")
	
	# Calculate actual bounds
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for node in generated_graph.nodes.values():
		min_pos.x = min(min_pos.x, node.position.x)
		min_pos.y = min(min_pos.y, node.position.y)
		max_pos.x = max(max_pos.x, node.position.x)
		max_pos.y = max(max_pos.y, node.position.y)
	
	var actual_size = max_pos - min_pos
	print("=== ACTUAL MAP BOUNDS ===")
	print("  Min position: ", min_pos)
	print("  Max position: ", max_pos)
	print("  Actual size: ", actual_size)
	print("  Utilization: ", actual_size.x, "x", actual_size.y, " of expected 1920x900")
	
	# Visualize the map
	map_visualizer.visualize_graph(generated_graph)
	
	print("=== TEST COMPLETE ===")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("Regenerating map...")
			generate_test_map()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
