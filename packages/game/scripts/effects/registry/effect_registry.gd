extends Node

var _by_id: Dictionary = {}
var _class_by_type: Dictionary = {
	"health": "res://scripts/effects/types/health_handler.gd",
	"damage": "res://scripts/effects/types/damage_handler.gd",
	"stat": "res://scripts/effects/types/stat_handler.gd",
	"sanity": "res://scripts/effects/types/sanity_handler.gd",
	"resource": "res://scripts/effects/types/resource_handler.gd",
	"defense": "res://scripts/effects/types/defense_handler.gd",
	"card": "res://scripts/effects/types/card_manipulation_handler.gd",
	"karma": "res://scripts/effects/types/karma_handler.gd",
	"status": "res://scripts/effects/types/status_handler.gd",
}

func register_effect(effect) -> void:
	if effect and effect.effect_id != "":
		_by_id[effect.effect_id] = effect

func get_by_id(id: String):
	return _by_id.get(id, null)

func new_by_type(type_key: String):
	var path = _class_by_type.get(type_key, null)
	if path == null:
		return null
	var script = load(path)
	if script == null:
		return null
	return script.new()
