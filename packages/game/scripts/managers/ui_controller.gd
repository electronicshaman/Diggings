extends Node

const DEBUG_ENABLED: bool = true

signal ui_refresh_requested()
signal hand_refresh_requested()

var game_controller: Node
var duel_state: Resource

var player_health_label: Label
var player_energy_label: Label
var player_defense_label: Label
var player_sanity_label: Label
var player_gold_label: Label
var character_name_label: Label
var enemy_name_label: Label
var enemy_health_label: Label
var enemy_defense_label: Label
var deck_label: Label
var discard_label: Label
var turn_label: Label
var phase_label: Label
var seed_label: Label
var end_turn_button: Button
var debug_panel: Control

var hand_area: Node2D
var hand_cards: Array[Node] = []
var card_scene: PackedScene

# Battlefield system - visual areas
var enemy_hand_area: Node2D
var battlefield_area: Node2D
var enemy_hand_cards: Array[Node] = []
var battlefield_cards: Array[Node] = []

var curios_panel: Control
var curios_list: HBoxContainer

# Debounced visual refresh to avoid flicker/resets on rapid state changes
var _ui_refresh_timer: Timer
const UI_REFRESH_DEBOUNCE_SEC := 0.05

func _ready() -> void:
	GLog.debug("UIController initialized - Managing the mortal interface")
	card_scene = preload("res://scenes/cards/card.tscn")
	
	# Connect to UI notification events
	EventBus.ui_notification.connect(_on_ui_notification)

	# Create a one-shot timer to batch visual refreshes (hand/battlefield)
	_ui_refresh_timer = Timer.new()
	_ui_refresh_timer.one_shot = true
	_ui_refresh_timer.wait_time = UI_REFRESH_DEBOUNCE_SEC
	add_child(_ui_refresh_timer)
	_ui_refresh_timer.timeout.connect(_on_ui_refresh_timer_timeout)

func initialize(ui_references: Dictionary, game_controller_ref: Node) -> void:
	game_controller = game_controller_ref
	
	player_health_label = ui_references.get("player_health")
	player_energy_label = ui_references.get("player_energy")
	player_defense_label = ui_references.get("player_defense")
	player_sanity_label = ui_references.get("player_sanity")
	player_gold_label = ui_references.get("player_gold")
	character_name_label = ui_references.get("character_name")
	enemy_name_label = ui_references.get("enemy_name")
	enemy_health_label = ui_references.get("enemy_health")
	enemy_defense_label = ui_references.get("enemy_defense")
	deck_label = ui_references.get("deck")
	discard_label = ui_references.get("discard")
	turn_label = ui_references.get("turn")
	phase_label = ui_references.get("phase")
	seed_label = ui_references.get("seed")
	end_turn_button = ui_references.get("end_turn_button")
	debug_panel = ui_references.get("debug_panel")
	hand_area = ui_references.get("hand_area")
	enemy_hand_area = ui_references.get("enemy_hand_area")
	battlefield_area = ui_references.get("battlefield_area")
	
	curios_panel = ui_references.get("curios_panel")
	curios_list = ui_references.get("curios_list")
	
	if game_controller:
		game_controller.game_state_updated.connect(update_all_ui)
		if "current_duel_state" in game_controller:
			duel_state = game_controller.current_duel_state
	
	# Connect to CurioManager signals
	if CurioManager:
		CurioManager.curio_acquired.connect(_on_curio_acquired)
		CurioManager.curio_removed.connect(_on_curio_removed)
		CurioManager.curio_stack_changed.connect(_on_curio_stack_changed)
	
	setup_debug_buttons(ui_references)

func setup_debug_buttons(ui_references: Dictionary) -> void:
	var add_card_btn = ui_references.get("add_card_button")
	var set_health_btn = ui_references.get("set_health_button")
	var set_energy_btn = ui_references.get("set_energy_button")
	var reset_duel_btn = ui_references.get("reset_duel_button")
	
	if add_card_btn:
		add_card_btn.pressed.connect(_on_add_card_pressed)
	if set_health_btn:
		set_health_btn.pressed.connect(_on_set_health_pressed)
	if set_energy_btn:
		set_energy_btn.pressed.connect(_on_set_energy_pressed)
	if reset_duel_btn:
		reset_duel_btn.pressed.connect(_on_reset_duel_pressed)

func update_duel_state(new_state: Resource) -> void:
	duel_state = new_state
	update_all_ui()

func update_all_ui() -> void:
	update_player_ui()
	update_enemy_ui()
	update_pile_ui()
	update_turn_ui()
	update_seed_ui()
	update_curios_display()
	_queue_visual_refresh()

func update_player_ui() -> void:
	if not duel_state or not duel_state.player_data:
		return
	
	var p = duel_state.player_data
	
	# Update player stats with null safety checks
	if player_health_label:
		player_health_label.text = "Health: %d/%d" % [p.current_health, p.max_health]
	else:
		GLog.debug("player_health_label is null - UI element missing")
		
	if player_energy_label:
		player_energy_label.text = "Energy: %d/%d" % [p.current_energy, p.max_energy]
	else:
		GLog.debug("player_energy_label is null - UI element missing")
		
	if player_defense_label:
		player_defense_label.text = "Defense: %d" % p.defense
	else:
		GLog.debug("player_defense_label is null - UI element missing")
		
	if player_sanity_label:
		player_sanity_label.text = "Sanity: %d/%d" % [p.current_sanity, p.max_sanity]
	else:
		GLog.debug("player_sanity_label is null - UI element missing")
		
	# Optional UI elements (gracefully handle missing)
	if player_gold_label and p.stats:
		player_gold_label.text = "Gold: %d" % p.stats.current_gold
		
	if character_name_label:
		character_name_label.text = p.get_display_name()

func update_enemy_ui() -> void:
	if not duel_state or not duel_state.enemy_data:
		return
	
	var e = duel_state.enemy_data
	
	if enemy_name_label:
		enemy_name_label.text = e.enemy_name
	else:
		GLog.debug("enemy_name_label is null - UI element missing")
		
	if enemy_health_label:
		enemy_health_label.text = "Health: %d/%d" % [e.current_health, e.max_health]
	else:
		GLog.debug("enemy_health_label is null - UI element missing")
		
	if enemy_defense_label:
		enemy_defense_label.text = "Defense: %d" % e.defense
	else:
		GLog.debug("enemy_defense_label is null - UI element missing")

func update_pile_ui() -> void:
	if not game_controller:
		return
	
	# Get DuelStateManager from the scene controller
	var duel_state_manager = game_controller.get_duel_state_manager()
	if not duel_state_manager:
		GLog.debug("duel_state_manager not available - cannot update pile UI")
		return
	
	if deck_label:
		deck_label.text = "Deck: %d" % duel_state_manager.get_deck_count()
	else:
		GLog.debug("deck_label is null - UI element missing")
		
	if discard_label:
		discard_label.text = "Discard: %d" % duel_state_manager.get_discard_count()
	else:
		GLog.debug("discard_label is null - UI element missing")

func update_turn_ui() -> void:
	if not duel_state:
		return
	
	if turn_label:
		turn_label.text = "Turn: %d" % duel_state.current_turn
	else:
		GLog.debug("turn_label is null - UI element missing")
	
	if phase_label:
		if "duel_ended" in duel_state and duel_state.duel_ended:
			phase_label.text = "Duel Complete"
		else:
			phase_label.text = "Player Turn" if duel_state.is_player_turn else "Enemy Turn"
	else:
		GLog.debug("phase_label is null - UI element missing")
	
	if end_turn_button:
		end_turn_button.disabled = not duel_state.is_player_turn
	else:
		GLog.debug("end_turn_button is null - UI element missing")

func update_seed_ui() -> void:
	"""Update the seed display based on GameSettings."""
	if not seed_label:
		return
	
	# Only show seed if the setting is enabled
	if GameSettings.show_seed_in_ui and SeedManager.is_run_active():
		seed_label.visible = true
		var hash_seed = SeedManager.get_hash_seed_string()
		var is_thematic = SeedManager.is_thematic_seed(hash_seed)
		
		if is_thematic:
			seed_label.text = "Seed: %s ✨" % hash_seed  # Special indicator for thematic seeds
		else:
			seed_label.text = "Seed: %s" % hash_seed
	else:
		seed_label.visible = false

func refresh_hand_display() -> void:
	clear_hand_display()
	
	if not game_controller or not hand_area:
		return
	
	# Get DuelStateManager from the scene controller
	var duel_state_manager = game_controller.get_duel_state_manager()
	if not duel_state_manager:
		GLog.debug("duel_state_manager not available - cannot refresh hand")
		return
	
	var hand_data = duel_state_manager.get_hand_cards()
	
	for i in range(hand_data.size()):
		var ci = hand_data[i]
		var card_node = card_scene.instantiate()
		hand_area.add_child(card_node)
		hand_cards.append(card_node)
		
		var card_spacing = 160
		var total_width = (hand_data.size() - 1) * card_spacing
		var start_x = -total_width / 2
		card_node.position.x = start_x + i * card_spacing
		card_node.position.y = 0
		card_node.scale = Vector2(0.625, 0.625)  # Scale down from 300x420 to 187x262 (25% larger)
		
		if card_node.has_method("set_card"):
			card_node.set_card(ci)
		elif "card_instance" in card_node:
			card_node.card_instance = ci
			card_node.card_data = ci.card_data
		else:
			card_node.card_data = ci.card_data
		if card_node.has_method("setup_card_visuals"):
			card_node.setup_card_visuals()
		card_node.card_played.connect(_on_hand_card_played)
	
	hand_refresh_requested.emit()

func _queue_visual_refresh() -> void:
	# Restart the timer so bursts of updates coalesce into a single refresh
	if _ui_refresh_timer:
		_ui_refresh_timer.start(UI_REFRESH_DEBOUNCE_SEC)

func _on_ui_refresh_timer_timeout() -> void:
	# Perform the actual visual refreshes once after the burst of changes
	refresh_hand_display()
	refresh_enemy_hand_display()
	refresh_battlefield_display()
	ui_refresh_requested.emit()

func clear_hand_display() -> void:
	for card_node in hand_cards:
		if is_instance_valid(card_node):
			card_node.queue_free()
	hand_cards.clear()

func _on_hand_card_played(card_node: Node) -> void:
	if not game_controller:
		return
	
	# Get DuelStateManager from the scene controller
	var duel_state_manager = game_controller.get_duel_state_manager()
	if not duel_state_manager:
		GLog.debug("duel_state_manager not available - cannot play card")
		return
	
	var ci = null
	if card_node.has_method("get_card_instance_or_null"):
		ci = card_node.get_card_instance_or_null()
	elif "card_instance" in card_node:
		ci = card_node.card_instance
	else:
		var cd = card_node.get("card_data")
		if cd:
			ci = CardInstance.new(cd)
	if ci:
		duel_state_manager.play_card(ci)

func refresh_enemy_hand_display() -> void:
	clear_enemy_hand_display()
	
	if not duel_state or not duel_state.enemy_data or not enemy_hand_area:
		return
	
	var enemy_hand_data = duel_state.enemy_data.enemy_hand.cards if duel_state.enemy_data.enemy_hand else []
	
	for i in range(enemy_hand_data.size()):
		var card_instance = card_scene.instantiate()
		enemy_hand_area.add_child(card_instance)
		enemy_hand_cards.append(card_instance)
		
		var card_spacing = 120
		var total_width = (enemy_hand_data.size() - 1) * card_spacing
		var start_x = -total_width / 2
		card_instance.position.x = start_x + i * card_spacing
		card_instance.position.y = 0
		card_instance.scale = Vector2(0.4, 0.4)  # Smaller enemy cards (120x168)
		
		# Show as card back (enemy cards are hidden)
		card_instance.show_as_card_back()

func clear_enemy_hand_display() -> void:
	for card_node in enemy_hand_cards:
		if is_instance_valid(card_node):
			card_node.queue_free()
	enemy_hand_cards.clear()

func refresh_battlefield_display() -> void:
	clear_battlefield_display()
	
	if not duel_state or not duel_state.battlefield or not battlefield_area:
		return
	
	var battlefield_data = duel_state.battlefield.cards
	
	for i in range(battlefield_data.size()):
		var ci = battlefield_data[i]
		var card_node = card_scene.instantiate()
		battlefield_area.add_child(card_node)
		battlefield_cards.append(card_node)
		
		var card_spacing = 140
		var total_width = (battlefield_data.size() - 1) * card_spacing
		var start_x = -total_width / 2
		card_node.position.x = start_x + i * card_spacing
		card_node.position.y = 0
		card_node.scale = Vector2(0.45, 0.45)  # Slightly smaller battlefield cards (135x189)
		
		if card_node.has_method("set_card"):
			card_node.set_card(ci)
		elif "card_instance" in card_node:
			card_node.card_instance = ci
			card_node.card_data = ci.card_data
		else:
			card_node.card_data = ci.card_data
		if card_node.has_method("setup_card_visuals"):
			card_node.setup_card_visuals()
		
		# TODO: Differentiate between player and enemy cards visually
		
func clear_battlefield_display() -> void:
	for card_node in battlefield_cards:
		if is_instance_valid(card_node):
			card_node.queue_free()
	battlefield_cards.clear()

func show_duel_result(winner: String) -> void:
	if phase_label:
		var result_text = "Victory!" if winner == "player" else "Defeat!"
		phase_label.text = result_text
	
	if end_turn_button:
		end_turn_button.disabled = true
	
	EventBus.emit_ui_notification(
		"Duel Complete" if winner == "player" else "You have fallen",
		"success" if winner == "player" else "error"
	)

func toggle_debug_panel() -> void:
	if debug_panel:
		debug_panel.visible = not debug_panel.visible

func _on_add_card_pressed() -> void:
	if not game_controller:
		return
	var duel_state_manager = game_controller.get_duel_state_manager()
	if duel_state_manager:
		duel_state_manager.add_random_card_to_hand()

func _on_set_health_pressed() -> void:
	if not game_controller:
		return
	var duel_state_manager = game_controller.get_duel_state_manager()
	if duel_state_manager:
		duel_state_manager.modify_player_health(10)

func _on_set_energy_pressed() -> void:
	if not game_controller:
		return
	var duel_state_manager = game_controller.get_duel_state_manager()
	if duel_state_manager:
		duel_state_manager.modify_player_energy(10)

func _on_reset_duel_pressed() -> void:
	if not game_controller:
		return
	var duel_state_manager = game_controller.get_duel_state_manager()
	if duel_state_manager:
		duel_state_manager.start_test_duel()

func _on_ui_notification(message: String, type: String) -> void:
	"""Handle UI notifications like curio rewards"""
	GLog.info("🎉 UI Notification [%s]: %s" % [type, message])
	
	# For now, just show in debug panel or console
	# Later we can add popup notifications
	if type == "reward":
		GLog.info("Curio reward notification displayed!")

func update_curios_display() -> void:
	"""Update the display of active curios in the UI"""
	if not curios_list:
		return
	
	# Clear existing labels (except the first one which might be placeholder)
	for child in curios_list.get_children():
		if child != curios_list.get_child(0):
			child.queue_free()
	
	# Get active curios from CurioManager
	if not CurioManager:
		return
	
	var active_curios = CurioManager.get_active_curios()
	
	if active_curios.is_empty():
		# Show "No Curios" if empty
		var label = curios_list.get_child(0) if curios_list.get_child_count() > 0 else null
		if label and label is Label:
			label.text = "No Curios"
			label.modulate = Color.GRAY
		return
	
	# Remove placeholder if we have curios
	if curios_list.get_child_count() > 0:
		curios_list.get_child(0).queue_free()
	
	# Add a label for each active curio
	for curio in active_curios:
		if not curio:
			continue
		
		var label = Label.new()
		var curio_name = curio.curio_name if curio.curio_name else "Unknown"
		var stack_count = CurioManager.get_curio_stack_count(curio_name)
		
		# Format the text with stack count if applicable
		if stack_count > 1:
			label.text = "%s (x%d)" % [curio_name, stack_count]
		else:
			label.text = curio_name
		
		# Color based on rarity
		if curio.has_method("get_rarity_color"):
			label.modulate = curio.get_rarity_color()
		else:
			# Fallback color based on rarity string
			var rarity = curio.rarity if curio.rarity else "Common"
			match rarity:
				"Rare":
					label.modulate = Color.CYAN
				"Legendary":
					label.modulate = Color.GOLD
				"Corrupted":
					label.modulate = Color.PURPLE
				_:
					label.modulate = Color.WHITE
		
		# Add tooltip with description
		if curio.description:
			label.tooltip_text = curio.description
		
		curios_list.add_child(label)

func _on_curio_acquired(curio: Resource) -> void:
	"""Handle when a new curio is acquired"""
	update_curios_display()
	var curio_name = curio.curio_name if curio and curio.curio_name else "Unknown Curio"
	EventBus.emit_ui_notification("Acquired: " + curio_name, "success")

func _on_curio_removed(_curio: Resource) -> void:
	"""Handle when a curio is removed"""
	update_curios_display()

func _on_curio_stack_changed(_curio: Resource, _new_count: int) -> void:
	"""Handle when a curio's stack count changes"""
	update_curios_display()
