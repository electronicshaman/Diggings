extends Control
class_name MapController

const DEBUG_ENABLED: bool = true

# Import our map system classes
const MapNode = preload("res://scripts/map/MapNode.gd")
const MapEdge = preload("res://scripts/map/MapEdge.gd") 
const MapGenerator = preload("res://scripts/map/MapGenerator.gd")
const MapVisualizer = preload("res://scripts/map/MapVisualizer.gd")
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

# Zoom and pan system
var zoom_level = 1.0
var zoom_min = 0.3
var zoom_max = 3.0
var zoom_speed = 0.1
var dragging = false
var drag_start_position = Vector2()
var initial_map_position = Vector2()

@onready var view_deck_button = $HeaderPanel/HeaderContent/ViewDeckButton
@onready var floor_label = $HeaderPanel/HeaderContent/FloorLabel
@onready var zoom_in_button = $HeaderPanel/HeaderContent/MapZoomIn
@onready var zoom_out_button = $HeaderPanel/HeaderContent/MapZoomOut
@onready var zoom_reset_button = $HeaderPanel/HeaderContent/MapZoomReset
@onready var map_viewport = $MapViewport
@onready var map_content = $MapViewport/MapContent

# Graph generation system
var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	setup_graph_system()
	setup_button_connections()
	
	# Initialize map content with simple centering
	var viewport_size = get_viewport().get_visible_rect().size
	var map_viewport_size = Vector2(viewport_size.x, viewport_size.y - 80)
	# Set MapContent to a reasonable size and center it in the viewport
	map_content.size = map_viewport_size  # Match viewport size
	map_content.position = Vector2.ZERO  # Start at origin of MapViewport
	GLog.debug("Initialized map content size: " + str(map_content.size) + " at position: " + str(map_content.position))
	
	# Initialize game data for development if needed
	if not GameManager.is_run_active:
		if not GameManager.game_data:
			GameManager.game_data = {}
		# Enable run state for development to allow map persistence
		GameManager.is_run_active = true
		
	generate_new_map()

func _input(event):
	# Only handle input when the map scene is active
	if not visible:
		return
		
	# Handle zooming with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = min(zoom_level + zoom_speed, zoom_max)
			_update_zoom(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = max(zoom_level - zoom_speed, zoom_min)
			_update_zoom(event.position)
		# Handle drag start
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_in_map_area(event.position):
				dragging = true
				drag_start_position = event.position
				initial_map_position = map_content.position
			else:
				dragging = false
	
	# Handle dragging for panning
	if event is InputEventMouseMotion and dragging:
		var delta = event.position - drag_start_position
		map_content.position = initial_map_position + delta

func _is_in_map_area(pos: Vector2) -> bool:
	# Check if position is in the map viewport (below header)
	return pos.y > 80

func _update_zoom(mouse_pos: Vector2 = Vector2.ZERO):
	var old_scale = map_content.scale
	map_content.scale = Vector2(zoom_level, zoom_level)
	
	# Zoom towards mouse position if provided
	if mouse_pos != Vector2.ZERO and _is_in_map_area(mouse_pos):
		# Adjust position so zoom happens towards mouse cursor
		var scale_delta = map_content.scale - old_scale
		var relative_mouse = mouse_pos - map_content.position
		map_content.position -= relative_mouse * (scale_delta.x / old_scale.x) if old_scale.x > 0 else Vector2.ZERO
	
	GLog.debug("Zoom level: " + str(zoom_level) + ", Scale: " + str(map_content.scale))

func reset_view():
	"""Reset zoom and center the map"""
	zoom_level = 1.0
	map_content.scale = Vector2.ONE
	# Reset to initial position
	map_content.position = Vector2.ZERO
	GLog.debug("View reset to origin with 1.0 zoom")

# Public method to regenerate map (useful for config testing)
func regenerate_map():
	GLog.info("Regenerating map...")
	
	# Reload config in case it changed
	if map_generator:
		map_generator.load_default_config()
		map_generator.initialize_rules()
	
	generate_new_map()
	
	# Reset view to center the new map
	call_deferred("reset_view")

# Hot-reload config for testing
func reload_config():
	if map_generator and map_generator.layout_config:
		var config_path = "res://data/map_layout_config.tres"
		if ResourceLoader.exists(config_path):
			map_generator.layout_config = load(config_path) as MapLayoutConfig
			map_generator.initialize_rules()
			GLog.info("Reloaded map configuration")
			regenerate_map()
		else:
			GLog.warning("Config file not found: " + config_path)

func setup_graph_system():
	# Create map generator
	map_generator = MapGenerator.new()
	# TEMPORARY: Enable debug mode to see all nodes for development
	map_generator.debug_show_all_nodes = true
	add_child(map_generator)
	
	# Debug: Check if map_content is valid
	if not map_content:
		GLog.error("MapContent node not found! Check scene structure.")
		return
	
	
	
	# Create visualizer and add it to the map content container
	map_visualizer = MapVisualizer.new()
	map_visualizer.setup(map_generator)
	
	# Add MapVisualizer to MapContent for zoom/pan system
	map_content.add_child(map_visualizer)
	
	# Make visible
	map_visualizer.visible = true
	
	# Connect visualizer signals
	map_visualizer.node_clicked.connect(_on_node_clicked)
	map_visualizer.node_hovered.connect(_on_node_hovered)
	map_visualizer.node_unhovered.connect(_on_node_unhovered)
	
	GLog.debug("Graph system setup complete")

func setup_button_connections():
	view_deck_button.pressed.connect(_on_view_deck_pressed)
	zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	zoom_out_button.pressed.connect(_on_zoom_out_pressed)
	zoom_reset_button.pressed.connect(_on_zoom_reset_pressed)

func generate_new_map():
	GLog.debug("generate_new_map called - GameManager.is_run_active: " + str(GameManager.is_run_active))
	GLog.debug("GameManager.game_data exists: " + str(GameManager.game_data != null))
	if GameManager.game_data:
		GLog.debug("GameManager.game_data.has('map'): " + str(GameManager.game_data.has("map")))
		if GameManager.game_data.has("map"):
			GLog.debug("GameManager.game_data.map is null: " + str(GameManager.game_data.map == null))
	
	# Only generate if we don't have a map stored in game_data or if no run is active
	if GameManager.is_run_active and GameManager.game_data.has("map") and GameManager.game_data.map != null:
		# Map already exists for this run, restore it instead
		GLog.debug("Restoring existing map from GameManager")
		restore_existing_map()
		return
	
	GLog.debug("Generating new map - no existing data found")
	
	# Generate a new map using a consistent seed for this run
	var seed: int
	if GameManager.is_run_active:
		# Use the run's master seed + a map-specific offset to ensure consistency
		seed = SeedManager.master_seed + 12345  # Fixed offset for map generation
		GLog.debug("Using consistent map seed: " + str(seed) + " (master: " + str(SeedManager.master_seed) + ")")
	else:
		# Development mode - use a fixed seed for consistency during testing
		seed = 12345  # Fixed seed for development
		GLog.debug("Using fixed development seed: " + str(seed))
	
	# Ensure the SeedManager's map_rng is seeded consistently
	SeedManager.map_rng.seed = seed
	GLog.debug("Seeded SeedManager.map_rng with: " + str(seed))
	
	map_generator.generate_map(seed)
	GLog.info("Generated new map for exploration with seed: " + str(seed))
	
	# Store the map in game_data for persistence
	if GameManager.is_run_active:
		GameManager.game_data.map = {
			"generator_data": map_generator.get_serializable_data(),
			"current_player_node": map_generator.current_player_node_id,
			"visited_nodes": map_generator.visited_node_ids.duplicate()
		}
		GLog.debug("Map data stored in GameManager")
	
	# Apply consistent visualization setup
	_setup_map_visualization()

func _setup_map_visualization():
	"""Apply consistent MapVisualizer setup for both new and restored maps"""
	GLog.debug("_setup_map_visualization called")
	
	# Update visualizer size and position
	var map_bounds = map_visualizer.get_graph_bounds()
	map_visualizer.set_deferred("custom_minimum_size", map_bounds.size)
	map_visualizer.set_deferred("size", map_bounds.size)
	map_visualizer.set_deferred("position", Vector2.ZERO)
	
	# Ensure visibility for all elements
	map_visualizer.visible = true
	map_visualizer.modulate = Color.WHITE
	var edge_count = 0
	var button_count = 0
	for child in map_visualizer.get_children():
		if child is Line2D:
			child.visible = true
			child.modulate = Color.WHITE
			# Force Line2D to front to ensure visibility
			child.z_index = 1
			edge_count += 1
		elif child.has_method("set_highlight"):  # CircularMapNode check
			child.visible = true
			child.modulate = Color.WHITE
			button_count += 1
		elif child is ColorRect:
			child.visible = true
			child.modulate = Color.WHITE
	
	# Ensure MapContent doesn't clip the visualizer
	map_content.clip_contents = false
	
	GLog.debug("Setup visualizer - size: " + str(map_bounds.size) + ", pos: " + str(map_visualizer.position) + ", edges: " + str(edge_count) + ", buttons: " + str(button_count))

func restore_existing_map():
	# Restore map from stored game data
	var map_data = GameManager.game_data.map
	if not map_data or not map_data.has("generator_data"):
		GLog.warn("Invalid map data found, generating new map")
		GameManager.game_data.map = null
		generate_new_map()
		return
		
	# Restore the map generator state
	map_generator.load_from_serializable_data(map_data.generator_data)
	
	# Restore player position and visited nodes
	if map_data.has("current_player_node"):
		map_generator.current_player_node_id = map_data.current_player_node
	if map_data.has("visited_nodes"):
		map_generator.visited_node_ids = map_data.visited_nodes
	
	GLog.info("Restored existing map from game data")
	
	# Update visualizer with the restored graph data
	var restored_graph = map_generator.get_graph_data()
	map_visualizer.visualize_graph(restored_graph)
	map_visualizer.highlight_available_moves()
	
	# Apply the same visualization setup as generate_new_map
	_setup_map_visualization()

func _on_view_deck_pressed():
	GLog.info("View Deck button pressed")
	SceneManager.load_scene_by_name("deck_viewer")

func _on_zoom_in_pressed():
	GLog.debug("Zoom In button pressed")
	zoom_level = min(zoom_level + zoom_speed, zoom_max)
	_update_zoom()

func _on_zoom_out_pressed():
	GLog.debug("Zoom Out button pressed")
	zoom_level = max(zoom_level - zoom_speed, zoom_min)
	_update_zoom()

func _on_zoom_reset_pressed():
	GLog.debug("Zoom Reset button pressed")
	reset_view()

func _on_node_clicked(node_id: String):
	GLog.info("Map node clicked: " + node_id)
	
	var node = map_generator.graph.nodes.get(node_id)
	if not node:
		return
	
	# Try to move player to this node
	if map_generator.move_player_to_node(node_id):
		handle_node_arrival(node_id, node)
	else:
		GLog.warning("Cannot move to node: " + node_id)

func handle_node_arrival(node_id: String, node: MapNode):
	GLog.info("Player arrived at: " + node.get_type_name() + " (" + node_id + ")")
	
	# Handle different node types
	match node.type:
		MapNode.NodeType.CAMP:
			handle_camp_arrival(node)
		MapNode.NodeType.MINE:
			handle_mine_arrival(node)
		MapNode.NodeType.SETTLEMENT:
			handle_settlement_arrival(node)
		MapNode.NodeType.POI:
			handle_poi_arrival(node)
		MapNode.NodeType.JUNCTION:
			handle_junction_arrival(node)

func handle_camp_arrival(node: MapNode):
	# Camps offer rest and healing - could show rest options
	GLog.info("Arrived at camp: " + node.id)
	# For now, just highlight available moves
	map_visualizer.highlight_available_moves()

func handle_mine_arrival(node: MapNode):
	# Mines might trigger combat or resource events
	GLog.info("Arrived at mine: " + node.id)
	
	# Random chance of combat at mines
	if SeedManager.get_event_random_float() < 0.6:  # 60% chance of combat
		GLog.info("Enemy encountered in the mine!")
		SceneManager.load_scene_by_name("main_game")
	else:
		map_visualizer.highlight_available_moves()

func handle_settlement_arrival(node: MapNode):
	# Settlements offer shops and NPCs
	GLog.info("Arrived at settlement: " + node.id)
	
	# For now, automatically go to shop
	SceneManager.load_scene_by_name("shop")

func handle_poi_arrival(node: MapNode):
	# POIs trigger special events
	GLog.info("Arrived at point of interest: " + node.id)
	
	# Random chance of event or combat
	if SeedManager.get_event_random_float() < 0.7:  # 70% chance of event
		SceneManager.load_scene_by_name("event")
	else:
		GLog.info("Strange encounter at the mysterious location!")
		SceneManager.load_scene_by_name("main_game")

func handle_junction_arrival(node: MapNode):
	# Junctions are just pass-through points
	GLog.info("Arrived at junction: " + node.id)
	map_visualizer.highlight_available_moves()

func _on_node_hovered(node_id: String):
	# Could show tooltip or highlight path
	pass

func _on_node_unhovered():
	# Clear any hover effects
	pass

# Public interface for other systems
func get_current_node() -> MapNode:
	return map_generator.get_current_player_node()

func get_available_destinations() -> Array[String]:
	return map_generator.get_available_moves()

func force_move_to_node(node_id: String) -> bool:
	return map_generator.move_player_to_node(node_id)

# Handle returning from other scenes
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		GLog.debug("Map visibility changed - scene became visible")
		# Refresh visualization when returning to map
		if map_visualizer:
			GLog.debug("GameManager.is_run_active: " + str(GameManager.is_run_active))
			GLog.debug("GameManager.game_data.has('map'): " + str(GameManager.game_data.has("map") if GameManager.game_data else "no game_data"))
			# Apply the same visualization setup to ensure consistency
			_setup_map_visualization()
			# Update visibility and highlighting after setup
			map_visualizer.update_visibility()
			map_visualizer.highlight_available_moves()
