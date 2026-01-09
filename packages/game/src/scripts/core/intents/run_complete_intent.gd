class_name RunCompleteIntent
extends SceneIntent

## Intent for showing the run completion screen.
## Contains summary data about the completed run.

## Was the run a victory?
var victory: bool = false

## Total time elapsed in seconds (optional)
var run_time: float = 0.0

## Total battles won (optional)
var battles_won: int = 0

func _init(p_victory: bool = true, p_return_scene: String = "quick_duel_setup") -> void:
	super (p_return_scene)
	victory = p_victory

func get_intent_type() -> String:
	return "RunCompleteIntent"
