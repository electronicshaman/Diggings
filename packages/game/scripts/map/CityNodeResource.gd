extends MapNode
class_name CityNodeResource

func _init():
	super._init("", NodeType.CITY, Vector2.ZERO)
	
	# Set default properties for cities
	properties = {
		"city_name": "Gold Rush City",
		"heal_to_full": true,
		"has_shop": true,
		"has_deck_management": true,
		"safe": true,
		"always_accessible": true,
		"population": "large",
		"prosperity": "high"
	}
	
	# Cities are larger and more prominent
	properties["visual_size"] = Vector2(80, 80)
	properties["visual_color"] = Color.GOLD
	properties["glow_color"] = Color(1.0, 0.8, 0.0, 0.8)
	
	# City-specific actions
	actions = [
		NodeAction.create_rest_action(),
		NodeAction.create_shop_action(),
		create_city_heal_action(),
		create_deck_management_action()
	]

static func create_city_heal_action() -> NodeAction:
	var action = NodeAction.new("full_heal", "Full Recovery")
	action.heal_amount = 999  # Effectively full heal
	action.sanity_change = 50
	action.time_cost_hours = 8
	action.cost_gold = 20
	action.properties = {
		"description": "Get a full night's rest in the safety of the city.",
		"comfort_level": "luxury"
	}
	return action

static func create_deck_management_action() -> NodeAction:
	var action = NodeAction.new("deck_management", "Manage Deck")
	action.properties = {
		"description": "Review and organize your card collection.",
		"allows_card_removal": true,
		"allows_card_upgrade": true
	}
	return action

func get_type_name() -> String:
	return properties.get("city_name", "City")

func get_description() -> String:
	var desc = get_type_name() + "\n"
	desc += "The bustling heart of the region - a safe haven offering all services.\n"
	desc += "• Complete healing and rest available\n"
	desc += "• Well-stocked shops with premium goods\n"
	desc += "• Deck management and card services\n"
	desc += "• Always accessible for retreat"
	
	if properties.get("prosperity", "") == "high":
		desc += "\n• Prosperous trading hub"
	
	return desc