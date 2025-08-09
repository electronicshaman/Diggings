extends Control
class_name ClassSelectionController

@onready var bushranger_select_button = $MainContainer/ClassContainer/BushrangerCard/CardContent/SelectButton
@onready var back_button = $MainContainer/BackButton

func _ready():
	setup_button_connections()

func setup_button_connections():
	bushranger_select_button.pressed.connect(_on_bushranger_selected)
	back_button.pressed.connect(_on_back_pressed)

func _on_bushranger_selected():
	GLog.info("Bushranger class selected")
	# Start new run with Bushranger
	GameManager.start_new_run("Bushranger")
	# Will be handled by GameManager transition to appropriate scene

func _on_back_pressed():
	GLog.info("Returning to main menu")
	SceneManager.load_scene_by_name("main_menu")