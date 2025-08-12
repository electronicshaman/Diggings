extends Control

const DEBUG_ENABLED: bool = true

# Import map system classes
const MapGenerator = preload("res://scripts/map/MapGenerator.gd")
const MapVisualizer = preload("res://scripts/map/MapVisualizer.gd")
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	GLog.info("=== MAP TEST SCENE STARTED ===")
	
	# Set up the scene size to full viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create and test the map generator
	setup_map_system()
	test_config_loading()
	generate_test_map()

func setup_map_system():
	GLog.info("Setting up map system...")
	
	# Create map generator
	map_generator = MapGenerator.new()
	add_child(map_generator)
	
	# Create visualizer
	map_visualizer = MapVisualizer.new()
	map_visualizer.setup(map_generator)
	add_child(map_visualizer)
	
	GLog.info("Map system setup complete")

func test_config_loading():
	GLog.info("=== TESTING CONFIG LOADING ===")
	
	# Test loading the config manually
	var config_path = "res://data/map_layout_config.tres"
	if ResourceLoader.exists(config_path):
		var config = load(config_path) as MapLayoutConfig
		GLog.debug("Config loaded successfully:")
		GLog.debug("  viewport_size: " + str(config.viewport_size))
		GLog.debug("  spacing_min: " + str(config.spacing_min))
		GLog.debug("  spacing_max: " + str(config.spacing_max))
		GLog.debug("  connection_max_distance: " + str(config.connection_max_distance))
		GLog.debug("  physics_enabled: " + str(config.physics_enabled))
		GLog.debug("  bounds_enforce_viewport: " + str(config.bounds_enforce_viewport))
		GLog.debug("  bounds_margin: " + str(config.bounds_margin))
	else:
		GLog.error("Config file not found!")
	
	# Test the generator's loaded config
	if map_generator.layout_config:
		GLog.debug("Generator config:")
		GLog.debug("  viewport_size: " + str(map_generator.layout_config.viewport_size))
		GLog.debug("  spacing_min: " + str(map_generator.layout_config.spacing_min))
		GLog.debug("  spacing_max: " + str(map_generator.layout_config.spacing_max))
	else:
		GLog.error("Generator has no config!")

func generate_test_map():
	GLog.info("=== GENERATING TEST MAP ===")
	
	# Test the new dual seed system
	test_hash_seeds()
	test_probability_distribution()
	test_deterministic_behavior()
	
	# Test both traditional and planar graph generation
	test_traditional_generation()
	test_planar_generation()
	
	GLog.info("=== TEST COMPLETE ===")

func test_traditional_generation():
	GLog.info("=== TESTING TRADITIONAL GENERATION ===")
	
	# Ensure traditional generation is used
	if map_generator.layout_config:
		map_generator.layout_config.use_planar_graph_generation = false
	
	var test_seed = 42
	GLog.debug("Using integer seed: " + str(test_seed))
	
	var generated_graph = map_generator.generate_map(test_seed)
	
	if not generated_graph or generated_graph.get("nodes", {}).is_empty():
		GLog.error("Traditional map generation failed!")
		return
	
	GLog.info("Traditional map generated successfully!")
	GLog.debug("  Node count: " + str(generated_graph.nodes.size()))
	GLog.debug("  Edge count: " + str(generated_graph.edges.size()))
	
	# Test for edge crossings in traditional generation
	test_planarity(generated_graph, "Traditional")
	
	# Print node positions and connections
	print_graph_details(generated_graph, "TRADITIONAL")
	
	# Visualize the traditional map
	map_visualizer.visualize_graph(generated_graph)

func test_planar_generation():
	GLog.info("=== TESTING PLANAR GENERATION ===")
	
	# Enable planar graph generation
	if map_generator.layout_config:
		map_generator.layout_config.use_planar_graph_generation = true
		map_generator.layout_config.planar_pruning_intensity = 0.6
		map_generator.layout_config.auto_fix_crossings = true
		map_generator.layout_config.validate_planarity = true
	
	var test_seed = 43  # Different seed for variety
	GLog.debug("Using integer seed for planar generation: " + str(test_seed))
	
	var generated_graph = map_generator.generate_map(test_seed)
	
	if not generated_graph or generated_graph.get("nodes", {}).is_empty():
		GLog.error("Planar map generation failed!")
		return
	
	GLog.info("Planar map generated successfully!")
	GLog.debug("  Node count: " + str(generated_graph.nodes.size()))
	GLog.debug("  Edge count: " + str(generated_graph.edges.size()))
	
	# Test planarity
	test_planarity(generated_graph, "Planar")
	
	# Print detailed planarity report
	test_detailed_planarity_analysis(generated_graph)
	
	# Print node positions and connections
	print_graph_details(generated_graph, "PLANAR")
	
	# Wait a moment then visualize the planar map
	await get_tree().create_timer(1.0).timeout
	map_visualizer.visualize_graph(generated_graph)

func test_planarity(graph: Dictionary, generation_type: String):
	GLog.info("=== PLANARITY TEST FOR " + generation_type.to_upper() + " ===")
	
	# Import the validator
	const PlanarGraphValidator = preload("res://scripts/map/PlanarGraphValidator.gd")
	
	var is_planar = PlanarGraphValidator.is_graph_planar(graph)
	var crossings = PlanarGraphValidator.find_edge_crossings(graph)
	
	if is_planar:
		GLog.info("  ✓ Graph is PLANAR (no edge crossings)")
	else:
		GLog.warn("  ✗ Graph has CROSSINGS: " + str(crossings.size()) + " intersections found")
		
		# Print details of first few crossings
		var max_details = min(5, crossings.size())
		for i in range(max_details):
			var crossing = crossings[i]
			print("    Crossing ", i+1, ": ", crossing.edge1.from_node, "->", crossing.edge1.to_node, 
				  " ✗ ", crossing.edge2.from_node, "->", crossing.edge2.to_node, 
				  " at ", crossing.intersection_point)

func test_detailed_planarity_analysis(graph: Dictionary):
	GLog.info("=== DETAILED PLANARITY ANALYSIS ===")
	
	const PlanarGraphValidator = preload("res://scripts/map/PlanarGraphValidator.gd")
	
	var report = PlanarGraphValidator.generate_planarity_report(graph)
	
	print("  Total nodes: ", report.total_nodes)
	print("  Total edges: ", report.total_edges)
	print("  Planar upper bound: ", report.planar_upper_bound, " edges")
	print("  Exceeds planar bound: ", report.exceeds_planar_bound)
	print("  Is planar: ", report.is_planar)
	print("  Total crossings: ", report.total_crossings)
	print("  Edges with crossings: ", report.edges_with_crossings)
	
	if report.total_crossings > 0:
		print("  Crossing details:")
		for detail in report.crossing_details:
			print("    ", detail.edge1, " ✗ ", detail.edge2, " at ", detail.intersection_point)

func print_graph_details(graph: Dictionary, generation_type: String):
	print("=== " + generation_type + " GRAPH DETAILS ===")
	
	# Print all node positions
	print("NODE POSITIONS:")
	for node_id in graph.nodes:
		var node = graph.nodes[node_id]
		print("  ", node_id, ": ", node.position, " (", node.get_type_name(), ") - ", node.connections.size(), " connections")
	
	# Print all edges
	print("EDGES:")
	for edge in graph.get("edges", []):
		print("  ", edge.from_node, " <-> ", edge.to_node)
	
	# Calculate actual bounds
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for node in graph.nodes.values():
		min_pos.x = min(min_pos.x, node.position.x)
		min_pos.y = min(min_pos.y, node.position.y)
		max_pos.x = max(max_pos.x, node.position.x)
		max_pos.y = max(max_pos.y, node.position.y)
	
	var actual_size = max_pos - min_pos
	print("BOUNDS:")
	print("  Min position: ", min_pos)
	print("  Max position: ", max_pos)
	print("  Actual size: ", actual_size)
	print("  Utilization: ", actual_size.x, "x", actual_size.y, " of expected 1920x900")

func test_hash_seeds():
	GLog.info("=== TESTING DUAL SEED SYSTEM ===")
	
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
		elif event.keycode == KEY_T:
			print("Testing traditional generation only...")
			test_traditional_generation()
		elif event.keycode == KEY_P:
			print("Testing planar generation only...")
			test_planar_generation()
		elif event.keycode == KEY_C:
			print("Testing crossings in current map...")
			test_current_map_crossings()
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func test_current_map_crossings():
	var current_graph = map_generator.get_graph_data()
	if current_graph.get("nodes", {}).is_empty():
		print("No current map to test")
		return
	
	print("=== CURRENT MAP CROSSING TEST ===")
	test_planarity(current_graph, "Current")
	test_detailed_planarity_analysis(current_graph)
