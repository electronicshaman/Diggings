extends Control

const DEBUG_ENABLED: bool = true

@onready var title_label: Label = $CanvasLayer/CenterContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CanvasLayer/CenterContainer/VBoxContainer/MessageLabel
@onready var return_button: Button = $CanvasLayer/CenterContainer/VBoxContainer/ReturnButton

var return_scene_path: String = "res://scenes/game/quick_duel_setup.tscn"

func _ready() -> void:
    # Basic setup if run directly
    if not GameManager.has_active_intent():
        _setup_default_view()
    else:
        _handle_intent(GameManager.get_active_intent())

    if return_button:
        return_button.pressed.connect(_on_return_pressed)

func _setup_default_view() -> void:
    if title_label: title_label.text = "Run Completed"
    if message_label: message_label.text = "Congratulations!"

func _handle_intent(intent: SceneIntent) -> void:
    if not intent is RunCompleteIntent:
        GLog.warn("RunCompleteScene opened with invalid intent type", "run_complete")
        return
        
    var run_intent = intent as RunCompleteIntent
    return_scene_path = run_intent.return_scene
    
    if title_label:
        title_label.text = "Victory!" if run_intent.victory else "Defeat"
    
    if message_label:
        message_label.text = "You have completed the run."

func _on_return_pressed() -> void:
    if SceneManager:
        SceneManager.load_scene(return_scene_path)
    else:
        # Fallback if SceneManager not available
        get_tree().change_scene_to_file(return_scene_path)
