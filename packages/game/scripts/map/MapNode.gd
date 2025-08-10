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

@export var id: String = ""
@export var type: NodeType = NodeType.JUNCTION
@export var position: Vector2 = Vector2.ZERO
@export var connections: Array[String] = []
@export var discovered: bool = false
@export var visited: bool = false

# Additional properties for gameplay
@export var properties: Dictionary = {}

func _init(node_id: String = "", node_type: NodeType = NodeType.JUNCTION, pos: Vector2 = Vector2.ZERO):
	id = node_id
	type = node_type
	position = pos
	
	# Set default properties based on type
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
		NodeType.CAMP:
			properties = {
				"heal_amount": 15,
				"rest_time": 4,
				"safe": true
			}
		NodeType.MINE:
			properties = {
				"resource_type": "gold",
				"danger_level": 2,
				"exploration_time": 6
			}
		NodeType.SETTLEMENT:
			properties = {
				"shop_tier": 1,
				"population": "small",
				"safety": 0.8
			}
		NodeType.POI:
			properties = {
				"mystery_level": 1,
				"requires_light": false,
				"one_time": true
			}
		NodeType.JUNCTION:
			properties = {
				"pass_through": true
			}
		NodeType.BOSS:
			properties = {
				"boss_name": "Region Boss",
				"difficulty": 3,
				"one_time": true,
				"rewards_legendary": true
			}

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