class_name GameOverIntent
extends SceneIntent

## Intent for showing the game over screen.
## Carries the reason the curated run ended in defeat.

var reason: RunSession.EndReason = RunSession.EndReason.HEALTH

func _init(p_reason: RunSession.EndReason = RunSession.EndReason.HEALTH) -> void:
	super("main_menu")
	reason = p_reason

func get_intent_type() -> String:
	return "GameOverIntent"
