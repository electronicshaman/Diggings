extends CurioEffect
class_name StatModifier

const EFFECT_NAME := "Stat Modifier"

@export var stat_name: String = "max_health"  # max_health, max_energy, max_sanity, defense, etc.
@export var modifier_value: float = 0  # Amount to modify stat by
@export var modifier_type: String = "flat"  # flat or percentage
@export var apply_immediately: bool = false  # Apply to current value as well as max

func _init() -> void:
	trigger_event = "passive"

func apply_effect(game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
	# Get player data
	var player_data = _get_player_data(game_state)
	if not player_data:
		return
	
	var actual_value = _calculate_modifier_value(player_data)
	
	# Apply the stat modification
	match stat_name:
		"max_health":
			player_data.modify_max_health(int(actual_value))
			if apply_immediately:
				player_data.heal(int(actual_value))
		"max_energy":
			player_data.modify_max_energy(int(actual_value))
			if apply_immediately:
				player_data.restore_energy(int(actual_value))
		"max_sanity":
			player_data.modify_max_sanity(int(actual_value))
			if apply_immediately:
				player_data.restore_sanity(int(actual_value))
		"defense":
			player_data.gain_defense(int(actual_value))
		"gold":
			if game_state.has_method("add_gold"):
				game_state.add_gold(int(actual_value))
		_:
			GLog.warn("Unknown stat '%s' in StatModifier" % stat_name)

func get_stat_modifier(requested_stat: String) -> float:
	"""Return the modifier value if this effect modifies the requested stat"""
	if stat_name == requested_stat:
		return modifier_value if modifier_type == "flat" else 0.0
	return 0.0

func _calculate_modifier_value(player_data) -> float:
	if modifier_type == "percentage":
		var base_value = 0
		match stat_name:
			"max_health":
				base_value = player_data.max_health
			"max_energy":
				base_value = player_data.max_energy
			"max_sanity":
				base_value = player_data.max_sanity
			_:
				base_value = 0
		return base_value * (modifier_value / 100.0)
	else:
		return modifier_value

func _format_modifier() -> String:
	if modifier_type == "percentage":
		return "%+d%%" % int(modifier_value)
	else:
		return "%+d" % int(modifier_value)

func _get_player_data(game_state: Node):
	# Try to get player data from various sources
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
	var stat_display = stat_name.replace("_", " ").capitalize()
	return "Modifies %s by %s" % [stat_display, _format_modifier()]

func get_effect_name() -> String:
	return EFFECT_NAME
