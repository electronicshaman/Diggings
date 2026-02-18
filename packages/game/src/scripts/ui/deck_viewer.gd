extends Control

@onready var return_button = $MainContainer/ReturnToMapButton

func _ready():
	return_button.pressed.connect(_on_return_pressed)

func _on_return_pressed():
	SceneManager.load_scene_by_name("quick_duel_setup")
