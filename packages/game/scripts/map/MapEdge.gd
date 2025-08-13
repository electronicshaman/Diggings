extends Resource
class_name MapEdge

@export var from_node: String = ""
@export var to_node: String = ""
@export var travel_time: int = 2  # Hours to traverse
@export var difficulty: int = 1   # 1-5 difficulty scale
@export var requirements: Array[String] = []  # Conditions to traverse
@export var properties: Dictionary = {}

func _init(from: String = "", to: String = "", time: int = 2, diff: int = 1):
	from_node = from
	to_node = to
	travel_time = time
	difficulty = diff
	
	# Default properties
	properties = {
		"terrain": "path",
		"safety": 0.7,
		"visibility": 1.0
	}

func get_other_node(current_node: String) -> String:
	if current_node == from_node:
		return to_node
	elif current_node == to_node:
		return from_node
	else:
		push_error("Node " + current_node + " is not part of this edge")
		return ""

func connects(node_a: String, node_b: String) -> bool:
	return (from_node == node_a and to_node == node_b) or (from_node == node_b and to_node == node_a)

func can_traverse(player_state: Dictionary = {}) -> bool:
	# Check if player meets requirements to traverse this edge
	for requirement in requirements:
		match requirement:
			"light_source":
				if not player_state.get("has_light", false):
					return false
			"climbing_gear":
				if not player_state.get("has_climbing", false):
					return false
			"boat":
				if not player_state.get("has_boat", false):
					return false
	
	return true

func get_travel_cost() -> Dictionary:
	var cost = {
		"time": travel_time,
		"sanity": 0,
		"energy": 1
	}
	
	# Night travel penalties would be calculated elsewhere
	# based on current game time
	
	return cost

func get_description() -> String:
	var desc = "A " + properties.get("terrain", "path")
	
	if difficulty > 3:
		desc += " (Dangerous)"
	elif difficulty > 1:
		desc += " (Challenging)"
	
	if requirements.size() > 0:
		desc += "\nRequires: " + ", ".join(requirements)
	
	return desc
