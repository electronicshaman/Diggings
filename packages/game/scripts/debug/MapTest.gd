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
	
	# Test the new dual seed system
	test_hash_seeds()
	test_probability_distribution()
	test_deterministic_behavior()
	
	# Generate map with a specific seed for debugging
	var test_seed = 42
	print("Using integer seed: ", test_seed)
	
	# Also demonstrate hash seed usage
	var hash_seed = SeedManager.generate_hash_seed(str(test_seed))
	print("Generated hash seed: ", hash_seed)
	
	var generated_graph = map_generator.generate_map(test_seed)
	
	if not generated_graph or generated_graph.get("nodes", {}).is_empty():
		print("ERROR: Map generation failed!")
		return
	
	print("Map generated successfully!")
	print("  Node count: ", generated_graph.nodes.size())
	print("  Edge count: ", generated_graph.edges.size())
	
	# Test that the same results are produced with equivalent hash seed
	test_seed_equivalence(test_seed, hash_seed)
	
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

func test_hash_seeds():
	print("=== TESTING DUAL SEED SYSTEM ===")
	
	# Test various seed inputs
	var test_inputs = ["42", "test", "ABCDEF1234", "cthulhu", "gold", "fear", "eldritch"]
	
	for input in test_inputs:
		var hash_seed = SeedManager.generate_hash_seed(input)
		var validation = SeedManager.validate_hash_seed(hash_seed)
		var is_thematic = SeedManager.is_thematic_seed(hash_seed)
		var type_label = "STANDARD" if not is_thematic else "THEMATIC"
		
		print("Input: ", input, " -> ", hash_seed, " (", type_label, ", Valid: ", validation, ")")
		
		# Test round-trip conversion
		if validation:
			var converted_int = SeedManager.hash_to_seed(hash_seed)
			print("  Converted to integer: ", converted_int)

func test_probability_distribution():
	print("=== TESTING PROBABILITY DISTRIBUTION ===")
	
	var standard_count = 0
	var thematic_count = 0
	var total_tests = 1000
	var thematic_examples = []
	
	print("Testing ", total_tests, " seed generations...")
	
	for i in range(total_tests):
		# Use varied inputs to get different hash results
		var test_input = "test_" + str(i)
		var seed = SeedManager.generate_hash_seed(test_input)
		
		if SeedManager.is_thematic_seed(seed):
			thematic_count += 1
			if thematic_examples.size() < 10:  # Collect first 10 examples
				thematic_examples.append(seed)
		else:
			standard_count += 1
	
	var thematic_percentage = (float(thematic_count) / total_tests) * 100.0
	
	print("Results:")
	print("  Standard seeds: ", standard_count, " (", 100.0 - thematic_percentage, "%)")
	print("  Thematic seeds: ", thematic_count, " (", thematic_percentage, "%)")
	print("  Expected thematic: ~1%")
	
	if thematic_examples.size() > 0:
		print("  Thematic examples: ", thematic_examples)
	else:
		print("  No thematic seeds generated in this sample")

func test_deterministic_behavior():
	print("=== TESTING DETERMINISTIC BEHAVIOR ===")
	
	var test_inputs = ["same_input", "another_test", "deterministic"]
	
	for input in test_inputs:
		var seeds = []
		# Generate same seed multiple times
		for i in range(5):
			seeds.append(SeedManager.generate_hash_seed(input))
		
		# Check if all results are identical
		var all_same = true
		for i in range(1, seeds.size()):
			if seeds[i] != seeds[0]:
				all_same = false
				break
		
		print("Input '", input, "': ", seeds[0], " (Deterministic: ", all_same, ")")
		if not all_same:
			print("  ERROR: Non-deterministic results: ", seeds)

func test_seed_equivalence(int_seed: int, hash_seed: String):
	print("=== TESTING SEED EQUIVALENCE ===")
	
	# Generate with integer seed
	SeedManager.set_master_seed(int_seed)
	var random_values_int = []
	for i in range(10):
		random_values_int.append(SeedManager.get_map_random_int(0, 1000))
	
	# Generate with equivalent hash seed
	SeedManager.set_master_seed(hash_seed)
	var random_values_hash = []
	for i in range(10):
		random_values_hash.append(SeedManager.get_map_random_int(0, 1000))
	
	print("Integer seed values: ", random_values_int)
	print("Hash seed values: ", random_values_hash)
	
	# Check if they match (they should be different due to different conversion methods)
	var match_count = 0
	for i in range(min(random_values_int.size(), random_values_hash.size())):
		if random_values_int[i] == random_values_hash[i]:
			match_count += 1
	
	print("Matching values: ", match_count, "/", random_values_int.size())
	
	# This is expected behavior - hash seeds create different but deterministic results
	if match_count < random_values_int.size():
		print("EXPECTED: Hash and integer seeds produce different deterministic sequences")
	else:
		print("UNEXPECTED: All values matched - this might indicate an issue")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("Regenerating map...")
			generate_test_map()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
