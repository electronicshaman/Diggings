extends Node
## Registry for handler types and instances.
## Provides factory methods to create handlers by type and lookup handlers by ID.
## Should be set up as an autoload in project.godot.

var _by_id: Dictionary = {}
var _class_by_type: Dictionary = {
	"health": "res://scripts/handlers/types/health_handler.gd",
	"damage": "res://scripts/handlers/types/damage_handler.gd",
	"stat": "res://scripts/handlers/types/stat_handler.gd",
	"sanity": "res://scripts/handlers/types/sanity_handler.gd",
	"resource": "res://scripts/handlers/types/resource_handler.gd",
	"defense": "res://scripts/handlers/types/defense_handler.gd",
	"card": "res://scripts/handlers/types/card_manipulation_handler.gd",
	"karma": "res://scripts/handlers/types/karma_handler.gd",
	"status": "res://scripts/handlers/types/status_handler.gd",
}

## Registers a handler instance by its effect_id for later lookup.
func register_effect(effect: Resource) -> void:
	if effect and effect.effect_id != "":
		_by_id[effect.effect_id] = effect

## Returns a registered handler by its effect_id, or null if not found.
func get_by_id(id: String) -> Resource:
	return _by_id.get(id, null)

## Creates a new handler instance of the specified type (e.g., "damage", "health").
func new_by_type(type_key: String) -> Resource:
	var path = _class_by_type.get(type_key, null)
	if path == null:
		return null
	var script = load(path)
	if script == null:
		return null
	return script.new()
