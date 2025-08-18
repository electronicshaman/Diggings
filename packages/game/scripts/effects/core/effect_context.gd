extends Resource
class_name EffectContext

# Source information
@export var source_type: String = "" # "card", "encounter", "curio", "status", etc.
@export var source_object: Resource = null # The card/encounter/curio that triggered this

# State references (not exported because this is a Resource)
var game_manager: Node = null
var duel_manager: Node = null # May be null outside combat
@export var player_data: Resource = null
@export var enemy_data: Resource = null # May be null outside combat

# Trigger information
@export var trigger_event: String = "" # "card_played", "turn_start", "enemy_defeated", etc.
@export var trigger_data: Dictionary = {} # Event-specific data

# Targeting
@export var primary_target: Resource = null
@export var secondary_targets: Array[Resource] = []

# Utility/context cache to reduce allocations can be added on demand
