extends "res://scripts/effects/core/game_effect.gd"
class_name CombatTriggerEffect

@export var enemy_path: String = ""
@export var combat_context: String = "encounter"
@export var combat_modifiers: Dictionary = {}

var EffectResultResource := preload("res://scripts/effects/core/effect_result.gd")

func apply_effect(context):
	var result = EffectResultResource.new()

	if enemy_path.is_empty():
		result.success = false
		result.prevented_by = "no_enemy_path"
		return result

	var enemy_resource = load(enemy_path)
	if not enemy_resource:
		result.success = false
		result.prevented_by = "invalid_enemy_path"
		push_error("CombatTriggerEffect: Could not load enemy at path: %s" % enemy_path)
		return result

	var game_manager = context.game_manager if context else null
	if not game_manager:
		game_manager = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if not game_manager:
		game_manager = context.get_node_or_null("/root/GameManager") if context and context.has_method("get_node_or_null") else null

	if not game_manager:
		# Try autoload directly
		var tree = Engine.get_main_loop()
		if tree and tree.root:
			game_manager = tree.root.get_node_or_null("GameManager")

	if not game_manager:
		result.success = false
		result.prevented_by = "no_game_manager"
		push_error("CombatTriggerEffect: GameManager not found")
		return result

	# Prepare the duel
	var prepared = game_manager.prepare_duel(enemy_resource, combat_context, combat_modifiers)

	if prepared:
		result.success = true
		result.values_applied["combat_triggered"] = true
		result.values_applied["enemy_name"] = enemy_resource.enemy_name if "enemy_name" in enemy_resource else "Unknown"
		result.ui_feedback = {"message": "Combat begins!"}
	else:
		result.success = false
		result.prevented_by = "duel_preparation_failed"

	return result


func get_preview_text(_context: Resource) -> String:
	if enemy_path.is_empty():
		return "Triggers combat"

	var enemy_resource = load(enemy_path)
	if enemy_resource and "enemy_name" in enemy_resource:
		return "Fight: %s" % enemy_resource.enemy_name

	return "Triggers combat encounter"
