extends CurioEffect
class_name EnemyModifier

const EFFECT_NAME := "Enemy Modifier"

@export var stat_name: String = "strength" # strength, defense, health
@export var modifier_value: int = 0
@export var apply_to_all: bool = true

func _init() -> void:
	trigger_event = "combat_start"

func apply_effect(game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
	var dm = _find_duel_manager(game_state)
	if dm and dm.duel_state and dm.duel_state.enemy_data:
		_apply_to_enemy(dm.duel_state.enemy_data)

func _apply_to_enemy(enemy: Object) -> void:
	match stat_name:
		"strength":
			if enemy.has_method("modify_strength"):
				enemy.modify_strength(modifier_value)
		"defense":
			if enemy.has_method("gain_defense"):
				enemy.gain_defense(modifier_value)
		"health":
			if enemy.has_method("modify_max_health"):
				enemy.modify_max_health(modifier_value)

func _find_duel_manager(game_state: Node) -> DuelManager:
	if not game_state or not game_state.get_tree():
		return null
	var root := game_state.get_tree().get_root()
	if not root:
		return null
	# Breadth-first search for a node of type DuelManager
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var node: Node = queue.pop_front() as Node
		# Direct type check using class_name
		if node is DuelManager:
			return node
		for child in node.get_children():
			if child is Node:
				queue.append(child)
	return null

func get_effect_name() -> String:
	return EFFECT_NAME
