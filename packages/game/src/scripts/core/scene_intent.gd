class_name SceneIntent
extends RefCounted

## Base class for all scene transition intents.
## Provides typed, explicit parameters for scene transitions instead of
## arbitrary dictionary keys in GameManager.game_data.

## Where to return when the scene completes (fallback if no callback)
var return_scene: String = ""

## Optional callback when scene completes successfully
var on_complete: Callable = Callable()

## Optional callback when scene is cancelled/fails
var on_cancel: Callable = Callable()

func _init(p_return_scene: String = "") -> void:
	return_scene = p_return_scene

## Override in subclasses to provide debugging info
func get_intent_type() -> String:
	return "SceneIntent"

## Check if this intent has a completion callback
func has_complete_callback() -> bool:
	return on_complete.is_valid()

## Check if this intent has a cancel callback  
func has_cancel_callback() -> bool:
	return on_cancel.is_valid()

## Call the completion callback if set
func complete(result: Variant = null) -> void:
	if has_complete_callback():
		if on_complete.get_argument_count() > 0:
			on_complete.call(result)
		else:
			on_complete.call()

## Call the cancel callback if set
func cancel(reason: String = "") -> void:
	if has_cancel_callback():
		if on_cancel.get_argument_count() > 0:
			on_cancel.call(reason)
		else:
			on_cancel.call()
