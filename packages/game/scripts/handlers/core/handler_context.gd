extends Resource
class_name HandlerContext
## Context object passed to handler apply_effect() methods.
## Contains all state needed for effect resolution: source info, game state references,
## targeting information, and curio modifications.

@export_group("Source")
@export var source_type: String = "" ## "card", "encounter", "curio", "status", etc.
@export var source_object: Resource = null ## The card/encounter/curio that triggered this

@export_group("State References")
## Node references (not exported because Resources persist)
var game_manager: Node = null
var duel_manager: Node = null ## May be null outside combat
@export var player_data: Resource = null
@export var enemy_data: Resource = null ## May be null outside combat

@export_group("Trigger")
@export var trigger_event: String = "" ## "card_played", "turn_start", "enemy_defeated", etc.
@export var trigger_data: Dictionary = {} ## Event-specific data

@export_group("Curio Modifiers")
@export var curio_modifications: Dictionary = {} ## {damage: int, defense: int, cost: int, draw: int}

@export_group("Targeting")
@export var primary_target: Resource = null
@export var secondary_targets: Array[Resource] = []

func _init() -> void:
	pass

## Returns the curio modifications dictionary for this context.
func get_curio_modifications() -> Dictionary:
	return curio_modifications
