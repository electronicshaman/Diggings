extends MapNode
class_name MineNodeResource

func _init():
	super._init("", NodeType.MINE, Vector2.ZERO)
	
	# Set default properties for mines
	properties = {
		"resource_type": "gold",
		"danger_level": 2,
		"exploration_time": 6,
		"mine_depth": "shallow",
		"equipment_needed": false,
		"collapse_risk": 0.1
	}
	
	# Mine visual properties
	properties["visual_size"] = Vector2(64, 64)
	properties["visual_color"] = Color.ORANGE
	properties["glow_color"] = Color(1.0, 0.5, 0.0, 0.8)
	
	# Mine-specific actions
	actions = [
		NodeAction.create_mine_action(),
		create_careful_mining_action(),
		NodeAction.create_explore_action(),
		create_survey_action()
	]

static func create_careful_mining_action() -> NodeAction:
	var action = NodeAction.new("careful_mine", "Mine Carefully")
	action.time_cost_hours = 8
	action.sanity_change = -2  # Less sanity loss than regular mining
	action.properties = {
		"description": "Take your time to mine safely, reducing risks but taking longer.",
		"gold_min": 8,
		"gold_max": 20,
		"danger_level": 1,
		"accident_chance": 0.05,
		"efficiency": "safe"
	}
	return action

static func create_survey_action() -> NodeAction:
	var action = NodeAction.new("survey", "Survey Mine")
	action.time_cost_hours = 3
	action.one_time_only = true
	action.properties = {
		"description": "Assess the mine's potential and safety before committing to extraction.",
		"reveals_info": true,
		"safety_bonus": true
	}
	return action

func get_description() -> String:
	var desc = "Mine\n"
	desc += "A mineral extraction site with potential riches and dangers.\n"
	
	var resource_type = properties.get("resource_type", "gold")
	var danger_level = properties.get("danger_level", 2)
	var exploration_time = properties.get("exploration_time", 6)
	
	desc += "• Mine for " + resource_type + " and other valuable materials\n"
	desc += "• Danger level: " + str(danger_level) + "/3\n"
	desc += "• Standard mining takes " + str(exploration_time) + " hours\n"
	desc += "• Risk vs reward location\n"
	desc += "• Can be revisited for additional resources"
	
	match properties.get("mine_depth", "shallow"):
		"shallow":
			desc += "\n• Surface-level excavation, moderate yields"
		"deep":
			desc += "\n• Deep shaft mining, high yields but dangerous"
		"abandoned":
			desc += "\n• Old mine with unknown hazards and treasures"
	
	if properties.get("equipment_needed", false):
		desc += "\n• Requires proper mining equipment"
	
	return desc