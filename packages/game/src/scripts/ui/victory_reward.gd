extends Control

const DEBUG_ENABLED: bool = true

# Card display
@onready var card_container: HBoxContainer = $VBoxContainer/CardContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var skip_button: Button = $VBoxContainer/ButtonContainer/SkipButton
@onready var gold_label: Label = $VBoxContainer/RewardInfo/GoldLabel

# Card scene for display
var card_scene = preload("res://scenes/cards/card.tscn")

# Available cards pool
var all_card_paths: Array[String] = []
var offered_cards: Array[CardData] = []
var selected_card: CardData = null

# Rewards
var gold_reward: int = 0

# Curio reward state
var pending_curio_reward: bool = false
var offered_curios: Array = []
var curio_phase_active: bool = false

# Test sequence preview mode
var is_test_sequence_preview: bool = false

# Where to navigate after reward selection (from intent or legacy)
var continue_to_scene: String = ""
var should_continue_sequence: bool = false

func _ready():
	GLog.info("Victory reward screen loaded")
	
	# Try to get intent from SceneManager first (new pattern)
	var intent = SceneManager.get_pending_intent() as RewardIntent
	if intent:
		_apply_intent(intent)
	else:
		# Legacy: Check for test sequence preview mode via game_data
		if GameManager:
			is_test_sequence_preview = GameManager.game_data.get("test_sequence_preview", false)
			if is_test_sequence_preview:
				GameManager.game_data["test_sequence_preview"] = false # Clear the flag
				GLog.info("Victory reward in PREVIEW mode (legacy) - deck unchanged", "victory_reward")
				if title_label:
					title_label.text = "Victory! (Preview - Deck Unchanged)"
			
			# Legacy: check for sequence continuation
			should_continue_sequence = GameManager.game_data.get("continue_test_sequence", false)
			GameManager.game_data["continue_test_sequence"] = false

	# Check if curio reward is pending (boss/elite defeated)
	if GameManager:
		pending_curio_reward = GameManager.game_data.get("pending_curio_reward", false)
		GameManager.game_data["pending_curio_reward"] = false # Clear the flag
		if pending_curio_reward:
			GLog.info("Curio reward will be offered after card selection")

	# Setup button connections
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)

	# Load all available cards
	_load_card_pool()

	# Generate and display reward cards
	_generate_reward_cards()

	# Display gold reward (if any)
	_display_gold_reward()

func _apply_intent(intent: RewardIntent) -> void:
	"""Configure scene from a RewardIntent"""
	is_test_sequence_preview = intent.is_preview_mode
	should_continue_sequence = intent.continue_sequence
	continue_to_scene = intent.return_scene
	pending_curio_reward = intent.offer_curio
	
	if intent.gold_reward > 0:
		gold_reward = intent.gold_reward
	
	if is_test_sequence_preview:
		GLog.info("Victory reward in PREVIEW mode (via intent) - deck unchanged", "victory_reward")
		if title_label:
			title_label.text = "Victory! (Preview - Deck Unchanged)"
	
	GLog.debug("Applied RewardIntent: preview=%s, continue=%s, return=%s" % [
		is_test_sequence_preview, should_continue_sequence, continue_to_scene
	], "victory_reward")

func _load_card_pool():
	"""Load all available card paths for reward selection"""
	all_card_paths = [
		"res://data/cards/attack/quick_shot.tres",
		"res://data/cards/attack/wild_shot.tres",
		"res://data/cards/attack/six_shooter.tres",
		"res://data/cards/attack/fan_the_hammer.tres",
		"res://data/cards/attack/ambush.tres",
		"res://data/cards/attack/bounty_shot.tres",
		"res://data/cards/attack/desperados_gambit.tres",
		"res://data/cards/attack/pickaxe_strike.tres",
		"res://data/cards/attack/dynamite.tres",
		"res://data/cards/skill/take_cover.tres",
		"res://data/cards/skill/reload.tres",
		"res://data/cards/skill/last_stand.tres",
		"res://data/cards/skill/bush_survival.tres",
		"res://data/cards/skill/outlaws_intuition.tres",
		"res://data/cards/skill/wanted_poster.tres",
		"res://data/cards/skill/bandits_code.tres",
		"res://data/cards/skill/bush_cover.tres",
		"res://data/cards/fortune/strike_it_rich.tres",
		"res://data/cards/power/pub_brawl.tres"
	]
	
	GLog.debug("Loaded %d cards into reward pool" % all_card_paths.size())

func _generate_reward_cards():
	"""Generate 3 random cards for the reward"""
	offered_cards.clear()
	
	# Clear existing card displays
	for child in card_container.get_children():
		child.queue_free()
	
	# Shuffle the card pool
	var available_paths = all_card_paths.duplicate()
	available_paths.shuffle()
	
	# Pick 3 cards (or less if pool is smaller)
	var cards_to_offer = min(3, available_paths.size())
	
	for i in range(cards_to_offer):
		var card_path = available_paths[i]
		var card_data = load(card_path) as CardData
		
		if card_data:
			offered_cards.append(card_data)
			_create_card_display(card_data, i)
		else:
			GLog.error("Failed to load card from path: %s" % card_path)
	
	GLog.info("Offering %d cards as rewards" % offered_cards.size())

func _create_card_display(card_data: CardData, index: int):
	"""Create a visual card display for selection"""
	var card_instance = card_scene.instantiate()
	card_container.add_child(card_instance)
	
	# Setup card visuals
	card_instance.card_data = card_data
	card_instance.setup_card_visuals()
	
	# Scale cards for better display
	card_instance.scale = Vector2(1.2, 1.2)
	
	# Add spacing between cards
	if index > 0:
		card_instance.position.x = index * 200
	
	# Connect card selection
	card_instance.card_played.connect(_on_card_selected.bind(card_data))
	
	# Add hover effects
	card_instance.mouse_entered.connect(_on_card_hover.bind(card_instance))
	card_instance.mouse_exited.connect(_on_card_unhover.bind(card_instance))

func _on_card_selected(card_node: Node, card_data: CardData):
	"""Handle when a card is selected"""
	if selected_card:
		return # Already selected

	selected_card = card_data
	GLog.info("Card selected: %s" % card_data.card_name)

	# Add card to player's deck
	_add_card_to_deck(card_data)

	# Visual feedback
	_highlight_selected_card(card_node)

	# Proceed after short delay
	await get_tree().create_timer(0.5).timeout
	_complete_card_reward()

func _add_card_to_deck(card_data: CardData):
	"""Add the selected card to the player's deck via DeckManager"""
	# Preview mode: show selection but don't add to deck
	if is_test_sequence_preview:
		GLog.info("PREVIEW: Card '%s' selected but NOT added to deck" % card_data.card_name, "victory_reward")
		EventBus.emit_ui_notification("Preview: %s (not added)" % card_data.card_name, "info")
		return

	# Use DeckManager to add the card (proper SOLID approach)
	if DeckManager and DeckManager.is_deck_available():
		var success := DeckManager.add_card(card_data)
		if success:
			GLog.info("Added %s to player deck via DeckManager" % card_data.card_name)
		else:
			GLog.error("Failed to add card via DeckManager: %s" % card_data.card_name)
	else:
		GLog.error("DeckManager not available - card '%s' not added" % card_data.card_name)

	# Emit event for other systems to react
	if EventBus.has_signal("card_added_to_deck"):
		EventBus.emit_signal("card_added_to_deck", card_data)

func _on_skip_pressed():
	"""Handle skip button - proceed without taking a card/curio"""
	if curio_phase_active:
		GLog.info("Player skipped curio reward")
		_finish_and_return_to_map()
	else:
		GLog.info("Player skipped card reward")
		_complete_card_reward()

func _complete_card_reward():
	"""Complete the card reward phase"""
	GLog.info("Card reward phase complete")

	# Add gold if any (skip in preview mode)
	if gold_reward > 0 and not is_test_sequence_preview:
		if not GameManager.game_data.has("gold"):
			GameManager.game_data["gold"] = 0
		GameManager.game_data["gold"] += gold_reward
		GLog.info("Added %d gold to player (total: %d)" % [gold_reward, GameManager.game_data["gold"]])
	elif gold_reward > 0 and is_test_sequence_preview:
		GLog.info("PREVIEW: Gold reward %d shown but not added" % gold_reward, "victory_reward")

	# Check if curio reward is pending (skip in preview mode)
	if pending_curio_reward and not is_test_sequence_preview:
		_show_curio_selection()
	else:
		_finish_and_return_to_map()

func _show_curio_selection():
	"""Show curio selection phase after card reward"""
	GLog.info("Showing curio selection")
	curio_phase_active = true
	pending_curio_reward = false # Consumed

	# Clear card displays
	for child in card_container.get_children():
		child.queue_free()

	# Update title
	if title_label:
		title_label.text = "Choose a Curio"

	# Update skip button text
	if skip_button:
		skip_button.text = "Skip Curio"

	# Hide gold label (already collected)
	if gold_label:
		gold_label.visible = false

	# Get weighted curio selection
	var character_class = ""
	if GameManager and GameManager.current_character_class:
		character_class = GameManager.current_character_class

	var curio_manager = get_node_or_null("/root/CurioManager")
	if curio_manager and curio_manager.has_method("get_weighted_curio_selection"):
		offered_curios = curio_manager.get_weighted_curio_selection(character_class, 3)
	else:
		GLog.error("CurioManager not found or missing get_weighted_curio_selection method")
		_finish_and_return_to_map()
		return

	if offered_curios.is_empty():
		GLog.info("No curios available to offer")
		_finish_and_return_to_map()
		return

	# Display curio options
	for i in range(offered_curios.size()):
		_create_curio_display(offered_curios[i], i)

	GLog.info("Offering %d curios as rewards" % offered_curios.size())

func _create_curio_display(curio_data: Resource, _index: int):
	"""Create a visual curio display for selection"""
	# Create a simple button-based display for now
	var curio_button = Button.new()
	curio_button.custom_minimum_size = Vector2(200, 150)

	# Get curio info
	var curio_name = curio_data.curio_name if "curio_name" in curio_data else "Unknown Curio"
	var description = curio_data.description if "description" in curio_data else ""
	var rarity = curio_data.rarity if "rarity" in curio_data else "Common"

	# Set button text with name, rarity, and description
	curio_button.text = "[%s]\n%s\n\n%s" % [rarity, curio_name, description]
	curio_button.autowrap_mode = TextServer.AUTOWRAP_WORD

	# Apply rarity color
	var rarity_color = _get_rarity_color(rarity)
	curio_button.add_theme_color_override("font_color", rarity_color)

	# Connect selection
	curio_button.pressed.connect(_on_curio_selected.bind(curio_data))

	# Add hover effect
	curio_button.mouse_entered.connect(_on_curio_hover.bind(curio_button))
	curio_button.mouse_exited.connect(_on_curio_unhover.bind(curio_button))

	card_container.add_child(curio_button)

func _get_rarity_color(rarity: String) -> Color:
	"""Get display color for curio rarity"""
	match rarity.to_lower():
		"common":
			return Color(0.8, 0.8, 0.8) # Light gray
		"rare":
			return Color(0.3, 0.5, 1.0) # Blue
		"legendary":
			return Color(1.0, 0.8, 0.2) # Gold
		"corrupted":
			return Color(0.6, 0.2, 0.8) # Purple
		_:
			return Color.WHITE

func _on_curio_selected(curio_data: Resource):
	"""Handle when a curio is selected"""
	var curio_name = curio_data.curio_name if "curio_name" in curio_data else "Unknown"
	GLog.info("Curio selected: %s" % curio_name)

	# Add curio to player via CurioManager
	var curio_manager = get_node_or_null("/root/CurioManager")
	if curio_manager:
		var success = curio_manager.add_curio(curio_data)
		if success:
			GLog.info("Added curio: %s" % curio_name)
			EventBus.ui_notification.emit("Acquired: %s" % curio_name, "reward")
		else:
			GLog.warn("Could not add curio (may be at max stacks)")

	# Proceed to map
	await get_tree().create_timer(0.5).timeout
	_finish_and_return_to_map()

func _on_curio_hover(button: Button):
	"""Visual feedback when hovering over a curio"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)

func _on_curio_unhover(button: Button):
	"""Reset visual when not hovering"""
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _finish_and_return_to_map():
	"""Complete all rewards and return to map (or continue sequence/test setup in preview mode)"""
	if is_test_sequence_preview:
		if should_continue_sequence:
			GLog.info("Victory reward preview complete - continuing to next battle in sequence", "victory_reward")
			# Advance to next enemy in sequence
			if GameManager.test_sequence_state:
				GameManager.test_sequence_state.advance_to_next_enemy()
			# Return to duel scene to continue sequence
			SceneManager.load_scene("res://scenes/game/duel.tscn")
		else:
			GLog.info("Victory reward preview complete - returning to test setup", "victory_reward")
			SceneManager.load_scene("res://scenes/debug/test_duel_setup.tscn")
	else:
		GLog.info("Victory reward complete - returning to map")
		SceneManager.load_scene_by_name("map")

func _display_gold_reward():
	"""Display gold earned from the victory"""
	# Calculate gold based on enemy difficulty (placeholder)
	gold_reward = randi_range(10, 30)
	
	if gold_label:
		gold_label.text = "Gold: +%d" % gold_reward

func _on_card_hover(card_node: Node):
	"""Visual feedback when hovering over a card"""
	if not selected_card:
		var tween = create_tween()
		tween.tween_property(card_node, "position:y", -20, 0.2)
		tween.tween_property(card_node, "scale", Vector2(1.3, 1.3), 0.2)

func _on_card_unhover(card_node: Node):
	"""Reset visual when not hovering"""
	if not selected_card:
		var tween = create_tween()
		tween.tween_property(card_node, "position:y", 0, 0.2)
		tween.tween_property(card_node, "scale", Vector2(1.2, 1.2), 0.2)

func _highlight_selected_card(card_node: Node):
	"""Highlight the selected card"""
	# Scale up selected card
	var tween = create_tween()
	tween.tween_property(card_node, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(card_node, "modulate", Color(1.2, 1.2, 1.2), 0.3)
	
	# Fade out other cards
	for child in card_container.get_children():
		if child != card_node:
			var fade_tween = create_tween()
			fade_tween.tween_property(child, "modulate:a", 0.3, 0.3)

func set_rewards(gold: int = 0, _extra_cards: Array = []):
	"""Set specific rewards (called from duel manager)"""
	gold_reward = gold
	# Could add specific card pools or guaranteed cards here