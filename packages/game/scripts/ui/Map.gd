extends Control
class_name MapController

const DEBUG_ENABLED: bool = true

# Import our map system classes
const MapNode = preload("res://scripts/map/MapNode.gd")
const MapEdge = preload("res://scripts/map/MapEdge.gd") 
const MapGenerator = preload("res://scripts/map/MapGenerator.gd")
const MapVisualizer = preload("res://scripts/map/MapVisualizer.gd")
const MapLayoutConfig = preload("res://scripts/map/MapLayoutConfig.gd")

@onready var view_deck_button = $HeaderPanel/HeaderContent/ViewDeckButton
@onready var floor_label = $HeaderPanel/HeaderContent/FloorLabel
@onready var map_scroll_container = $MapScrollContainer

# Graph generation system
var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	setup_graph_system()
	setup_button_connections()
	
	# Force ScrollContainer to fill the viewport below header
	var viewport_size = get_viewport().get_visible_rect().size
	map_scroll_container.position = Vector2(0, 80)
	map_scroll_container.size = Vector2(viewport_size.x, viewport_size.y - 80)
	GLog.debug("Set ScrollContainer size to: " + str(map_scroll_container.size))
	
	generate_new_map()

# Public method to regenerate map (useful for config testing)
func regenerate_map():
	GLog.info("Regenerating map...")
	
	# Reload config in case it changed
	if map_generator:
		map_generator.load_default_config()
		map_generator.initialize_rules()
	
	generate_new_map()

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
	
	# ScrollContainer now fills the entire viewport below the header - no special sizing needed!
	
	# Create visualizer and add it to the scroll container
	map_visualizer = MapVisualizer.new()
	map_visualizer.setup(map_generator)
	
	# No need to clear static layers since we restructured the scene
	
	# Add MapVisualizer to ScrollContainer (now with proper size flags)
	map_scroll_container.add_child(map_visualizer)
	
	# Make visible
	map_visualizer.visible = true
	
	# Connect visualizer signals
	map_visualizer.node_clicked.connect(_on_node_clicked)
	map_visualizer.node_hovered.connect(_on_node_hovered)
	map_visualizer.node_unhovered.connect(_on_node_unhovered)
	
	GLog.debug("Graph system setup complete")

func setup_button_connections():
	view_deck_button.pressed.connect(_on_view_deck_pressed)

func generate_new_map():
	# Only generate if we don't have a map stored in game_data or if no run is active
	if GameManager.is_run_active and GameManager.game_data.has("map") and GameManager.game_data.map != null:
		# Map already exists for this run, restore it instead
		restore_existing_map()
		return
	
	# Generate a new map using the seeded RNG system
	var seed = SeedManager.get_map_random_int(0, 2147483647) if GameManager.is_run_active else -1
	map_generator.generate_map(seed)
	GLog.info("Generated new map for exploration")
	
	# Store the map in game_data for persistence
	if GameManager.is_run_active:
		GameManager.game_data.map = {
			"generator_data": map_generator.get_serializable_data(),
			"current_player_node": map_generator.current_player_node_id,
			"visited_nodes": map_generator.visited_node_ids.duplicate()
		}
		GLog.debug("Map data stored in GameManager")
	
	# Update visualizer size to match the generated map bounds
	var map_bounds = map_visualizer.get_graph_bounds()
	# Use set_deferred to avoid anchor conflicts
	map_visualizer.set_deferred("custom_minimum_size", map_bounds.size)
	map_visualizer.set_deferred("size", map_bounds.size)
	GLog.debug("Updated visualizer size to: " + str(map_bounds.size))
	
	# Force visibility for debugging
	map_visualizer.call_deferred("force_visibility")
	map_visualizer.call_deferred("debug_state")

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

func _on_view_deck_pressed():
	GLog.info("View Deck button pressed")
	SceneManager.load_scene_by_name("deck_viewer")

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
		# Refresh visualization when returning to map
		if map_visualizer:
			map_visualizer.update_visibility()
			map_visualizer.highlight_available_moves()
