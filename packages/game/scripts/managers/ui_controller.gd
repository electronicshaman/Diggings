extends Node

const DEBUG_ENABLED: bool = true
const CURIO_ICON_SLOT_SIZE := Vector2(64, 64)
const CURIO_ICON_TEXTURE_SIZE := Vector2(56, 56)
const CURIO_ICON_MARGIN := 6

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
var enemy_status_container: VBoxContainer
var deck_label: Label
var discard_label: Label
var removed_label: Label
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

# Quick draw highlighting system
var quick_draw_highlighting_active: bool = false

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
	enemy_status_container = ui_references.get("enemy_status_container")
	deck_label = ui_references.get("deck")
	discard_label = ui_references.get("discard")
	removed_label = ui_references.get("removed")
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

		# Connect to DuelManager's turn_ended signal for clearing quick draw highlights
		if game_controller.has_node("DuelManager"):
			var duel_manager_node = game_controller.get_node("DuelManager")
			if duel_manager_node.has_signal("turn_ended"):
				duel_manager_node.turn_ended.connect(_on_turn_ended)

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
	
	# Update hand cards energy status
	update_hand_energy_status(p.current_energy)
		
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
	
	# Update status effects display
	_update_enemy_status_display(e)

func _update_enemy_status_display(enemy: EnemyState) -> void:
	"""Update the enemy status effects display with all active statuses"""
	if not enemy_status_container:
		GLog.debug("enemy_status_container is null - UI element missing")
		return
	
	# Clear existing status labels
	for child in enemy_status_container.get_children():
		child.queue_free()
	
	# Build list of active statuses
	var active_statuses: Array[Dictionary] = []
	
	# Check for stun
	if enemy.is_stunned():
		var stun_turns = enemy.stun_turns_remaining
		var status_text = "⚡ STUNNED"
		if stun_turns == 1:
			status_text += " (next turn)"
		else:
			status_text += " (%d turns)" % stun_turns
		active_statuses.append({
			"text": status_text,
			"color": Color(1, 0.8, 0, 1)  # Yellow/orange for stun
		})
	
	# TODO: Add other status effects here as they are implemented
	# Example for future debuffs:
	# if enemy.has_debuff():
	#     active_statuses.append({
	#         "text": "🔻 WEAKENED (2 turns)",
	#         "color": Color(0.8, 0.2, 0.2, 1)  # Red for debuffs
	#     })
	
	# Create and add labels for each active status
	for status in active_statuses:
		var status_label = Label.new()
		status_label.text = status.text
		status_label.add_theme_color_override("font_color", status.color)
		status_label.add_theme_font_size_override("font_size", 18)
		enemy_status_container.add_child(status_label)

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

	if removed_label:
		removed_label.text = "Removed: %d" % duel_state_manager.get_removed_count()
	else:
		GLog.debug("removed_label is null - UI element missing")

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

func update_hand_energy_status(current_energy: int) -> void:
	for card in hand_cards:
		if card.has_method("update_energy_status"):
			card.update_energy_status(current_energy)

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
	
	# Check if we should highlight quick draw cards (before any cards played this turn)
	var duel_state_ref = duel_state_manager.current_duel_state
	var should_highlight_quick_draw = (duel_state_ref
		and duel_state_ref.player_data
		and duel_state_ref.player_data.cards_played_this_turn == 0)

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
		
		# Update energy status immediately
		if duel_state_ref and duel_state_ref.player_data and card_node.has_method("update_energy_status"):
			card_node.update_energy_status(duel_state_ref.player_data.current_energy)

		card_node.card_played.connect(_on_hand_card_played)

		# Apply quick draw highlighting if applicable
		if should_highlight_quick_draw and ci.card_data:
			if ci.card_data.has_first_card_played_condition():
				if card_node.has_method("set_quick_draw_highlight"):
					card_node.set_quick_draw_highlight(true)
					quick_draw_highlighting_active = true

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

func clear_quick_draw_highlights() -> void:
	"""Clear quick draw highlighting from all cards in hand"""
	if not quick_draw_highlighting_active:
		return

	if not hand_area:
		quick_draw_highlighting_active = false
		return

	for child in hand_area.get_children():
		if child.has_method("set_quick_draw_highlight"):
			child.set_quick_draw_highlight(false)

	quick_draw_highlighting_active = false

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

func _on_turn_ended(is_player_turn: bool) -> void:
	"""Handle turn end signal to clear quick draw highlights"""
	if is_player_turn:
		clear_quick_draw_highlights()

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
	"""Render active curios as icons with overlays for duels"""
	if not curios_list:
		return

	_clear_curios_display()

	if not CurioManager:
		_show_empty_curio_state()
		return

	var active_curios = CurioManager.get_active_curios()
	if active_curios.is_empty():
		_show_empty_curio_state()
		return

	for curio in active_curios:
		if not curio:
			continue
		var curio_name = curio.curio_name if curio.curio_name else ""
		var stack_count = 1
		if CurioManager and curio_name != "":
			stack_count = max(CurioManager.get_curio_stack_count(curio_name), 1)
		curios_list.add_child(_create_curio_icon_node(curio, stack_count))

func _clear_curios_display() -> void:
	for child in curios_list.get_children():
		child.queue_free()

func _show_empty_curio_state() -> void:
	var label = Label.new()
	label.text = "No Curios"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(0.7, 0.7, 0.7, 0.9)
	label.add_theme_font_size_override("font_size", 18)
	curios_list.add_child(label)

func _create_curio_icon_node(curio: CurioData, stack_count: int) -> Control:
	var slot = MarginContainer.new()
	slot.custom_minimum_size = CURIO_ICON_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.tooltip_text = _build_curio_tooltip(curio, stack_count)
	slot.add_theme_constant_override("margin_left", CURIO_ICON_MARGIN)
	slot.add_theme_constant_override("margin_right", CURIO_ICON_MARGIN)
	slot.add_theme_constant_override("margin_top", CURIO_ICON_MARGIN)
	slot.add_theme_constant_override("margin_bottom", CURIO_ICON_MARGIN)

	var holder = Control.new()
	holder.custom_minimum_size = CURIO_ICON_TEXTURE_SIZE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background = ColorRect.new()
	background.color = _get_curio_background_color(curio)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(background)

	var icon_texture: Texture2D = curio.icon if curio.icon else null
	if icon_texture:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(icon_rect)
	else:
		var fallback_label = Label.new()
		fallback_label.text = curio.curio_name if curio.curio_name else "Curio"
		fallback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback_label.add_theme_font_size_override("font_size", 12)
		fallback_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(fallback_label)

	if stack_count > 1:
		var stack_badge = Label.new()
		stack_badge.text = "x%d" % stack_count
		stack_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stack_badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		stack_badge.add_theme_font_size_override("font_size", 14)
		stack_badge.add_theme_color_override("font_color", Color.WHITE)
		stack_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		stack_badge.add_theme_constant_override("outline_size", 2)
		stack_badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		stack_badge.offset_left = -36
		stack_badge.offset_top = -24
		stack_badge.offset_right = -4
		stack_badge.offset_bottom = -4
		holder.add_child(stack_badge)

	return slot

func _build_curio_tooltip(curio: CurioData, stack_count: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var display_name = curio.curio_name if curio.curio_name else "Unknown Curio"
	if stack_count > 1:
		display_name += " (x%d)" % stack_count
	parts.append(display_name)
	if curio.description:
		parts.append(curio.description)
	return "\n".join(parts)

func _get_curio_background_color(curio: CurioData) -> Color:
	var rarity_color = curio.get_rarity_color() if curio and curio.has_method("get_rarity_color") else Color(0.3, 0.3, 0.3)
	var blended = rarity_color.lerp(Color.BLACK, 0.55)
	blended.a = 0.9
	return blended

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
