extends Resource
class_name MapNodeConfig

# Base configuration class for all map nodes
# This replaces the hardcoded match statements in MapNode.gd

# Basic node identification
@export var node_name: String = ""
@export var description: String = ""
@export var node_type: int = 5  # Default to JUNCTION

# Visual properties
@export_group("Visual Properties")
@export var visual_size: Vector2 = Vector2(64, 64)
@export var visual_color: Color = Color.GRAY
@export var glow_color: Color = Color(0.7, 0.7, 0.7, 0.5)
@export var pulse_effect: bool = false
@export var icon_texture: Texture2D
@export var background_texture: Texture2D

# State-specific colors (optional overrides)
@export_group("State Colors")
@export var state_color_locked: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var state_color_available: Color = Color.WHITE
@export var state_color_current: Color = Color.YELLOW
@export var state_color_completed: Color = Color(0.8, 0.8, 0.8, 0.8)

# Gameplay properties
@export_group("Gameplay Properties") 
@export var safe: bool = false
@export var can_revisit: bool = true
@export var one_time_only: bool = false
@export var always_accessible: bool = false

# Action configuration
@export_group("Actions")
@export var available_actions: Array[String] = []  # Action names that this node supports
@export var action_properties: Dictionary = {}  # Action-specific configuration

# Custom properties for specialized behaviors
@export_group("Custom Properties")
@export var custom_properties: Dictionary = {}

func get_display_name() -> String:
	"""Get the display name for this node type"""
	if not node_name.is_empty():
		return node_name
	return _get_default_name()

func get_display_description() -> String:
	"""Get the full description including type-specific details"""
	if not description.is_empty():
		return description
	return _get_default_description()

func get_type_color() -> Color:
	"""Get the color associated with this node type"""
	return visual_color

func get_state_color(state: int) -> Color:
	"""Get the color for a specific node state"""
	match state:
		0: return state_color_locked     # NodeState.LOCKED
		1: return state_color_available  # NodeState.AVAILABLE
		2: return state_color_current    # NodeState.CURRENT
		3: return state_color_completed  # NodeState.COMPLETED
		_: return Color.WHITE

func _get_default_name() -> String:
	"""Override in subclasses to provide default names"""
	match node_type:
		0: return "City"  # MapNode.NodeType.CITY
		1: return "Camp"  # MapNode.NodeType.CAMP
		2: return "Mine"  # MapNode.NodeType.MINE
		3: return "Settlement"  # MapNode.NodeType.SETTLEMENT
		4: return "Point of Interest"  # MapNode.NodeType.POI
		5: return "Junction"  # MapNode.NodeType.JUNCTION
		6: return "Boss"  # MapNode.NodeType.BOSS
		_: return "Unknown"

func _get_default_description() -> String:
	"""Override in subclasses to provide default descriptions"""
	match node_type:
		0: return "The central hub of the region. Safe haven with all services."
		1: return "A safe place to rest and recover."
		2: return "Rich in resources but dangerous to explore."
		3: return "A bustling community with shops and traders."
		4: return "A mysterious location worth investigating."
		5: return "A crossroads leading to other destinations."
		6: return "A powerful enemy guards the exit from this region."
		_: return "A location on the map."

func get_available_action_names() -> Array[String]:
	"""Get the list of action names available for this node"""
	return available_actions.duplicate()

func get_action_property(action_name: String, property_name: String, default_value = null):
	"""Get a specific property for an action"""
	if action_name in action_properties:
		var action_props = action_properties[action_name]
		if action_props is Dictionary and property_name in action_props:
			return action_props[property_name]
	return default_value

func set_action_property(action_name: String, property_name: String, value):
	"""Set a specific property for an action"""
	if not action_name in action_properties:
		action_properties[action_name] = {}
	action_properties[action_name][property_name] = value

func get_custom_property(property_name: String, default_value = null):
	"""Get a custom property value"""
	return custom_properties.get(property_name, default_value)

func set_custom_property(property_name: String, value):
	"""Set a custom property value"""
	custom_properties[property_name] = value
