extends Node
class_name EffectRegistry

var _by_id: Dictionary = {}
var _class_by_type: Dictionary = {
	"health": "res://scripts/effects/types/health_effect.gd",
	"damage": "res://scripts/effects/types/damage_effect.gd",
	"stat": "res://scripts/effects/types/stat_effect.gd",
	"sanity": "res://scripts/effects/types/sanity_effect.gd",
	"resource": "res://scripts/effects/types/resource_effect.gd",
	"defense": "res://scripts/effects/types/defense_effect.gd",
	"card": "res://scripts/effects/types/card_manipulation_effect.gd",
	"karma": "res://scripts/effects/types/karma_effect.gd",
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
