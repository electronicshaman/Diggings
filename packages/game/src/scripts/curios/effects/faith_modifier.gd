extends CurioEffect
class_name FaithModifier

const EFFECT_NAME := "Faith Modifier"

@export var faith_gain_bonus: int = 0 # Increase all Faith gains by this amount
@export var faith_max_bonus: int = 0 # Increase Faith cap
@export var faith_minimum: int = 0 # Faith cannot go below this value
@export var faith_conversion_rate: float = 1.0 # Multiplier for Faith effects
@export var trigger_on_damage: bool = false # Gain Faith when taking damage
@export var damage_to_faith_percent: float = 0.2 # Percentage of damage converted to Faith
@export var resource_type: String = "faith" # Default to faith
@export var amount: int = 1 # Amount of Faith to gain when triggered

func _init() -> void:
	pass

func apply_effect(game_state: Node, _curio_data: Resource, context: Dictionary) -> void:
	var player = _get_player_data(game_state)
	if not player:
		return

	# Calculate actual amount (honor stacks)
	var actual_amount = amount
	if _curio_data and game_state and game_state.has_method("get_curio_stack_count"):
		var curio_name: String = (_curio_data as CurioData).curio_name if (_curio_data is CurioData) else ""
		if curio_name != "":
			var stacks: int = int(game_state.get_curio_stack_count(curio_name))
			if stacks > 1:
				actual_amount *= stacks

	# Handle different trigger events
	match trigger_event:
		"combat_start":
			# Gain Faith at combat start
			_add_faith(player, actual_amount)

		"damage_taken":
			# Convert damage to Faith
			if trigger_on_damage:
				var damage_amount = context.get("damage_amount", 0)
				var faith_gain = int(ceil(damage_amount * damage_to_faith_percent))
				if faith_gain > 0:
					_add_faith(player, faith_gain)

		"faith_gained":
			# Triggered when Faith is gained (bonus effect)
			if faith_gain_bonus > 0:
				_add_faith(player, faith_gain_bonus)

		"passive":
			# Passive effects applied when curio is acquired
			if faith_max_bonus > 0:
				var current_max = player.get_resource_max("Faith")
				player.custom_resource_max["Faith"] = current_max + faith_max_bonus

func _add_faith(player_data, value: int) -> void:
	"""Add Faith to player using the generic resource system"""
	if player_data and player_data.has_method("gain_resource"):
		player_data.gain_resource("Faith", value)
		var current = player_data.get_resource("Faith")
		var max_val = player_data.get_resource_max("Faith")
		if max_val > 0:
			GLog.debug("FaithModifier: Added %d Faith (current: %d/%d)" % [value, current, max_val])
		else:
			GLog.debug("FaithModifier: Added %d Faith (current: %d)" % [value, current])

func _get_player_data(game_state: Node):
	"""Get player data from game state"""
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
	"""Find DuelManager in scene tree"""
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
	var desc_parts: Array[String] = []

	if amount > 0 and trigger_event == "combat_start":
		desc_parts.append("Gain %d Faith at combat start" % amount)

	if faith_max_bonus > 0:
		desc_parts.append("+%d max Faith" % faith_max_bonus)

	if faith_minimum > 0:
		desc_parts.append("Faith cannot go below %d" % faith_minimum)

	if trigger_on_damage and damage_to_faith_percent > 0:
		desc_parts.append("Gain Faith equal to %d%% of damage taken" % int(damage_to_faith_percent * 100))

	if faith_gain_bonus > 0:
		desc_parts.append("+%d Faith whenever you gain Faith" % faith_gain_bonus)

	var desc = ". ".join(desc_parts) if desc_parts.size() > 0 else "Faith modifier"

	if chance_to_trigger < 1.0:
		desc = "(%d%% chance) %s" % [int(chance_to_trigger * 100), desc]

	return desc

func get_effect_name() -> String:
	return EFFECT_NAME
