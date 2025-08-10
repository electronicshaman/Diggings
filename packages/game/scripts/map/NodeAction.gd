extends Resource
class_name NodeAction

# Base class for modular node actions/behaviors
# Allows different node types to have specific behaviors without coupling

@export var action_name: String = ""
@export var display_text: String = ""
@export var icon_texture: Texture2D
@export var enabled: bool = true

# Optional requirements for this action to be available
@export var requires_items: Array[String] = []
@export var requires_stats: Dictionary = {}  # stat_name -> minimum_value
@export var cooldown_hours: int = 0
@export var one_time_only: bool = false

# Action results/effects
@export var cost_gold: int = 0
@export var heal_amount: int = 0
@export var sanity_change: int = 0
@export var time_cost_hours: int = 0

# Custom properties for specific actions
@export var properties: Dictionary = {}

func _init(name: String = "", display: String = ""):
	action_name = name
	display_text = display if not display.is_empty() else name

func can_execute(player_data: Dictionary, node: MapNode) -> bool:
	"""Check if this action can be executed by the player at this node"""
	
	if not enabled:
		return false
	
	# Check gold requirements
	if cost_gold > 0:
		var player_gold = player_data.get("gold", 0)
		if player_gold < cost_gold:
			return false
	
	# Check item requirements
	var player_inventory = player_data.get("inventory", [])
	for required_item in requires_items:
		if required_item not in player_inventory:
			return false
	
	# Check stat requirements
	var player_stats = player_data.get("stats", {})
	for stat_name in requires_stats:
		var required_value = requires_stats[stat_name]
		var current_value = player_stats.get(stat_name, 0)
		if current_value < required_value:
			return false
	
	# Check one-time restrictions
	if one_time_only:
		var action_history = player_data.get("action_history", {})
		var node_history = action_history.get(node.id, [])
		if action_name in node_history:
			return false
	
	# Check cooldowns (simplified - would need proper time tracking)
	if cooldown_hours > 0:
		var last_used = player_data.get("last_action_times", {}).get(node.id + "_" + action_name, 0)
		var current_time = Time.get_ticks_msec() / 1000  # Simplified time
		if (current_time - last_used) < (cooldown_hours * 3600):
			return false
	
	return true

func execute(player_data: Dictionary, node: MapNode) -> Dictionary:
	"""Execute the action and return results"""
	var result = {
		"success": false,
		"message": "",
		"effects": {},
		"events": []
	}
	
	if not can_execute(player_data, node):
		result.message = "Cannot execute " + display_text
		return result
	
	# Apply costs
	if cost_gold > 0:
		player_data.gold = player_data.get("gold", 0) - cost_gold
		result.effects["gold_spent"] = cost_gold
	
	# Apply benefits
	if heal_amount > 0:
		var current_hp = player_data.get("hp", 0)
		var max_hp = player_data.get("max_hp", 100)
		var new_hp = min(current_hp + heal_amount, max_hp)
		var actual_heal = new_hp - current_hp
		player_data.hp = new_hp
		result.effects["healed"] = actual_heal
	
	if sanity_change != 0:
		var current_sanity = player_data.get("sanity", 0)
		var max_sanity = player_data.get("max_sanity", 100)
		var new_sanity = clamp(current_sanity + sanity_change, 0, max_sanity)
		player_data.sanity = new_sanity
		result.effects["sanity_change"] = sanity_change
	
	# Apply time cost (game time progression)
	if time_cost_hours > 0:
		var current_time = player_data.get("game_time_hours", 0)
		player_data.game_time_hours = current_time + time_cost_hours
		result.effects["time_passed"] = time_cost_hours
	
	# Record action in history
	if one_time_only or cooldown_hours > 0:
		if not player_data.has("action_history"):
			player_data.action_history = {}
		if not player_data.action_history.has(node.id):
			player_data.action_history[node.id] = []
		
		if one_time_only:
			player_data.action_history[node.id].append(action_name)
		
		if cooldown_hours > 0:
			if not player_data.has("last_action_times"):
				player_data.last_action_times = {}
			player_data.last_action_times[node.id + "_" + action_name] = Time.get_ticks_msec() / 1000
	
	result.success = true
	result.message = "Executed " + display_text
	
	return result

func get_description(player_data: Dictionary, node: MapNode) -> String:
	"""Get a detailed description of what this action does"""
	var desc = display_text
	
	var effects = []
	if heal_amount > 0:
		effects.append("Heal " + str(heal_amount) + " HP")
	if sanity_change > 0:
		effects.append("Restore " + str(sanity_change) + " Sanity")
	elif sanity_change < 0:
		effects.append("Lose " + str(abs(sanity_change)) + " Sanity")
	if cost_gold > 0:
		effects.append("Cost: " + str(cost_gold) + " gold")
	if time_cost_hours > 0:
		effects.append("Takes " + str(time_cost_hours) + " hours")
	
	if not effects.is_empty():
		desc += "\n" + " | ".join(effects)
	
	# Add availability info
	if not can_execute(player_data, node):
		desc += "\n[Unavailable]"
	
	return desc

# Static factory methods for common actions
static func create_rest_action() -> NodeAction:
	var action = NodeAction.new("rest", "Rest and Recover")
	action.heal_amount = 15
	action.sanity_change = 10
	action.time_cost_hours = 4
	action.properties = {
		"description": "Take time to rest and recover your strength.",
		"safety_required": true
	}
	return action

static func create_shop_action() -> NodeAction:
	var action = NodeAction.new("shop", "Visit Shop")
	action.properties = {
		"description": "Browse and purchase items from the local merchant.",
		"shop_tier": 1
	}
	return action

static func create_explore_action() -> NodeAction:
	var action = NodeAction.new("explore", "Explore Location")
	action.time_cost_hours = 2
	action.properties = {
		"description": "Thoroughly explore this location for hidden secrets.",
		"danger_level": 1,
		"discovery_chance": 0.3
	}
	return action

static func create_mine_action() -> NodeAction:
	var action = NodeAction.new("mine", "Mine for Gold")
	action.time_cost_hours = 6
	action.sanity_change = -5
	action.properties = {
		"description": "Dig for precious gold, but beware of the dangers below.",
		"gold_min": 10,
		"gold_max": 30,
		"danger_level": 2,
		"accident_chance": 0.15
	}
	return action

static func create_trade_action() -> NodeAction:
	var action = NodeAction.new("trade", "Trade with Locals")
	action.time_cost_hours = 1
	action.properties = {
		"description": "Engage in trade with the local population.",
		"reputation_gain": 1
	}
	return action

static func create_investigate_action() -> NodeAction:
	var action = NodeAction.new("investigate", "Investigate Mystery")
	action.time_cost_hours = 3
	action.sanity_change = -10
	action.one_time_only = true
	action.properties = {
		"description": "Delve into the strange occurrences at this location.",
		"mystery_level": 1,
		"reward_type": "knowledge"
	}
	return action