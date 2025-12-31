extends Control
class_name DeckManagementController

const DEBUG_ENABLED = true

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	GLog.debug("Deck Management placeholder loaded")

func _on_back_pressed() -> void:
	SceneManager.load_scene("res://scenes/ui/main_menu.tscn")
