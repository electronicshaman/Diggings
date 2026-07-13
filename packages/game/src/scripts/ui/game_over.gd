extends Control

func _ready() -> void:
	var intent := SceneManager.get_pending_intent() as GameOverIntent
	if not intent:
		GLog.error("Game Over opened without GameOverIntent")
		SceneManager.load_scene_by_name("main_menu")
		return
	match intent.reason:
		RunSession.EndReason.HEALTH:
			$MainContainer/ReasonLabel.text = "Your body gave out."
		RunSession.EndReason.SANITY:
			$MainContainer/ReasonLabel.text = "Your mind broke."
		_:
			$MainContainer/ReasonLabel.text = "The run state became invalid."
	$MainContainer/MainMenuButton.pressed.connect(_return_to_main_menu)

func _return_to_main_menu() -> void:
	GameManager.reset_curated_run()
	SceneManager.load_scene_by_name("main_menu")
