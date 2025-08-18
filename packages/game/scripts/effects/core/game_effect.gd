extends Resource
class_name GameEffect

@export var effect_id: String = ""
@export var effect_type: String = ""
@export var target_type: String = "player" # "player", "enemy", "all", "random"
@export var timing: String = "immediate" # "immediate", "delayed", "persistent"
@export var description: String = ""
@export var delayed: bool = false
@export var delay_turns: int = 0

# Execution and ordering
@export var priority: int = 0
@export var phase: String = "default" # e.g., "on_play", "turn_start", "turn_end"

# Stacking semantics
@export var stack_key: String = ""
@export var stack_behavior: String = "independent" # "independent" | "stack_values" | "refresh_duration" | "cap_value"
@export var stack_cap: int = 0 # 0 = no cap

# Versioning for save/migration
@export var version: int = 1
@export var tags: Array[String] = []

func apply_effect(_context: Resource) -> Resource:
	# Should return EffectResult
	return null

func can_apply(_context: Resource) -> bool:
	return true

func get_preview_text(_context: Resource) -> String:
	return description

func on_added(_context: Resource) -> void:
	pass

func on_removed(_context: Resource) -> void:
	pass
