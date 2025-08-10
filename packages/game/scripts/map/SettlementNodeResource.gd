extends MapNode
class_name SettlementNodeResource

func _init():
	super._init("", NodeType.SETTLEMENT, Vector2.ZERO)
	
	# Set default properties for settlements
	properties = {
		"shop_tier": 1,
		"population": "small",
		"safety": 0.8,
		"settlement_type": "trading_post",
		"specialization": "general"
	}
	
	# Settlement visual properties
	properties["visual_size"] = Vector2(64, 64)
	properties["visual_color"] = Color.BLUE
	properties["glow_color"] = Color(0.2, 0.4, 1.0, 0.7)
	
	# Settlement-specific actions
	actions = [
		NodeAction.create_shop_action(),
		NodeAction.create_trade_action(),
		create_gather_info_action(),
		create_resupply_action()
	]

static func create_gather_info_action() -> NodeAction:
	var action = NodeAction.new("gather_info", "Gather Information")
	action.time_cost_hours = 1
	action.cost_gold = 5
	action.properties = {
		"description": "Talk to locals and traders for useful information about the region.",
		"info_type": "regional",
		"reveals_nodes": 2
	}
	return action

static func create_resupply_action() -> NodeAction:
	var action = NodeAction.new("resupply", "Resupply")
	action.time_cost_hours = 2
	action.cost_gold = 15
	action.heal_amount = 5
	action.sanity_change = 5
	action.properties = {
		"description": "Purchase basic supplies and provisions from the settlement.",
		"supply_type": "basic"
	}
	return action

func get_description() -> String:
	var desc = "Settlement\n"
	
	var settlement_type = properties.get("settlement_type", "trading_post")
	var population = properties.get("population", "small")
	var shop_tier = properties.get("shop_tier", 1)
	
	match settlement_type:
		"trading_post":
			desc += "A bustling trading post where merchants gather.\n"
		"mining_town":
			desc += "A rough mining town built around resource extraction.\n"
		"frontier_village":
			desc += "A small frontier village on the edge of civilization.\n"
		_:
			desc += "A small community of hardy settlers.\n"
	
	desc += "• Shop available (Tier " + str(shop_tier) + ")\n"
	desc += "• Trade with local merchants\n"
	desc += "• Gather regional information\n"
	desc += "• Resupply and basic services\n"
	desc += "• Population: " + population
	
	var specialization = properties.get("specialization", "general")
	match specialization:
		"mining":
			desc += "\n• Specializes in mining equipment and ore trade"
		"trading":
			desc += "\n• Hub for inter-regional trade routes"
		"crafting":
			desc += "\n• Skilled artisans and custom equipment"
		"information":
			desc += "\n• Well-informed locals with valuable knowledge"
		_:
			desc += "\n• General goods and services"
	
	var safety_level = properties.get("safety", 0.8)
	if safety_level >= 0.9:
		desc += "\n• Very safe, well-protected community"
	elif safety_level >= 0.7:
		desc += "\n• Generally safe, occasional troubles"
	else:
		desc += "\n• Somewhat dangerous, lawless frontier"
	
	return desc