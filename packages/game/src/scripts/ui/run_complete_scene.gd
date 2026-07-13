extends Control

func _ready() -> void:
	var intent := SceneManager.get_pending_intent() as RunCompleteIntent
	if not intent:
		GLog.error("Run Complete opened without RunCompleteIntent")
		SceneManager.load_scene_by_name("main_menu")
		return
	$CanvasLayer/CenterContainer/VBoxContainer/ClassLabel.text = "Class: %s" % intent.character_class
	$CanvasLayer/CenterContainer/VBoxContainer/SeedLabel.text = "Seed: %d" % intent.seed
	$CanvasLayer/CenterContainer/VBoxContainer/FightsLabel.text = "Fights won: %d/3" % intent.battles_won
	$CanvasLayer/CenterContainer/VBoxContainer/VitalsLabel.text = "Health: %d | Sanity: %d" % [intent.final_health, intent.final_sanity]
	$CanvasLayer/CenterContainer/VBoxContainer/CardsLabel.text = "Cards added: %s" % (", ".join(intent.cards_added) if not intent.cards_added.is_empty() else "None")
	$CanvasLayer/CenterContainer/VBoxContainer/ReturnButton.pressed.connect(_return_to_main_menu)

func _return_to_main_menu() -> void:
	GameManager.reset_curated_run()
	SceneManager.load_scene_by_name("main_menu")
