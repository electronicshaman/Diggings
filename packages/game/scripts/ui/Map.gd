extends Control
class_name MapController

const DEBUG_ENABLED: bool = true

# Import our map system classes
const MapNode = preload("res://scripts/map/MapNode.gd")
const MapEdge = preload("res://scripts/map/MapEdge.gd") 
const MapGenerator = preload("res://scripts/map/MapGenerator.gd")
const MapVisualizer = preload("res://scripts/map/MapVisualizer.gd")

@onready var view_deck_button = $UIContainer/HeaderPanel/HeaderContent/ViewDeckButton
@onready var floor_label = $UIContainer/HeaderPanel/HeaderContent/FloorLabel
@onready var map_scroll_container = $UIContainer/MapScrollContainer

# Graph generation system
var map_generator: MapGenerator
var map_visualizer: MapVisualizer

func _ready():
	setup_graph_system()
	setup_button_connections()
	generate_new_map()

func setup_graph_system():
	# Create map generator
	map_generator = MapGenerator.new()
	add_child(map_generator)
	
	# Create visualizer and add it to the scroll container
	map_visualizer = MapVisualizer.new()
	map_visualizer.setup(map_generator)
	
	# Clear the old static map layers
	var map_layers = $UIContainer/MapScrollContainer/MapLayers
	if map_layers:
		map_layers.queue_free()
	
	# Add visualizer to scroll container
	map_scroll_container.add_child(map_visualizer)
	
	# Ensure the visualizer is visible
	map_visualizer.visible = true
	
	# Connect visualizer signals
	map_visualizer.node_clicked.connect(_on_node_clicked)
	map_visualizer.node_hovered.connect(_on_node_hovered)
	map_visualizer.node_unhovered.connect(_on_node_unhovered)
	
	GLog.debug("Graph system setup complete")

func setup_button_connections():
	view_deck_button.pressed.connect(_on_view_deck_pressed)

func generate_new_map():
	# Generate a new map using the current run seed or random
	var seed = GameManager.current_run_seed if GameManager.is_run_active else -1
	map_generator.generate_map(seed)
	GLog.info("Generated new map for exploration")

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
	if randf() < 0.6:  # 60% chance of combat
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
	if randf() < 0.7:  # 70% chance of event
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
