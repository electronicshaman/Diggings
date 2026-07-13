extends Control
class_name BetweenFightChoiceController

@onready var run_status: Label = $Margin/VBox/RunStatus
@onready var card_offers: HBoxContainer = $Margin/VBox/CardOffers
@onready var recover_button: Button = $Margin/VBox/RecoverButton

var choice_submitted := false


func _ready() -> void:
	if not GameManager.has_pending_run_reward():
		GLog.error("Between-fight choice opened without a pending reward")
		SceneManager.load_scene_by_name("main_menu")
		return
	var offers := GameManager.get_pending_run_rewards()
	run_status.text = GameManager.get_run_progress_text()
	for card in offers:
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 180)
		button.text = "%s\n%s" % [card.card_name, card.description]
		button.pressed.connect(_on_card_selected.bind(card))
		card_offers.add_child(button)
	recover_button.pressed.connect(_on_recover_selected)


func _on_card_selected(card: CardData) -> void:
	if choice_submitted:
		return
	_begin_submission()
	if not GameManager.choose_run_card(card):
		_restore_choices_if_reward_is_pending()


func _on_recover_selected() -> void:
	if choice_submitted:
		return
	_begin_submission()
	if not GameManager.choose_run_recovery():
		_restore_choices_if_reward_is_pending()


func _begin_submission() -> void:
	choice_submitted = true
	_set_controls_disabled(true)


func _restore_choices_if_reward_is_pending() -> void:
	if not GameManager.has_pending_run_reward():
		return
	choice_submitted = false
	_set_controls_disabled(false)


func _set_controls_disabled(disabled: bool) -> void:
	recover_button.disabled = disabled
	for child in card_offers.get_children():
		if child is Button:
			child.disabled = disabled
