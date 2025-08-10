extends MapNode
class_name POINodeResource

func _init():
	super._init("", NodeType.POI, Vector2.ZERO)
	
	# Set default properties for Points of Interest
	properties = {
		"mystery_level": 1,
		"requires_light": false,
		"one_time": true,
		"poi_type": "ruins",
		"danger_rating": "moderate"
	}
	
	# POI visual properties
	properties["visual_size"] = Vector2(64, 64)
	properties["visual_color"] = Color.PURPLE
	properties["glow_color"] = Color(0.7, 0.2, 0.9, 0.8)
	
	# POI-specific actions
	actions = [
		NodeAction.create_investigate_action(),
		NodeAction.create_explore_action(),
		create_observe_action(),
		create_ritual_action()
	]

static func create_observe_action() -> NodeAction:
	var action = NodeAction.new("observe", "Observe from Distance")
	action.time_cost_hours = 1
	action.sanity_change = -2
	action.properties = {
		"description": "Study the mysterious location from a safe distance.",
		"safety": "high",
		"info_gained": "basic"
	}
	return action

static func create_ritual_action() -> NodeAction:
	var action = NodeAction.new("perform_ritual", "Perform Ritual")
	action.time_cost_hours = 4
	action.sanity_change = -20
	action.one_time_only = true
	action.requires_items = ["ritual_components"]
	action.properties = {
		"description": "Attempt to commune with the otherworldly forces at this location.",
		"danger_level": 3,
		"reward_type": "supernatural",
		"requires_preparation": true
	}
	return action

func get_description() -> String:
	var desc = "Point of Interest\n"
	
	var poi_type = properties.get("poi_type", "ruins")
	var mystery_level = properties.get("mystery_level", 1)
	var danger_rating = properties.get("danger_rating", "moderate")
	
	match poi_type:
		"ruins":
			desc += "Ancient ruins with an unsettling aura.\n"
		"stone_circle":
			desc += "A mysterious circle of weathered standing stones.\n"
		"abandoned_mine":
			desc += "An old mine shaft that echoes with strange sounds.\n"
		"crater":
			desc += "A deep crater of unknown origin.\n"
		"monolith":
			desc += "A towering stone monolith covered in indecipherable markings.\n"
		_:
			desc += "A location that defies easy explanation.\n"
	
	desc += "• Mystery level: " + str(mystery_level) + "/3\n"
	desc += "• Danger rating: " + danger_rating + "\n"
	desc += "• Investigation may yield valuable knowledge\n"
	desc += "• Approach with caution - sanity at risk\n"
	
	if properties.get("one_time", true):
		desc += "• Can only be fully explored once"
	else:
		desc += "• Can be revisited, but yields diminishing returns"
	
	if properties.get("requires_light", false):
		desc += "\n• Requires light source for safe exploration"
	
	match mystery_level:
		1:
			desc += "\n• Mildly unsettling, local legends only"
		2:
			desc += "\n• Genuinely disturbing, regional significance"
		3:
			desc += "\n• Profoundly alien, cosmic implications"
	
	return desc