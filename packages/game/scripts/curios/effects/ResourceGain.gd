extends CurioEffect
class_name ResourceGain

const EFFECT_NAME := "Resource Gain"

@export var resource_type: String = "gold"  # gold, energy, sanity, health, cards
@export var amount: int = 1
@export var random_range: bool = false  # If true, amount is max and we roll 1-amount
@export var condition: String = ""  # Optional condition like "if_perfect_turn"

func _init() -> void:
	pass

func apply_effect(game_state: Node, _curio_data: Resource, context: Dictionary) -> void:
	# Check condition if specified
	if not _check_condition(game_state, context):
		return
	
	# Calculate actual amount
	var actual_amount = amount
	# Honor stacks when managed by CurioManager
	if _curio_data and game_state and game_state.has_method("get_curio_stack_count"):
		var curio_name: String = _curio_data.curio_name if _curio_data.has("curio_name") else ""
		if curio_name != "":
			var stacks: int = int(game_state.get_curio_stack_count(curio_name))
			if stacks > 1:
				actual_amount *= stacks
	if random_range:
		actual_amount = randi_range(1, amount)
	
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
		"if_first_turn":
			return context.get("turn_number", 0) == 1
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

func _draw_cards(game_state: Node, value: int) -> void:
	# This would need to interact with the duel manager
	if game_state.has_node("/root/DuelManager"):
		var dm = game_state.get_node("/root/DuelManager")
		if dm.has_method("draw_cards"):
			dm.draw_cards(value)

func _get_player_data(game_state: Node):
	# If the caller provides a direct accessor (e.g., DuelManager), use it
	if game_state.has_method("get_player_data"):
		return game_state.get_player_data()
	# Try accessing a DuelManager singleton to retrieve player data during combat
	if game_state.has_node("/root/DuelManager"):
		var dm = game_state.get_node("/root/DuelManager")
		if dm and dm.has_method("get_player_data"):
			return dm.get_player_data()
	# Fallback: check if GameManager stores a player reference (legacy)
	if game_state.has_node("/root/GameManager"):
		var gm = game_state.get_node("/root/GameManager")
		if gm.game_data.has("player"):
			return gm.game_data["player"]
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
