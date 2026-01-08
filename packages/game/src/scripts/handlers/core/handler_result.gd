extends Resource
class_name HandlerResult
## Result object returned by handler apply_effect() methods.
## Contains the outcome of an effect execution, including values to apply,
## success/failure status, and feedback for UI display.

@export var success: bool = true ## Whether the effect was successfully applied
@export var values_applied: Dictionary = {} ## Key-value pairs of effect outcomes (e.g., {"damage": 10, "heal": 5})
@export var prevented_by: String = "" ## Reason the effect was blocked (empty if successful)
@export var critical: bool = false ## Whether the effect resulted in a critical hit
@export var overkill: int = 0 ## Amount of excess damage dealt beyond target's health
@export var triggers: Array[String] = [] ## Additional effects to trigger as a result
@export var ui_feedback: Dictionary = {} ## Data for UI display (e.g., {"message": "Critical Hit!"})
@export var logs: Array[String] = [] ## Diagnostic log messages for debugging
