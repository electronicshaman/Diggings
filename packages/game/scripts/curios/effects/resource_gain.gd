extends CurioEffect
class_name ResourceGain

const EFFECT_NAME := "Resource Gain"

@export var resource_type: String = "gold"  # gold, energy, sanity, health, cards, corruption
@export var amount: int = 1
@export var random_range: bool = false  # If true, amount is max and we roll 1-amount
@export var condition: String = ""  # Optional condition like "if_perfect_turn", "if_power_card", "if_high_cost"

func _init() -> void:
	pass

func apply_effect(game_state: Node, _curio_data: Resource, context: Dictionary) -> void:
	# Check condition if specified
	if not _check_condition(game_state, context):
		return
	
	# Calculate actual amount (random roll first if enabled)
	var actual_amount = (randi_range(1, amount) if random_range else amount)
	# Honor stacks when managed by CurioManager (multiply rolled/base amount)
	if _curio_data and game_state and game_state.has_method("get_curio_stack_count"):
		var curio_name: String = (_curio_data as CurioData).curio_name if (_curio_data is CurioData) else ""
		if curio_name != "":
			var stacks: int = int(game_state.get_curio_stack_count(curio_name))
			if stacks > 1:
				actual_amount *= stacks
	
	# Apply the resource gain
	match resource_type:
		"gold":
			_add_gold(game_state, actual_amount)
		"energy":
			_add_energy(game_state, actual_amount)
		"sanity":
			_add_sanity(game_state, actual_amount)
		"health":
			_add_health(game_state, actual_amount)
		"cards":
			_draw_cards(game_state, actual_amount)
		"block", "defense":
			_add_defense(game_state, actual_amount)
		"corruption":
			_add_corruption(game_state, actual_amount)
		_:
			GLog.warn("Unknown resource type '%s' in ResourceGain" % resource_type)

func _check_condition(game_state: Node, context: Dictionary) -> bool:
	if condition.is_empty():
		return true
	
	match condition:
		"if_perfect_turn":
			var player = _get_player_data(game_state)
			return player and player.damage_taken_this_turn == 0
		"if_low_health":
			var player = _get_player_data(game_state)
			return player and player.get_health_percentage() < 0.3
		"if_low_sanity":
			var player = _get_player_data(game_state)
			return player and player.get_sanity_percentage() < 0.25
		"if_first_turn":
			return context.get("turn_number", 0) == 1
		"if_power_card":
			var card_data = context.get("card_data", null)
			return card_data and card_data.mechanical_category.to_lower() == "power"
		"if_attack_card":
			var card_data = context.get("card_data", null)
			return card_data and card_data.mechanical_category.to_lower() == "attack"
		"if_high_cost":
			var card_data = context.get("card_data", null)
			return card_data and card_data.energy_cost >= 2
		_:
			return true

func _add_gold(game_state: Node, value: int) -> void:
	# Prefer modifying the in-duel player stats if available
	var player = _get_player_data(game_state)
	var applied := false
	if player and player.stats:
		player.stats.gain_gold(value)
		applied = true
	# Fallback to global run gold if player context isn't available
	if not applied and game_state.has_node("/root/GameManager"):
		var gm = game_state.get_node("/root/GameManager")
		gm.game_data["gold"] = gm.game_data.get("gold", 0) + value
	# Emit UI event if possible
	if game_state.has_node("/root/EventBus"):
		game_state.get_node("/root/EventBus").gold_changed.emit(value)

func _add_energy(game_state: Node, value: int) -> void:
	var player = _get_player_data(game_state)
	if player:
		player.restore_energy(value)

func _add_sanity(game_state: Node, value: int) -> void:
	var player = _get_player_data(game_state)
	if player:
		player.restore_sanity(value)

func _add_health(game_state: Node, value: int) -> void:
	var player = _get_player_data(game_state)
	if player:
		player.heal(value)

func _add_defense(game_state: Node, value: int) -> void:
	var player = _get_player_data(game_state)
	if player:
		player.gain_defense(value)

func _add_corruption(game_state: Node, value: int) -> void:
	var player = _get_player_data(game_state)
	if player and player.stats:
		player.stats.gain_corruption(value)
	if game_state.has_node("/root/EventBus"):
		game_state.get_node("/root/EventBus").corruption_changed.emit(value)

func _draw_cards(game_state: Node, value: int) -> void:
	# This would need to interact with the duel manager
	var dm = _find_duel_manager(game_state)
	if dm and dm.duel_state:
		dm.duel_state.draw_cards(value)

func _get_player_data(game_state: Node):
	# If the caller provides a direct accessor (e.g., DuelManager), use it
	if game_state.has_method("get_player_data"):
		return game_state.get_player_data()
	# Try to locate a DuelManager in the active scene tree
	var dm = _find_duel_manager(game_state)
	if dm and dm.has_method("get_player_data"):
		return dm.get_player_data()
	# Fallback: check if GameManager stores a player reference (legacy)
	if game_state.has_node("/root/GameManager"):
		var gm = game_state.get_node("/root/GameManager")
		if gm.game_data.has("player"):
			return gm.game_data["player"]
	return null

func _find_duel_manager(game_state: Node):
	if not game_state or not game_state.get_tree():
		return null
	var root = game_state.get_tree().get_root()
	if not root:
		return null
	# Breadth-first search for a node of type DuelManager
	var queue: Array = [root]
	while not queue.is_empty():
		var node = queue.pop_front()
		# Direct type check using class_name
		if node is DuelManager:
			return node
		for child in node.get_children():
			if child is Node:
				queue.append(child)
	return null

func get_formatted_description() -> String:
	var desc = ""
	if random_range:
		desc = "Gain 1-%d %s" % [amount, resource_type]
	else:
		desc = "Gain %d %s" % [amount, resource_type]
	
	if not condition.is_empty():
		desc += " (%s)" % condition.replace("_", " ")
	
	if chance_to_trigger < 1.0:
		desc = "(%d%% chance) %s" % [int(chance_to_trigger * 100), desc]
	
	return desc

func get_effect_name() -> String:
	return EFFECT_NAME
