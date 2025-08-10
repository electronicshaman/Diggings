extends Resource
class_name MapNode

enum NodeType {
	CITY,      # Central hub - safe haven with all services
	CAMP,      # Rest and healing locations
	MINE,      # Resource gathering with danger
	SETTLEMENT, # Trading posts and NPCs
	POI,       # Points of interest, mysteries
	JUNCTION,  # Simple path connectors
	BOSS       # Boss encounter - map completion
}

enum NodeState {
	LOCKED,      # Not accessible - grey/hidden
	AVAILABLE,   # Can be visited - normal appearance  
	CURRENT,     # Player's current location - highlighted
	COMPLETED    # Already visited - contextual appearance
}

@export var id: String = ""
@export var type: NodeType = NodeType.JUNCTION
@export var position: Vector2 = Vector2.ZERO
@export var connections: Array[String] = []

# Unified state system
@export var state: NodeState = NodeState.LOCKED

# Configuration resource that defines this node's properties and behavior
@export var config: NodeConfig

# Available actions for this node (generated from config)  
@export var actions: Array[NodeAction] = []

func _init(node_id: String = "", node_type: NodeType = NodeType.JUNCTION, pos: Vector2 = Vector2.ZERO, node_config: NodeConfig = null):
	id = node_id
	type = node_type
	position = pos
	config = node_config
	
	# If no config provided, create a default one based on type
	if config == null:
		config = _create_default_config(type)
	
	# Generate actions from config
	_generate_actions_from_config()

func set_config(new_config: NodeConfig):
	"""Set a new configuration for this node"""
	config = new_config
	if config:
		type = config.node_type
		_generate_actions_from_config()

func _create_default_config(node_type: NodeType) -> NodeConfig:
	"""Create a basic default config if none is provided"""
	var config = NodeConfig.new()
	config.node_type = node_type
	
	# Set basic defaults based on type
	match node_type:
		NodeType.CITY:
			config.node_name = "City"
			config.visual_color = Color.GOLD
			config.visual_size = Vector2(80, 80)
			config.safe = true
			config.always_accessible = true
			config.available_actions.append("rest")
			config.available_actions.append("shop")
		NodeType.CAMP:
			config.node_name = "Camp"
			config.visual_color = Color.FOREST_GREEN
			config.visual_size = Vector2(64, 64)
			config.safe = true
			config.available_actions.append("rest")
		NodeType.MINE:
			config.node_name = "Mine"
			config.visual_color = Color.ORANGE
			config.visual_size = Vector2(70, 70)
			config.available_actions.append("mine")
			config.available_actions.append("explore")
		NodeType.SETTLEMENT:
			config.node_name = "Settlement"
			config.visual_color = Color.BLUE
			config.visual_size = Vector2(68, 68)
			config.safe = true
			config.available_actions.append("shop")
			config.available_actions.append("trade")
			config.available_actions.append("rest")
		NodeType.POI:
			config.node_name = "Point of Interest"
			config.visual_color = Color.PURPLE
			config.visual_size = Vector2(66, 66)
			config.one_time_only = true
			config.available_actions.append("investigate")
		NodeType.JUNCTION:
			config.node_name = "Junction"
			config.visual_color = Color.GRAY
			config.visual_size = Vector2(48, 48)
			config.safe = true
			config.available_actions.append("survey_paths")
		NodeType.BOSS:
			config.node_name = "Boss"
			config.visual_color = Color.DARK_RED
			config.visual_size = Vector2(90, 90)
			config.one_time_only = true
			config.can_revisit = false
			config.available_actions.append("challenge")
	
	return config

func _generate_actions_from_config():
	"""Generate NodeAction objects from config data"""
	actions.clear()
	
	if not config:
		return
	
	# Create actions based on config's available_actions list
	for action_name in config.get_available_action_names():
		var action = _create_action_from_config(action_name)
		if action:
			actions.append(action)

func _create_action_from_config(action_name: String) -> NodeAction:
	"""Create a NodeAction from config data"""
	var action = NodeAction.new()
	action.action_name = action_name
	
	# Get action properties from config
	var props = config.action_properties.get(action_name, {})
	
	# Set display text (use a nice formatted version)
	action.display_text = _format_action_name(action_name)
	
	# Set common properties
	var description = props.get("description", "")
	action.time_cost_hours = props.get("time_cost_hours", 0)
	action.cost_gold = props.get("cost_gold", 0)
	action.heal_amount = props.get("heal_amount", 0)
	action.sanity_change = props.get("sanity_change", 0)
	action.one_time_only = props.get("one_time_only", false)
	action.cooldown_hours = props.get("cooldown_hours", 0)
	
	# Set requirements
	action.requires_items = props.get("requires_items", [])
	action.requires_stats = props.get("requires_stats", {})
	
	# Store all properties (including description)
	action.properties = props.duplicate()
	
	return action

func _format_action_name(action_name: String) -> String:
	"""Convert action_name to a nice display format"""
	match action_name:
		"rest": return "Rest and Recover"
		"quick_rest": return "Quick Rest"
		"brief_rest": return "Brief Rest"
		"shop": return "Visit Shop"
		"trade": return "Trade with Locals"
		"mine": return "Mine for Gold"
		"explore": return "Explore Location"
		"investigate": return "Investigate Mystery"
		"observe": return "Observe from Distance"
		"challenge": return "Challenge to Combat"
		"study_opponent": return "Study Opponent"
		"prepare": return "Prepare for Battle"
		"survey_paths": return "Survey Paths"
		"tend_fire": return "Tend Campfire"
		"gather_info": return "Gather Information"
		"quick_search": return "Quick Search"
		"deck_management": return "Manage Deck"
		_:
			# Convert snake_case to Title Case
			return action_name.replace("_", " ").capitalize()

func connect_to(other_node_id: String) -> void:
	if other_node_id not in connections:
		connections.append(other_node_id)

func disconnect_from(other_node_id: String) -> void:
	connections.erase(other_node_id)

func is_connected_to(other_node_id: String) -> bool:
	return other_node_id in connections

func get_type_name() -> String:
	if config:
		return config.get_display_name()
	else:
		GLog.error("MapNode " + id + " has no config! All nodes must have NodeConfig resources.")
		return "ERROR_NO_CONFIG"

func get_type_color() -> Color:
	if config:
		return config.get_type_color()
	else:
		GLog.error("MapNode " + id + " has no config! All nodes must have NodeConfig resources.")
		return Color.MAGENTA  # Obvious error color

func discover() -> void:
	if state == NodeState.LOCKED:
		set_state(NodeState.AVAILABLE)
	GLog.debug("Node discovered: " + get_type_name() + " (" + id + ")")

func visit() -> void:
	discover()  # Ensure discovered first
	set_state(NodeState.CURRENT)
	GLog.debug("Node visited: " + get_type_name() + " (" + id + ")")

func get_description() -> String:
	if state == NodeState.LOCKED:
		return "Unexplored Location"
	
	if config:
		return config.get_display_description()
	else:
		GLog.error("MapNode " + id + " has no config! All nodes must have NodeConfig resources.")
		return "ERROR: No configuration data found for this node."

# New state management methods
func get_state() -> NodeState:
	return state

func set_state(new_state: NodeState):
	state = new_state

func is_interactive() -> bool:
	"""Returns true if the node can be clicked/selected"""
	match state:
		NodeState.AVAILABLE:
			return true
		NodeState.CURRENT:
			return true
		NodeState.COMPLETED:
			# Some completed nodes can be revisited
			return can_revisit()
		_:
			return false

func can_revisit() -> bool:
	"""Returns true if this node type can be visited multiple times"""
	if config:
		return config.can_revisit
	else:
		GLog.error("MapNode " + id + " has no config! All nodes must have NodeConfig resources.")
		return false

func get_state_alpha() -> float:
	"""Returns the visual alpha for this node's current state"""
	match state:
		NodeState.LOCKED:
			return 0.3
		NodeState.AVAILABLE:
			return 1.0
		NodeState.CURRENT:
			return 1.0
		NodeState.COMPLETED:
			return 0.8 if can_revisit() else 0.6
		_:
			return 1.0

# NodeAction system methods
func get_available_actions(player_data: Dictionary) -> Array[NodeAction]:
	"""Get all actions that the player can currently perform at this node"""
	var available: Array[NodeAction] = []
	
	for action in actions:
		if action.can_execute(player_data, self):
			available.append(action)
	
	return available

func execute_action(action_name: String, player_data: Dictionary) -> Dictionary:
	"""Execute a specific action by name"""
	for action in actions:
		if action.action_name == action_name:
			return action.execute(player_data, self)
	
	return {
		"success": false,
		"message": "Action '" + action_name + "' not found",
		"effects": {},
		"events": []
	}

func has_action(action_name: String) -> bool:
	"""Check if this node has a specific action"""
	for action in actions:
		if action.action_name == action_name:
			return true
	return false

func add_action(action: NodeAction):
	"""Add a new action to this node"""
	if not has_action(action.action_name):
		actions.append(action)

func remove_action(action_name: String):
	"""Remove an action from this node"""
	for i in range(actions.size() - 1, -1, -1):
		if actions[i].action_name == action_name:
			actions.remove_at(i)
			break

func get_action_descriptions(player_data: Dictionary) -> Array[String]:
	"""Get formatted descriptions of all available actions"""
	var descriptions: Array[String] = []
	
	for action in get_available_actions(player_data):
		descriptions.append(action.get_description(player_data, self))
	
	return descriptions

# Helper methods for config-based properties

func get_visual_size() -> Vector2:
	"""Get the visual size for this node"""
	if config:
		return config.visual_size
	return Vector2(64, 64)

func get_glow_color() -> Color:
	"""Get the glow color for this node"""
	if config:
		return config.glow_color
	return Color(0.7, 0.7, 0.7, 0.5)

func has_pulse_effect() -> bool:
	"""Check if this node should pulse"""
	if config:
		return config.pulse_effect
	return false

func is_safe() -> bool:
	"""Check if this node is considered safe"""
	if config:
		return config.safe
	return false

func is_always_accessible() -> bool:
	"""Check if this node is always accessible"""
	if config:
		return config.always_accessible
	return false

func get_custom_property(property_name: String, default_value = null):
	"""Get a custom property from the config"""
	if config:
		return config.get_custom_property(property_name, default_value)
	return default_value

func set_custom_property(property_name: String, value):
	"""Set a custom property in the config"""
	if config:
		config.set_custom_property(property_name, value)

# Static helper method for loading node configs from .tres files
static func load_config_from_file(file_path: String) -> NodeConfig:
	"""Load a NodeConfig from a .tres file"""
	if ResourceLoader.exists(file_path):
		return load(file_path) as NodeConfig
	else:
		GLog.debug("NodeConfig file not found: " + file_path)
		return null

# Factory method for creating nodes with config files
static func create_from_config_file(node_id: String, config_path: String, pos: Vector2 = Vector2.ZERO) -> MapNode:
	"""Create a MapNode with configuration loaded from a .tres file"""
	var node_config = load_config_from_file(config_path)
	if node_config:
		return MapNode.new(node_id, node_config.node_type, pos, node_config)
	else:
		GLog.debug("Failed to create node from config: " + config_path)
		return MapNode.new(node_id, NodeType.JUNCTION, pos)
