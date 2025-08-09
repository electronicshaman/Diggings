extends Control

@onready var back_button = $MainContainer/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	SceneManager.load_scene_by_name("main_menu")