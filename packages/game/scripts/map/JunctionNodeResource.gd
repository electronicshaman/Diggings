extends MapNode
class_name JunctionNodeResource

func _init():
	super._init("", NodeType.JUNCTION, Vector2.ZERO)
	
	# Set default properties for junctions
	properties = {
		"pass_through": true,
		"junction_type": "crossroads",
		"path_count": 3,
		"visibility_bonus": true
	}
	
	# Junction visual properties - smaller and neutral
	properties["visual_size"] = Vector2(48, 48)
	properties["visual_color"] = Color.GRAY
	properties["glow_color"] = Color(0.7, 0.7, 0.7, 0.5)
	
	# Junction-specific actions (usually minimal)
	actions = [
		create_survey_paths_action(),
		create_rest_briefly_action()
	]

static func create_survey_paths_action() -> NodeAction:
	var action = NodeAction.new("survey_paths", "Survey Available Paths")
	action.time_cost_hours = 1
	action.properties = {
		"description": "Get a better view of nearby locations and possible routes.",
		"reveals_connections": true,
		"info_type": "navigation"
	}
	return action

static func create_rest_briefly_action() -> NodeAction:
	var action = NodeAction.new("brief_rest", "Brief Rest")
	action.time_cost_hours = 1
	action.heal_amount = 3
	action.sanity_change = 2
	action.properties = {
		"description": "Take a quick break at this crossroads.",
		"efficiency": "minimal"
	}
	return action

func get_description() -> String:
	var desc = "Junction\n"
	
	var junction_type = properties.get("junction_type", "crossroads")
	var path_count = properties.get("path_count", 3)
	
	match junction_type:
		"crossroads":
			desc += "A well-traveled crossroads where multiple paths converge.\n"
		"fork":
			desc += "A simple fork in the path offering different routes.\n"
		"bridge":
			desc += "A bridge crossing that connects distant areas.\n"
		"overlook":
			desc += "A high vantage point with good visibility.\n"
		_:
			desc += "A connection point between different paths.\n"
	
	desc += "• " + str(path_count) + " paths available from this location\n"
	desc += "• Pass-through location - no special features\n"
	desc += "• Good place to plan your next move\n"
	
	if properties.get("visibility_bonus", false):
		desc += "• Offers good view of nearby areas\n"
	
	desc += "• Safe stopping point for brief rest"
	
	return desc

# Junctions are always pass-through and can be revisited
func can_revisit() -> bool:
	return true