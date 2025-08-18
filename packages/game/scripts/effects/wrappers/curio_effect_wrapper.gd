extends Resource
class_name CurioEffectWrapper

@export var base_effect: Resource # GameEffect
@export var trigger_event: String = "passive"
@export var stacks_with_duplicates: bool = false
@export var chance_to_trigger: float = 1.0
@export var max_stacks: int = 0
