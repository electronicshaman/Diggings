extends Control

@onready var main_menu_button = $MainContainer/MainMenuButton

func _ready():
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed():
	SceneManager.load_scene_by_name("main_menu")