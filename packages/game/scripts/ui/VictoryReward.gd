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

func _ready():
	GLog.info("Victory reward screen loaded")
	
	# Setup button connections
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	
	# Load all available cards
	_load_card_pool()
	
	# Generate and display reward cards
	_generate_reward_cards()
	
	# Display gold reward (if any)
	_display_gold_reward()

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
		return  # Already selected
	
	selected_card = card_data
	GLog.info("Card selected: %s" % card_data.card_name)
	
	# Add card to player's deck
	_add_card_to_deck(card_data)
	
	# Visual feedback
	_highlight_selected_card(card_node)
	
	# Proceed after short delay
	await get_tree().create_timer(0.5).timeout
	_complete_reward()

func _add_card_to_deck(card_data: CardData):
	"""Add the selected card to the player's deck"""
	# Store the card path in game_data for persistence
	if not GameManager.game_data.has("player_deck"):
		GameManager.game_data["player_deck"] = []
	
	# Add the card's resource path to the deck
	GameManager.game_data["player_deck"].append(card_data.resource_path)
	GLog.info("Added %s to player deck" % card_data.card_name)
	
	# Emit event for other systems to react
	if EventBus.has_signal("card_added_to_deck"):
		EventBus.emit_signal("card_added_to_deck", card_data)

func _on_skip_pressed():
	"""Handle skip button - proceed without taking a card"""
	GLog.info("Player skipped card reward")
	_complete_reward()

func _complete_reward():
	"""Complete the reward phase and move to next scene"""
	GLog.info("Victory reward complete")
	
	# Add gold if any
	if gold_reward > 0:
		if not GameManager.game_data.has("gold"):
			GameManager.game_data["gold"] = 0
		GameManager.game_data["gold"] += gold_reward
		GLog.info("Added %d gold to player (total: %d)" % [gold_reward, GameManager.game_data["gold"]])
	
	# Return to map to continue the adventure
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

func set_rewards(gold: int = 0, extra_cards: Array = []):
	"""Set specific rewards (called from duel manager)"""
	gold_reward = gold
	# Could add specific card pools or guaranteed cards here