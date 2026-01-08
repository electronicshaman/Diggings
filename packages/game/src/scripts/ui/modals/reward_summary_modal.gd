extends Control

const DEBUG_ENABLED: bool = true

signal modal_completed(result: Variant)

@onready var background_panel: Panel = $BackgroundPanel
@onready var modal_container: VBoxContainer = $BackgroundPanel/ModalContainer
@onready var title_label: Label = $BackgroundPanel/ModalContainer/TitleLabel
@onready var rewards_container: VBoxContainer = $BackgroundPanel/ModalContainer/RewardsContainer
@onready var continue_button: Button = $BackgroundPanel/ModalContainer/ContinueButton

var reward_data: Dictionary = {}

func _ready() -> void:
	GLog.debug("Reward summary modal ready")
	
	# Set up modal appearance
	_setup_modal_appearance()
	
	# Connect continue button
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Make modal focusable for keyboard input
	set_process_input(true)

func _setup_modal_appearance() -> void:
	"""Set up the visual appearance of the modal"""
	# Center the modal on screen
	modal_container.custom_minimum_size = Vector2(500, 300)
	
	# Ensure modal appears above everything
	z_index = 1000

func initialize(data: Dictionary) -> void:
	"""Initialize the modal with reward data"""
	GLog.debug("Initializing reward summary modal with data: %s" % str(data.keys()))
	
	reward_data = data.duplicate()
	_display_rewards()

func _display_rewards() -> void:
	"""Display the reward information"""
	title_label.text = "Encounter Complete!"
	
	# Clear existing reward displays
	for child in rewards_container.get_children():
		if child.name.begins_with("Reward"):
			child.queue_free()
	
	var has_rewards = false
	
	# Display gold rewards
	if reward_data.has("gold") and reward_data.gold != 0:
		_add_reward_display("Gold", str(reward_data.gold), Color.YELLOW)
		has_rewards = true
	
	# Display karma changes
	if reward_data.has("karma_changes") and reward_data.karma_changes is Dictionary:
		var karma_changes = reward_data.karma_changes as Dictionary
		for category in karma_changes:
			var change = karma_changes[category]
			if change != 0:
				var sign_str = "+" if change > 0 else ""
				var color = Color.GREEN if change > 0 else Color.RED
				_add_reward_display("Karma (%s)" % category.capitalize(), "%s%d" % [sign_str, change], color)
				has_rewards = true
	
	# Display overall karma change
	if reward_data.has("total_karma") and reward_data.total_karma != 0:
		var sign_str = "+" if reward_data.total_karma > 0 else ""
		var color = Color.GREEN if reward_data.total_karma > 0 else Color.RED
		_add_reward_display("Total Karma", "%s%d" % [sign_str, reward_data.total_karma], color)
		has_rewards = true
	
	# Display corruption changes
	if reward_data.has("corruption") and reward_data.corruption != 0:
		var sign_str = "+" if reward_data.corruption > 0 else ""
		var color = Color.RED if reward_data.corruption > 0 else Color.GREEN
		_add_reward_display("Corruption", "%s%d" % [sign_str, reward_data.corruption], color)
		has_rewards = true
	
	# Display card rewards
	if reward_data.has("cards") and reward_data.cards is Array:
		var cards = reward_data.cards as Array
		for card in cards:
			if card is String:
				_add_reward_display("Card Gained", card, Color.CYAN)
			elif card is Resource and card.has_method("get_card_name"):
				_add_reward_display("Card Gained", card.get_card_name(), Color.CYAN)
			has_rewards = true
	
	# Display curio rewards
	if reward_data.has("curios") and reward_data.curios is Array:
		var curios = reward_data.curios as Array
		for curio in curios:
			if curio is String:
				_add_reward_display("Curio Found", curio, Color.PURPLE)
			elif curio is Resource and curio.has_method("get_curio_name"):
				_add_reward_display("Curio Found", curio.get_curio_name(), Color.PURPLE)
			has_rewards = true
	
	# Display custom rewards
	if reward_data.has("custom_rewards") and reward_data.custom_rewards is Array:
		var custom_rewards = reward_data.custom_rewards as Array
		for reward in custom_rewards:
			if reward is Dictionary:
				var reward_name = reward.get("name", "Unknown Reward")
				var reward_description = reward.get("description", "")
				var reward_color = Color.WHITE
				if reward.has("color"):
					reward_color = reward.color
				_add_reward_display(reward_name, reward_description, reward_color)
				has_rewards = true
	
	# If no rewards, show a message
	if not has_rewards:
		var no_rewards_label = Label.new()
		no_rewards_label.name = "RewardNoRewards"
		no_rewards_label.text = "No material rewards gained."
		no_rewards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_rewards_label.add_theme_color_override("font_color", Color.GRAY)
		rewards_container.add_child(no_rewards_label)
	
	GLog.debug("Displayed %d reward types" % rewards_container.get_child_count())

func _add_reward_display(reward_name: String, reward_value: String, color: Color = Color.WHITE) -> void:
	"""Add a reward display to the container"""
	var reward_container = HBoxContainer.new()
	reward_container.name = "Reward%s" % reward_name.replace(" ", "")
	
	var name_label = Label.new()
	name_label.text = reward_name + ":"
	name_label.custom_minimum_size.x = 150
	name_label.add_theme_color_override("font_color", Color.WHITE)
	
	var value_label = Label.new()
	value_label.text = reward_value
	value_label.add_theme_color_override("font_color", color)
	
	reward_container.add_child(name_label)
	reward_container.add_child(value_label)
	rewards_container.add_child(reward_container)

func _input(event: InputEvent) -> void:
	"""Handle keyboard input"""
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()

func _on_continue_pressed() -> void:
	"""Handle continue button - close modal"""
	GLog.debug("Player acknowledged rewards")
	modal_completed.emit("continue")

func _notification(what: int) -> void:
	"""Handle notifications"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Treat window close as continue
		_on_continue_pressed()

# Static helper method for creating reward data
static func create_reward_data(
	gold: int = 0,
	karma_changes: Dictionary = {},
	total_karma: int = 0,
	corruption: int = 0,
	cards: Array = [],
	curios: Array = [],
	custom_rewards: Array = []
) -> Dictionary:
	"""Helper method to create properly formatted reward data"""
	return {
		"gold": gold,
		"karma_changes": karma_changes,
		"total_karma": total_karma,
		"corruption": corruption,
		"cards": cards,
		"curios": curios,
		"custom_rewards": custom_rewards
	}