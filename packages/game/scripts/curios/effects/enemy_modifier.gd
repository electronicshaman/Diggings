extends CurioEffect
class_name EnemyModifier

const EFFECT_NAME := "Enemy Modifier"

@export var stat_name: String = "strength"  # strength, defense, health
@export var modifier_value: int = 0
@export var apply_to_all: bool = true

func _init() -> void:
	trigger_event = "combat_start"

func apply_effect(game_state: Node, _curio_data: Resource, _context: Dictionary) -> void:
	if game_state.has_node("/root/DuelManager"):
		var dm = game_state.get_node("/root/DuelManager")
		if dm.has_method("get_enemies"):
			var enemies = dm.get_enemies()
			for enemy in enemies:
				_apply_to_enemy(enemy)

func _apply_to_enemy(enemy: Node) -> void:
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

func get_effect_name() -> String:
	return EFFECT_NAME
