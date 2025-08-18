extends Resource
class_name EffectResult

@export var success: bool = true
@export var values_applied: Dictionary = {}
@export var prevented_by: String = ""
@export var critical: bool = false
@export var overkill: int = 0
@export var triggers: Array[String] = []
@export var ui_feedback: Dictionary = {}
@export var logs: Array[String] = []
