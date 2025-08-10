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

# Legacy state flags (kept for compatibility, will be phased out)
@export var discovered: bool = false
@export var visited: bool = false

# New unified state system
@export var state: NodeState = NodeState.LOCKED

# Visual properties for enhanced nodes
@export var icon_texture: Texture2D
@export var background_texture: Texture2D

# Additional properties for gameplay
@export var properties: Dictionary = {}

# Available actions for this node
@export var actions: Array[NodeAction] = []

func _init(node_id: String = "", node_type: NodeType = NodeType.JUNCTION, pos: Vector2 = Vector2.ZERO):
	id = node_id
	type = node_type
	position = pos
	
	# Set default properties and actions based on type
	match type:
		NodeType.CITY:
			properties = {
				"city_name": "City",
				"heal_to_full": true,
				"has_shop": true,
				"has_deck_management": true,
				"safe": true,
				"always_accessible": true
			}
			actions = [
				NodeAction.create_rest_action(),
				NodeAction.create_shop_action()
			]
		NodeType.CAMP:
			properties = {
				"heal_amount": 15,
				"rest_time": 4,
				"safe": true
			}
			actions = [
				NodeAction.create_rest_action()
			]
		NodeType.MINE:
			properties = {
				"resource_type": "gold",
				"danger_level": 2,
				"exploration_time": 6
			}
			actions = [
				NodeAction.create_mine_action(),
				NodeAction.create_explore_action()
			]
		NodeType.SETTLEMENT:
			properties = {
				"shop_tier": 1,
				"population": "small",
				"safety": 0.8
			}
			actions = [
				NodeAction.create_shop_action(),
				NodeAction.create_trade_action()
			]
		NodeType.POI:
			properties = {
				"mystery_level": 1,
				"requires_light": false,
				"one_time": true
			}
			actions = [
				NodeAction.create_investigate_action(),
				NodeAction.create_explore_action()
			]
		NodeType.JUNCTION:
			properties = {
				"pass_through": true
			}
			actions = []  # Junctions typically have no actions
		NodeType.BOSS:
			properties = {
				"boss_name": "Region Boss",
				"difficulty": 3,
				"one_time": true,
				"rewards_legendary": true
			}
			actions = []  # Boss fights are handled differently

func connect_to(other_node_id: String) -> void:
	if other_node_id not in connections:
		connections.append(other_node_id)

func disconnect_from(other_node_id: String) -> void:
	connections.erase(other_node_id)

func is_connected_to(other_node_id: String) -> bool:
	return other_node_id in connections

func get_type_name() -> String:
	match type:
		NodeType.CITY: return properties.get("city_name", "City")
		NodeType.CAMP: return "Camp"
		NodeType.MINE: return "Mine"
		NodeType.SETTLEMENT: return "Settlement"
		NodeType.POI: return "Point of Interest"
		NodeType.JUNCTION: return "Junction"
		NodeType.BOSS: return properties.get("boss_name", "Boss")
		_: return "Unknown"

func get_type_color() -> Color:
	match type:
		NodeType.CITY: return Color.GOLD
		NodeType.CAMP: return Color.GREEN
		NodeType.MINE: return Color.ORANGE
		NodeType.SETTLEMENT: return Color.BLUE
		NodeType.POI: return Color.PURPLE
		NodeType.JUNCTION: return Color.GRAY
		NodeType.BOSS: return Color.RED
		_: return Color.WHITE

func discover() -> void:
	discovered = true
	GLog.debug("Node discovered: " + get_type_name() + " (" + id + ")")

func visit() -> void:
	if not discovered:
		discover()
	visited = true
	GLog.debug("Node visited: " + get_type_name() + " (" + id + ")")

func get_description() -> String:
	var desc = get_type_name()
	if not discovered:
		return "Unexplored Location"
	
	match type:
		NodeType.CITY:
			desc += "\nThe central hub of the region. Safe haven with all services."
		NodeType.CAMP:
			desc += "\nA safe place to rest and recover."
		NodeType.MINE:
			desc += "\nRich in resources but dangerous to explore."
		NodeType.SETTLEMENT:
			desc += "\nA bustling community with shops and traders."
		NodeType.POI:
			desc += "\nA mysterious location worth investigating."
		NodeType.JUNCTION:
			desc += "\nA crossroads leading to other destinations."
		NodeType.BOSS:
			desc += "\nA powerful enemy guards the exit from this region."
	
	return desc

# New state management methods
func get_state() -> NodeState:
	return state

func set_state(new_state: NodeState):
	state = new_state
	# Update legacy flags for compatibility
	match state:
		NodeState.LOCKED:
			discovered = false
			visited = false
		NodeState.AVAILABLE:
			discovered = true
			visited = false
		NodeState.CURRENT:
			discovered = true  
			visited = true
		NodeState.COMPLETED:
			discovered = true
			visited = true

func is_interactive() -> bool:
	"""Returns true if the node can be clicked/selected"""
	match state:
		NodeState.AVAILABLE:
			return true
		NodeState.COMPLETED:
			# Some completed nodes can be revisited
			return can_revisit()
		_:
			return false

func can_revisit() -> bool:
	"""Returns true if this node type can be visited multiple times"""
	match type:
		NodeType.CITY, NodeType.CAMP, NodeType.SETTLEMENT, NodeType.MINE:
			return true
		NodeType.POI, NodeType.JUNCTION, NodeType.BOSS:
			return false
		_:
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
