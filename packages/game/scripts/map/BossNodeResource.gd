extends MapNode
class_name BossNodeResource

func _init():
	super._init("", NodeType.BOSS, Vector2.ZERO)
	
	# Set default properties for boss nodes
	properties = {
		"boss_name": "Region Guardian",
		"difficulty": 3,
		"one_time": true,
		"rewards_legendary": true,
		"boss_type": "eldritch_horror",
		"challenge_rating": "high"
	}
	
	# Boss visual properties - larger and more imposing
	properties["visual_size"] = Vector2(90, 90)
	properties["visual_color"] = Color.DARK_RED
	properties["glow_color"] = Color(0.8, 0.0, 0.0, 0.9)
	properties["pulse_effect"] = true
	
	# Boss-specific actions (limited, as combat is the main interaction)
	actions = [
		create_challenge_action(),
		create_study_opponent_action(),
		create_prepare_action()
	]

static func create_challenge_action() -> NodeAction:
	var action = NodeAction.new("challenge", "Challenge to Combat")
	action.properties = {
		"description": "Face the guardian in mortal combat - victory grants passage to the next region.",
		"combat_type": "boss",
		"stakes": "high",
		"retreat_allowed": false
	}
	return action

static func create_study_opponent_action() -> NodeAction:
	var action = NodeAction.new("study", "Study Opponent")
	action.time_cost_hours = 2
	action.sanity_change = -10
	action.one_time_only = true
	action.properties = {
		"description": "Observe the guardian to learn its weaknesses and patterns.",
		"combat_bonus": true,
		"info_type": "tactical"
	}
	return action

static func create_prepare_action() -> NodeAction:
	var action = NodeAction.new("prepare", "Prepare for Battle")
	action.time_cost_hours = 4
	action.cost_gold = 25
	action.properties = {
		"description": "Make final preparations before the decisive battle.",
		"buff_duration": "combat",
		"preparation_type": "comprehensive"
	}
	return action

func get_type_name() -> String:
	return properties.get("boss_name", "Region Guardian")

func get_description() -> String:
	var boss_name = properties.get("boss_name", "Region Guardian")
	var difficulty = properties.get("difficulty", 3)
	var boss_type = properties.get("boss_type", "eldritch_horror")
	
	var desc = boss_name + "\n"
	
	match boss_type:
		"eldritch_horror":
			desc += "An otherworldly entity that guards the passage to deeper mysteries.\n"
		"corrupted_prospector":
			desc += "Once human, now twisted by exposure to cosmic horrors.\n"
		"ancient_guardian":
			desc += "An ageless sentinel bound to protect this region's secrets.\n"
		"mining_baron_ghost":
			desc += "The vengeful spirit of a mining baron who died in greed.\n"
		_:
			desc += "A powerful entity that blocks further progress.\n"
	
	desc += "• Difficulty: " + str(difficulty) + "/5\n"
	desc += "• Challenge rating: " + properties.get("challenge_rating", "high") + "\n"
	
	if properties.get("rewards_legendary", false):
		desc += "• Victory grants legendary rewards\n"
	
	desc += "• Defeating unlocks the next region\n"
	desc += "• Retreat may not be possible once engaged\n"
	desc += "• Prepare thoroughly before challenging"
	
	match difficulty:
		1:
			desc += "\n• Manageable with basic preparation"
		2:
			desc += "\n• Requires good equipment and strategy"
		3:
			desc += "\n• Serious threat, comprehensive preparation needed"
		4:
			desc += "\n• Extreme danger, only for experienced adventurers"
		5:
			desc += "\n• Near-impossible challenge, legendary difficulty"
	
	return desc

# Override state management for bosses
func can_revisit() -> bool:
	# Bosses typically cannot be revisited once defeated
	return false