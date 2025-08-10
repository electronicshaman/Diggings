extends MapNode
class_name CampNodeResource

func _init():
	super._init("", NodeType.CAMP, Vector2.ZERO)
	
	# Set default properties for camps
	properties = {
		"heal_amount": 15,
		"rest_time": 4,
		"safe": true,
		"camp_type": "basic",
		"fire_quality": "good"
	}
	
	# Camp visual properties
	properties["visual_size"] = Vector2(64, 64)
	properties["visual_color"] = Color.FOREST_GREEN
	properties["glow_color"] = Color(0.0, 0.8, 0.2, 0.7)
	
	# Camp-specific actions
	actions = [
		NodeAction.create_rest_action(),
		create_quick_rest_action(),
		create_campfire_action()
	]

static func create_quick_rest_action() -> NodeAction:
	var action = NodeAction.new("quick_rest", "Quick Rest")
	action.heal_amount = 8
	action.sanity_change = 5
	action.time_cost_hours = 2
	action.properties = {
		"description": "Take a short break to catch your breath.",
		"efficiency": "fast"
	}
	return action

static func create_campfire_action() -> NodeAction:
	var action = NodeAction.new("tend_fire", "Tend Campfire")
	action.sanity_change = 15
	action.time_cost_hours = 1
	action.properties = {
		"description": "Sit by the warming fire and restore your spirits.",
		"comfort": "moderate",
		"light_source": true
	}
	return action

func get_description() -> String:
	var desc = "Camp\n"
	desc += "A safe resting place in the wilderness.\n"
	
	var heal_amount = properties.get("heal_amount", 15)
	var rest_time = properties.get("rest_time", 4)
	
	desc += "• Heal " + str(heal_amount) + " HP over " + str(rest_time) + " hours\n"
	desc += "• Restore sanity by the campfire\n"
	desc += "• Safe location - no random encounters\n"
	desc += "• Can be revisited multiple times"
	
	match properties.get("camp_type", "basic"):
		"basic":
			desc += "\n• Simple campsite with basic amenities"
		"improved":
			desc += "\n• Well-maintained camp with extra comforts"
		"hidden":
			desc += "\n• Secluded location, very safe"
	
	return desc