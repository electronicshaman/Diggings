extends Control
class_name MapController

const DEBUG_ENABLED: bool = true
const DEBUG_MAP_SHOW_ALL_NODES: bool = true

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

# Tooltip system
var tooltip_label: Label
var tooltip_background: Panel

# Graph generation system
var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	# Enhanced debug initialization for standalone testing
	if DEBUG_MAP_SHOW_ALL_NODES:
		ensure_debug_game_state()
	
	setup_graph_system()
	setup_button_connections()
	setup_tooltip_system()
	
	# Initialize map content with map generation size, not screen viewport size
	var config_viewport_size = Vector2(1920, 900)  # Default from map_layout_config.tres
	# Note: We'll set the final size in _setup_map_visualization when we have access to map_generator.layout_config
	
	# For now, set to a reasonable size - will be updated when map loads
	map_content.size = config_viewport_size
	map_content.position = Vector2.ZERO  # Start at origin of MapViewport
	
	# Ensure mouse input passes through to child nodes
	map_viewport.mouse_filter = Control.MOUSE_FILTER_PASS
	map_content.mouse_filter = Control.MOUSE_FILTER_PASS
	
	GLog.debug("Initialized map content with config size: " + str(map_content.size) + " at position: " + str(map_content.position))
	
	# Display the current map
	display_current_map()

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

# Refresh the current map display
func refresh_map_display():
	GLog.info("Refreshing map display")
	display_current_map()
	# Reset view to center the map
	call_deferred("reset_view")

func setup_graph_system():
	# Create map generator
	map_generator = MapGenerator.new()
	# Set debug mode to show all nodes as available for layout debugging
	map_generator.debug_show_all_nodes = DEBUG_MAP_SHOW_ALL_NODES
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

func setup_tooltip_system():
	# Create tooltip background panel
	tooltip_background = Panel.new()
	tooltip_background.name = "TooltipBackground"
	
	# Style the background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)  # Semi-transparent black
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color.WHITE
	tooltip_background.add_theme_stylebox_override("panel", style_box)
	
	# Create tooltip label
	tooltip_label = Label.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.add_theme_constant_override("outline_size", 1)
	tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Set up hierarchy and positioning
	tooltip_background.add_child(tooltip_label)
	add_child(tooltip_background)
	
	# Initially hide tooltip
	tooltip_background.visible = false
	tooltip_background.z_index = 1000  # Ensure it appears on top
	
	# Position label within background with padding
	tooltip_label.position = Vector2(6, 4)
	
	GLog.debug("Tooltip system initialized")

func display_current_map():
	GLog.debug("Displaying current map")
	
	if not GameManager.game_data or not GameManager.game_data.has("maps"):
		GLog.warn("No maps data in GameManager - generating test map for development")
		generate_test_map()
		return
	
	var current_region = GameManager.game_data.get("current_map", "")
	if current_region.is_empty():
		GLog.warn("No current map selected - generating test map for development")
		generate_test_map()
		return
	
	var map_data = GameManager.game_data.maps.get(current_region, {})
	if not map_data or not map_data.has("generator_data"):
		# Use regular procedural generation with our configuration
		GLog.debug("No map data for region, generating procedural map with current config")
		generate_procedural_map_with_config()
		return
	
	# Load the map from stored data
	map_generator.load_from_serializable_data(map_data.generator_data)
	
	# Restore player position, visited nodes, and discovered nodes
	if map_data.has("current_player_node"):
		map_generator.current_player_node_id = map_data.current_player_node
		map_generator.graph.player_position = map_data.current_player_node
	if map_data.has("visited_nodes"):
		map_generator.visited_node_ids.clear()
		for node_id in map_data.visited_nodes:
			map_generator.visited_node_ids.append(node_id)
	if map_data.has("discovered_nodes"):
		map_generator.discovered_node_ids.clear()
		for node_id in map_data.discovered_nodes:
			map_generator.discovered_node_ids.append(node_id)
	
	GLog.info("Loaded map for region: " + current_region)
	
	# Restore visibility based on discovered and visited nodes
	map_generator.restore_persistent_visibility()
	
	# Visualize the loaded graph
	var graph = map_generator.get_graph_data()
	map_visualizer.visualize_graph(graph)
	
	# Apply visualization setup
	_setup_map_visualization()
	
	# Highlight available moves after everything is set up
	call_deferred("_highlight_available_moves_after_setup")

func _setup_map_visualization():
	"""Apply consistent MapVisualizer setup for both new and restored maps"""
	GLog.debug("_setup_map_visualization called")
	
	# Update visualizer size and position - use config viewport size instead of node bounds
	var config_viewport_size = Vector2(1920, 900)  # From map_layout_config.tres
	if map_generator and map_generator.layout_config:
		config_viewport_size = map_generator.layout_config.viewport_size
	
	GLog.debug("Using config viewport size: " + str(config_viewport_size) + " instead of calculated bounds")
	
	# Update MapContent size to match the map generation viewport
	map_content.size = config_viewport_size
	GLog.debug("Set map_content size to: " + str(config_viewport_size))
	
	map_visualizer.set_deferred("custom_minimum_size", config_viewport_size)
	map_visualizer.set_deferred("size", config_viewport_size)
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
	
	GLog.debug("Setup visualizer - size: " + str(config_viewport_size) + ", pos: " + str(map_visualizer.position) + ", edges: " + str(edge_count) + ", buttons: " + str(button_count))

func _highlight_available_moves_after_setup():
	"""Highlight available moves after all visualization setup is complete"""
	if map_visualizer:
		GLog.debug("Highlighting available moves after setup")
		map_visualizer.update_visibility()
		map_visualizer.highlight_available_moves()

# TEMPORARY: Generate a simple test map using real resources for development
func generate_test_map():
	if DEBUG_MAP_SHOW_ALL_NODES:
		GLog.info("=== GENERATING DEBUG TEST MAP WITH ALL NODES AVAILABLE ===")
		GLog.info("DEBUG MODE: All nodes will be set to AVAILABLE for layout testing")
	else:
		GLog.info("=== GENERATING RESOURCE-DRIVEN TEST MAP FOR DEVELOPMENT ===")
		GLog.info("This is a temporary fallback for testing - remove when map selection is implemented")
	
	# Load real NodeConfig resources from data/map_nodes/
	var city_config = load("res://data/map_nodes/cities/goldfields_city.tres") as MapNodeConfig
	var camp_config = load("res://data/map_nodes/camps/prospector_camp.tres") as MapNodeConfig  
	var mine_config = load("res://data/map_nodes/mines/abandoned_goldmine.tres") as MapNodeConfig
	var settlement_config = load("res://data/map_nodes/settlements/trading_post.tres") as MapNodeConfig
	var junction_config = load("res://data/map_nodes/junctions/mountain_pass.tres") as MapNodeConfig
	
	# Create nodes with real resource configs
	var city_node = MapNodeRegistry.create_node("test_city", city_config, Vector2(400, 300))
	city_node.set_state(MapNode.NodeState.CURRENT)
	
	var camp_node = MapNodeRegistry.create_node("test_camp", camp_config, Vector2(300, 200))
	camp_node.set_state(MapNode.NodeState.AVAILABLE)
	
	var mine_node = MapNodeRegistry.create_node("test_mine", mine_config, Vector2(500, 200))
	mine_node.set_state(MapNode.NodeState.AVAILABLE)
	
	var settlement_node = MapNodeRegistry.create_node("test_settlement", settlement_config, Vector2(400, 150))
	settlement_node.set_state(MapNode.NodeState.AVAILABLE)
	
	var junction_node = MapNodeRegistry.create_node("test_junction", junction_config, Vector2(350, 350))
	junction_node.set_state(MapNode.NodeState.LOCKED)  # Undiscovered
	
	# Set up connections
	city_node.connect_to("test_camp")
	city_node.connect_to("test_mine")
	city_node.connect_to("test_junction")
	camp_node.connect_to("test_city")
	camp_node.connect_to("test_settlement")
	mine_node.connect_to("test_city")
	settlement_node.connect_to("test_camp")
	junction_node.connect_to("test_city")
	
	# Create simple graph structure
	var test_graph = {
		"nodes": {
			"test_city": city_node,
			"test_camp": camp_node,
			"test_mine": mine_node,
			"test_settlement": settlement_node,
			"test_junction": junction_node
		},
		"edges": [],  # We'll skip edge objects for simplicity
		"player_position": "test_city",
		"start_node": "test_city"
	}
	
	# Update map generator state
	map_generator.graph = test_graph
	map_generator.current_player_node_id = "test_city"
	map_generator.visited_node_ids = ["test_city"]
	
	GLog.info("Generated resource-driven test map with 5 nodes")
	GLog.info("All nodes loaded from .tres configuration files")
	GLog.info("Player starting at city node")
	
	# Set up initial visibility and discover adjacent nodes
	map_generator.discover_adjacent_nodes("test_city", 2)
	
	# Apply debug mode if enabled
	if map_generator.debug_show_all_nodes:
		GLog.debug("DEBUG MAP MODE: Setting up fog of war for test map")
		map_generator.setup_fog_of_war()
	
	# Visualize the test graph
	map_visualizer.visualize_graph(test_graph)
	
	# Apply visualization setup
	_setup_map_visualization()
	
	# Highlight available moves after everything is set up
	call_deferred("_highlight_available_moves_after_setup")

func generate_procedural_map_with_config():
	"""Generate a procedural map using our current configuration"""
	GLog.info("=== GENERATING PROCEDURAL MAP WITH CURRENT CONFIG ===")
	GLog.info("Using regular generation system with configuration from map_layout_config.tres")
	
	# Use procedural generation with a random seed to see our config changes
	var generated_graph = map_generator.generate_map()
	
	if not generated_graph or generated_graph.get("nodes", {}).is_empty():
		GLog.error("Procedural generation failed, falling back to test map")
		generate_test_map()
		return
	
	GLog.info("Generated procedural map with " + str(generated_graph.nodes.size()) + " nodes using current config")
	
	# Apply debug fog of war to make all nodes available if in debug mode
	if DEBUG_MAP_SHOW_ALL_NODES and map_generator.debug_show_all_nodes:
		GLog.debug("DEBUG MODE: Setting up fog of war to show all nodes")
		map_generator.setup_fog_of_war()
	
	# Visualize the generated graph
	map_visualizer.visualize_graph(generated_graph)
	
	# Apply visualization setup
	_setup_map_visualization()
	
	# Highlight available moves after everything is set up
	call_deferred("_highlight_available_moves_after_setup")

# Update the current map state in GameManager
func save_map_state():
	var current_region = GameManager.game_data.get("current_map", "")
	if current_region.is_empty():
		return
	
	if GameManager.game_data.maps.has(current_region):
		GameManager.game_data.maps[current_region].current_player_node = map_generator.current_player_node_id
		GameManager.game_data.maps[current_region].visited_nodes = map_generator.visited_node_ids.duplicate()
		GameManager.game_data.maps[current_region].discovered_nodes = map_generator.discovered_node_ids.duplicate()
		GameManager.game_data.maps[current_region].generator_data = map_generator.get_serializable_data()
		GLog.debug("Map state saved for region: " + current_region)

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
		GLog.error("Node not found in graph: " + node_id)
		return
	
	GLog.debug("Node details - state: " + str(node.state))
	GLog.debug("Current player position: " + map_generator.current_player_node_id)
	GLog.debug("Available moves: " + str(map_generator.get_available_moves()))
	
	# Try to move player to this node
	if map_generator.move_player_to_node(node_id):
		GLog.info("Successfully moved to node: " + node_id)
		handle_node_arrival(node_id, node)
	else:
		GLog.warn("Cannot move to node: " + node_id)

func handle_node_arrival(node_id: String, node: MapNode):
	GLog.info("Player arrived at: " + node.get_type_name() + " (" + node_id + ")")
	
	# Save the current map state before transitioning to another scene
	save_map_state()
	
	# Handle different node types
	match node.type:
		MapNode.NodeType.CITY:
			handle_city_arrival(node)
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
		MapNode.NodeType.BOSS:
			handle_boss_arrival(node)

func handle_camp_arrival(node: MapNode):
	# Camps offer rest and healing - go to camp scene
	GLog.info("Arrived at camp: " + node.id)
	SceneManager.load_scene_by_name("camp")

func handle_mine_arrival(node: MapNode):
	# Mines might trigger combat or resource events
	GLog.info("Arrived at mine: " + node.id)
	
	# Random chance of combat at mines
	if SeedManager.get_event_random_float() < 0.6:  # 60% chance of combat
		GLog.info("Enemy encountered in the mine!")
		SceneManager.load_scene_by_name("duel")
	else:
		# Safe mine exploration - could go to a mine exploration scene in the future
		# For now, just trigger combat anyway
		GLog.info("Exploring the mine...")
		SceneManager.load_scene_by_name("duel")

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
		SceneManager.load_scene_by_name("duel")

func handle_junction_arrival(node: MapNode):
	# Junctions offer path selection and information
	GLog.info("Arrived at junction: " + node.id)
	SceneManager.load_scene_by_name("junction")

func handle_city_arrival(node: MapNode):
	# Cities are safe havens with all services
	GLog.info("Arrived at city: " + node.get_type_name())
	SceneManager.load_scene_by_name("city_hub")

func handle_boss_arrival(node: MapNode):
	# Boss encounters - defeating them completes the map
	GLog.info("Boss encounter: " + node.properties.get("boss_name", "Unknown Boss"))
	# TODO: Pass boss enemy ID to duel scene
	SceneManager.load_scene_by_name("duel")

func _on_node_hovered(node_id: String):
	# Show tooltip with node information
	if not map_generator:
		return
		
	var node = map_generator.graph.nodes.get(node_id)
	if not node:
		return
	
	# Set tooltip text based on node state
	var tooltip_content: String
	if node.state != MapNode.NodeState.LOCKED:
		tooltip_content = node.get_type_name() + " (" + node_id + ")"
	else:
		tooltip_content = "Unknown Location"
	
	# Update tooltip content
	tooltip_label.text = tooltip_content
	
	# Resize background to fit text
	var text_size = tooltip_label.get_theme_font("font").get_string_size(
		tooltip_content, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		tooltip_label.get_theme_font_size("font_size")
	)
	tooltip_background.size = text_size + Vector2(12, 8)  # Add padding
	
	# Position tooltip near mouse cursor
	var mouse_pos = get_global_mouse_position()
	var tooltip_pos = mouse_pos + Vector2(10, -30)  # Offset from cursor
	
	# Keep tooltip within screen bounds
	var screen_size = get_viewport().get_visible_rect().size
	if tooltip_pos.x + tooltip_background.size.x > screen_size.x:
		tooltip_pos.x = mouse_pos.x - tooltip_background.size.x - 10
	if tooltip_pos.y < 0:
		tooltip_pos.y = mouse_pos.y + 10
	
	tooltip_background.global_position = tooltip_pos
	tooltip_background.visible = true
	

func _on_node_unhovered():
	# Hide tooltip
	if tooltip_background:
		tooltip_background.visible = false

# Public interface for other systems
func get_current_node() -> MapNode:
	return map_generator.get_current_player_node()

func get_available_destinations() -> Array[String]:
	return map_generator.get_available_moves()

func force_move_to_node(node_id: String) -> bool:
	return map_generator.move_player_to_node(node_id)

func ensure_debug_game_state():
	"""Initialize game state for standalone map debugging when opened directly"""
	GLog.debug("DEBUG MAP MODE: Ensuring game state is initialized for standalone testing")
	
	# Check if GameManager.game_data exists and is properly initialized
	if not GameManager.game_data or GameManager.game_data.is_empty():
		GLog.debug("DEBUG MAP MODE: Initializing GameManager game data")
		GameManager.initialize_game_data()
	
	# Ensure we have the maps structure
	if not GameManager.game_data.has("maps"):
		GLog.debug("DEBUG MAP MODE: Adding maps structure to game data")
		GameManager.game_data["maps"] = {}
	
	# Ensure we have current_map set (will trigger procedural map generation)
	if not GameManager.game_data.has("current_map") or GameManager.game_data["current_map"].is_empty():
		GLog.debug("DEBUG MAP MODE: Setting up debug region for procedural generation")
		GameManager.game_data["current_map"] = "debug_procedural"
	
	# Initialize SeedManager for consistent debug behavior
	if not SeedManager.is_initialized:
		GLog.debug("DEBUG MAP MODE: Initializing SeedManager with debug seed")
		SeedManager.set_master_seed(12345)  # Fixed seed for consistent debug layout

# Handle returning from other scenes
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		GLog.debug("Map visibility changed - scene became visible")
		# Reload and refresh map when returning
		if map_visualizer:
			display_current_map()
