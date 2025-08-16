extends Node2D

# Debug toggle for this file
const DEBUG_ENABLED: bool = true

@onready var duel_manager = $DuelManager
@onready var hand_area = $UI/Control/HandArea
@onready var player_health_label = $UI/Control/PlayerArea/PlayerStats/HealthLabel
@onready var player_energy_label = $UI/Control/PlayerArea/PlayerStats/EnergyLabel
@onready var player_defense_label = $UI/Control/PlayerArea/PlayerStats/DefenseLabel
@onready var player_sanity_label = $UI/Control/PlayerArea/PlayerStats/SanityLabel
@onready var enemy_name_label = $UI/Control/EnemyArea/EnemyStats/EnemyName
@onready var enemy_health_label = $UI/Control/EnemyArea/EnemyStats/EnemyHealth
@onready var enemy_defense_label = $UI/Control/EnemyArea/EnemyStats/EnemyDefense
@onready var deck_label = $UI/Control/PileIndicatorsLeft/DeckLabel
@onready var discard_label = $UI/Control/PileIndicatorsRight/DiscardLabel
@onready var turn_label = $UI/Control/TurnInfo/TurnLabel
@onready var phase_label = $UI/Control/TurnInfo/PhaseLabel
@onready var end_turn_button = $UI/Control/TurnInfo/EndTurnButton
@onready var debug_panel = $UI/Control/DebugPanel

var card_scene = preload("res://scenes/card.tscn")
var test_cards = []
var test_enemies = []
var hand_cards = []

func _ready():
	GLog.info("MainGameController ready, loading test content...")
	
	load_test_cards()
	load_test_enemies()
	
	duel_manager.duel_started.connect(_on_duel_started)
	duel_manager.turn_started.connect(_on_turn_started)
	duel_manager.card_played.connect(_on_card_played)
	duel_manager.duel_ended.connect(_on_duel_ended)
	
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	$UI/Control/DebugPanel/DebugButtons/AddCardButton.pressed.connect(_on_add_card_pressed)
	$UI/Control/DebugPanel/DebugButtons/SetHealthButton.pressed.connect(_on_set_health_pressed)
	$UI/Control/DebugPanel/DebugButtons/SetEnergyButton.pressed.connect(_on_set_energy_pressed)
	$UI/Control/DebugPanel/DebugButtons/ResetDuelButton.pressed.connect(_on_reset_duel_pressed)
	
	duel_manager.duel_state.add_change_listener(_on_duel_state_changed)
	
	await get_tree().create_timer(0.5).timeout
	start_test_duel()

func _input(event):
	if event.is_action_pressed("ui_page_up"):
		debug_panel.visible = !debug_panel.visible

func load_test_cards():
	var card_paths = [
		"res://resources/test_cards/gold/pickaxe_strike.tres",
		"res://resources/test_cards/gold/dynamite.tres",
		"res://resources/test_cards/grit/bush_defense.tres",
		"res://resources/test_cards/grog/pub_brawl.tres",
		"res://resources/test_cards/gamble/strike_it_rich.tres"
	]
	
	for path in card_paths:
		var card_data = load(path)
		if card_data:
			test_cards.append(card_data)
			GLog.debug("Loaded test card: %s" % card_data.card_name)

func load_test_enemies():
	var enemy_paths = [
		"res://resources/test_enemies/claim_jumper.tres",
		"res://resources/test_enemies/mad_dog_morgan.tres"
	]
	
	for path in enemy_paths:
		var enemy_data = load(path)
		if enemy_data:
			test_enemies.append(enemy_data)
			GLog.debug("Loaded test enemy: %s" % enemy_data.enemy_name)

func start_test_duel():
	if test_cards.is_empty() or test_enemies.is_empty():
		GLog.error("No test content loaded!")
		return
	
	var player_deck: Array[CardData] = []
	for i in range(15):
		player_deck.append(test_cards[i % test_cards.size()])
	
	var enemy = test_enemies[0]
	
	duel_manager.start_new_duel(player_deck, enemy)

func _on_duel_started():
	GLog.info("Duel started! Updating UI...")
	update_ui()
	refresh_hand_display()

func _on_turn_started(is_player_turn: bool):
	GLog.debug("Turn started: %s" % ("Player" if is_player_turn else "Enemy"))
	update_ui()
	refresh_hand_display()
	end_turn_button.disabled = !is_player_turn

func _on_card_played(card_data: CardData):
	GLog.debug("Card played: %s" % card_data.card_name)
	update_ui()
	refresh_hand_display()

func _on_duel_ended(winner: String):
	GLog.info("Duel ended! Winner: %s" % winner)
	end_turn_button.disabled = true
	
	var result_text = "Victory!" if winner == "player" else "Defeat!"
	phase_label.text = result_text

func _on_end_turn_pressed():
	if duel_manager.duel_state.is_player_turn:
		duel_manager.end_player_turn()

func _on_duel_state_changed(change_type: String, data: Dictionary):
	update_ui()
	if change_type.begins_with("hand_"):
		refresh_hand_display()

func update_ui():
	var duel_state = duel_manager.duel_state
	
	if duel_state.player_data:
		var p = duel_state.player_data
		player_health_label.text = "Health: %d/%d" % [p.current_health, p.max_health]
		player_energy_label.text = "Energy: %d/%d" % [p.current_energy, p.max_energy]
		player_defense_label.text = "Defense: %d" % p.defense
		player_sanity_label.text = "Sanity: %d/%d" % [p.current_sanity, p.max_sanity]
	
	if duel_state.enemy_data:
		var e = duel_state.enemy_data
		enemy_name_label.text = e.enemy_name
		enemy_health_label.text = "Health: %d/%d" % [e.current_health, e.max_health]
		enemy_defense_label.text = "Defense: %d" % e.defense
	
	deck_label.text = "Deck: %d" % duel_manager.get_deck_count()
	discard_label.text = "Discard: %d" % duel_manager.get_discard_count()
	
	turn_label.text = "Turn: %d" % duel_state.current_turn
	phase_label.text = "Player Turn" if duel_state.is_player_turn else "Enemy Turn"

func refresh_hand_display():
	for card_node in hand_cards:
		card_node.queue_free()
	hand_cards.clear()
	
	var hand_data = duel_manager.get_hand_cards()
	
	
	for i in range(hand_data.size()):
		var card_data = hand_data[i]
		var card_instance = card_scene.instantiate()
		hand_area.add_child(card_instance)
		hand_cards.append(card_instance)
		
		# Position cards manually - HandArea is now a Node2D
		var card_spacing = 160  # 150 width + 10 spacing
		var total_width = (hand_data.size() - 1) * card_spacing
		var start_x = -total_width / 2
		var calculated_x = start_x + i * card_spacing
		card_instance.position.x = calculated_x
		card_instance.position.y = 0
		
		
		card_instance.card_data = card_data
		card_instance.setup_card_visuals()
		
		card_instance.card_played.connect(_on_hand_card_played)

func _on_hand_card_played(card_node):
	var card_data = card_node.card_data
	if card_data:
		duel_manager.play_card(card_data)

func _on_add_card_pressed():
	if test_cards.is_empty():
		return
	
	var random_card = test_cards[randi() % test_cards.size()]
	duel_manager.duel_state.hand.add_card(random_card)
	refresh_hand_display()

func _on_set_health_pressed():
	if duel_manager.duel_state.player_data:
		duel_manager.duel_state.player_data.current_health += 10
		update_ui()

func _on_set_energy_pressed():
	if duel_manager.duel_state.player_data:
		duel_manager.duel_state.player_data.current_energy += 10
		update_ui()

func _on_reset_duel_pressed():
	start_test_duel()
