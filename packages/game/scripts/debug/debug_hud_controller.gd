extends Node2D

const DEBUG_ENABLED: bool = true

var panel_container: PanelContainer
var update_timer: Timer

# Core Game State
var current_scene_value: Label
var game_state_value: Label
var game_mode_value: Label
var run_active_value: Label
var run_time_value: Label
var session_time_value: Label

# Seeds & RNG
var master_seed_value: Label
var hash_seed_value: Label
var is_thematic_value: Label
var rng_stream_value: Label

# Player Data
var character_class_value: Label
var character_name_value: Label
var health_value: Label
var energy_value: Label
var sanity_value: Label
var defense_value: Label
var gold_value: Label
var corruption_value: Label

# Curios
var curios_list: VBoxContainer
var curios_total_value: Label

# Run Statistics
var cards_played_value: Label
var damage_dealt_value: Label
var damage_taken_value: Label
var enemies_defeated_value: Label
var perfect_battles_value: Label
var turns_taken_value: Label

# System/Debug
var fps_value: Label
var memory_value: Label
var god_mode_value: Label
var debug_mode_value: Label
var eventbus_signals_value: Label
var active_modals_value: Label
var encountered_ids_title: Label
var encountered_ids_list: RichTextLabel

func _ready() -> void:
	GLog.debug("Debug HUD Controller initialized")
	
	# Cache core container first and start hidden (CanvasLayer children don't inherit Node2D visibility)
	panel_container = get_node_or_null("CanvasLayer/PanelContainer")
	if panel_container:
		panel_container.visible = false
	else:
		# Fallback – hide this node (may not affect CanvasLayer children)
		visible = false
	
	# Cache all the label references
	cache_ui_references()
	
	# Set up update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.5  # Update twice per second
	update_timer.autostart = true
	update_timer.timeout.connect(_update_all_data)
	add_child(update_timer)
	
	# Initial update
	_update_all_data()
	
	set_process_unhandled_input(true)

func cache_ui_references() -> void:
	# Root panel reference for visibility toggling
	if panel_container == null:
		panel_container = get_node_or_null("CanvasLayer/PanelContainer")

	# Core Game State
	current_scene_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/CurrentScene/Value")
	game_state_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/GameState/Value")
	game_mode_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/GameMode/Value")
	run_active_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/RunActive/Value")
	run_time_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/RunTime/Value")
	session_time_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/CoreGameState/SessionTime/Value")
	
	# Seeds & RNG
	master_seed_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SeedsRNG/MasterSeed/Value")
	hash_seed_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SeedsRNG/HashSeed/Value")
	is_thematic_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SeedsRNG/IsThematic/Value")
	rng_stream_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/SeedsRNG/CurrentRNGStream/Value")
	
	# Player Data
	character_class_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/CharacterClass/Value")
	character_name_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/CharacterName/Value")
	health_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Health/Value")
	energy_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Energy/Value")
	sanity_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Sanity/Value")
	defense_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Defense/Value")
	gold_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Gold/Value")
	corruption_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerData/Corruption/Value")
	
	# Curios
	curios_list = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Curios/CuriosScroll/CuriosList")
	curios_total_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Curios/TotalCount/Value")
	
	# Run Statistics
	cards_played_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/CardsPlayed/Value")
	damage_dealt_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/DamageDealt/Value")
	damage_taken_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/DamageTaken/Value")
	enemies_defeated_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/EnemiesDefeated/Value")
	perfect_battles_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/PerfectBattles/Value")
	turns_taken_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/RunStatistics/TurnsTaken/Value")
	
	# System/Debug
	fps_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/FPS/Value")
	memory_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/MemoryUsage/Value")
	god_mode_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/GodMode/Value")
	debug_mode_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/DebugMode/Value")
	eventbus_signals_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/EventBusSignals/Value")
	active_modals_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/ActiveModals/Value")

	# Ensure Encounter IDs UI exists under SystemDebug and cache references
	_ensure_encounter_ids_ui()

func _unhandled_input(event: InputEvent) -> void:
	# Use the named input action instead of hardcoded keycode
	if event.is_action_pressed("HUD"):
		toggle_visibility()
		get_viewport().set_input_as_handled()

func toggle_visibility() -> void:
	# Prefer toggling the UI container so the CanvasLayer is actually hidden
	if panel_container:
		panel_container.visible = not panel_container.visible
		if panel_container.visible:
			_update_all_data()  # Force update when showing
			GLog.debug("Debug HUD shown")
		else:
			GLog.debug("Debug HUD hidden")
		return

	# Fallback to Node2D visibility if container missing
	visible = !visible
	if visible:
		_update_all_data()  # Force update when showing
		GLog.debug("Debug HUD shown")
	else:
		GLog.debug("Debug HUD hidden")

func _update_all_data() -> void:
	update_core_game_state()
	update_seeds_rng()
	update_player_data()
	update_curios()
	update_run_statistics()
	update_system_debug()
	_update_encounter_ids()

func update_core_game_state() -> void:
	# Current Scene
	if current_scene_value:
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene_value.text = current_scene.name
		else:
			current_scene_value.text = "None"
	
	# Game State
	if game_state_value and GameManager:
		var state_names = ["MENU", "PLAYING", "PAUSED", "GAME_OVER", "VICTORY", "LOADING"]
		if GameManager.current_state < state_names.size():
			game_state_value.text = state_names[GameManager.current_state]
		else:
			game_state_value.text = str(GameManager.current_state)
	
	# Game Mode
	if game_mode_value and GameManager:
		var mode_names = ["STANDARD", "DAILY", "ENDLESS", "CUSTOM"]
		if GameManager.current_mode < mode_names.size():
			game_mode_value.text = mode_names[GameManager.current_mode]
		else:
			game_mode_value.text = str(GameManager.current_mode)
	
	# Run Active
	if run_active_value and GameManager:
		run_active_value.text = "Yes" if GameManager.is_run_active else "No"
	
	# Run Time
	if run_time_value and GameManager:
		var run_time = GameManager.get_run_time()
		run_time_value.text = format_time(run_time)
	
	# Session Time
	if session_time_value and GameManager:
		var session_time = GameManager.get_session_time()
		session_time_value.text = format_time(session_time)

func update_seeds_rng() -> void:
	# Master Seed
	if master_seed_value and SeedManager:
		master_seed_value.text = str(SeedManager.get_master_seed())
	
	# Hash Seed
	if hash_seed_value and SeedManager:
		var hash_str = SeedManager.get_hash_seed_string()
		hash_seed_value.text = hash_str if !hash_str.is_empty() else "None"
	
	# Is Thematic
	if is_thematic_value and SeedManager:
		var hash_str = SeedManager.get_hash_seed_string()
		var is_thematic = SeedManager.is_thematic_seed(hash_str) if !hash_str.is_empty() else false
		is_thematic_value.text = "Yes" if is_thematic else "No"
	
	# Current RNG Stream
	if rng_stream_value and SeedManager:
		var stream = SeedManager.get_current_generator_name()
		rng_stream_value.text = stream if !stream.is_empty() else "None"

func update_player_data() -> void:
	# Character Class
	if character_class_value and GameManager:
		var char_class = GameManager.current_character_class
		character_class_value.text = char_class if !char_class.is_empty() else "None"
	
	# Character Name
	if character_name_value and GameManager:
		if GameManager.selected_character:
			var character_ref = GameManager.selected_character
			character_name_value.text = character_ref.full_name + " '" + character_ref.nickname + "'"
		else:
			character_name_value.text = "None"
	
	# Get player data from game_data
	var player_data = null
	if GameManager and GameManager.game_data.has("player"):
		player_data = GameManager.game_data["player"]
	
	# Health
	if health_value:
		if player_data and player_data.has("current_health"):
			health_value.text = "%d/%d" % [player_data.current_health, player_data.max_health]
		else:
			health_value.text = "---"
	
	# Energy
	if energy_value:
		if player_data and player_data.has("current_energy"):
			energy_value.text = "%d/%d" % [player_data.current_energy, player_data.max_energy]
		else:
			energy_value.text = "---"
	
	# Sanity
	if sanity_value:
		if player_data and player_data.has("current_sanity"):
			sanity_value.text = "%d/%d" % [player_data.current_sanity, player_data.max_sanity]
		else:
			sanity_value.text = "---"
	
	# Defense
	if defense_value:
		if player_data and player_data.has("defense"):
			defense_value.text = str(player_data.defense)
		else:
			defense_value.text = "0"
	
	# Gold
	if gold_value and GameManager:
		gold_value.text = str(GameManager.game_data.get("gold", 0))
	
	# Corruption
	if corruption_value and GameManager:
		corruption_value.text = str(GameManager.game_data.get("corruption", 0))

func update_curios() -> void:
	if not CurioManager:
		return
	
	# Update curios list
	if curios_list:
		# Clear existing labels
		for child in curios_list.get_children():
			child.queue_free()
		
		var active_curios = CurioManager.get_active_curios()
		
		if active_curios.is_empty():
			var label = Label.new()
			label.text = "No curios"
			label.modulate = Color.GRAY
			curios_list.add_child(label)
		else:
			for curio in active_curios:
				if not curio:
					continue
				
				var label = Label.new()
				var curio_name = curio.curio_name if curio.curio_name else "Unknown"
				var stack_count = CurioManager.get_curio_stack_count(curio_name)
				
				if stack_count > 1:
					label.text = "%s (x%d)" % [curio_name, stack_count]
				else:
					label.text = curio_name
				
				curios_list.add_child(label)
	
	# Update total count
	if curios_total_value:
		var count = CurioManager.get_active_curios().size()
		curios_total_value.text = str(count)

func update_run_statistics() -> void:
	if not GameManager:
		return
	
	var stats = GameManager.run_statistics
	
	if cards_played_value:
		cards_played_value.text = str(stats.get("cards_played", 0))
	
	if damage_dealt_value:
		damage_dealt_value.text = str(stats.get("damage_dealt", 0))
	
	if damage_taken_value:
		damage_taken_value.text = str(stats.get("damage_taken", 0))
	
	if enemies_defeated_value:
		enemies_defeated_value.text = str(stats.get("enemies_defeated", 0))
	
	if perfect_battles_value:
		perfect_battles_value.text = str(stats.get("perfect_battles", 0))
	
	if turns_taken_value:
		turns_taken_value.text = str(stats.get("turns_taken", 0))

func update_system_debug() -> void:
	# FPS
	if fps_value:
		fps_value.text = str(Engine.get_frames_per_second())
	
	# Memory Usage
	if memory_value:
		var memory_mb = OS.get_static_memory_usage() / (1024.0 * 1024.0)
		memory_value.text = "%.1f" % memory_mb
	
	# God Mode
	if god_mode_value:
		var debug_controller: DebugController = get_node_or_null("/root/DebugController") as DebugController
		if debug_controller:
			god_mode_value.text = "ON" if debug_controller.god_mode_enabled else "OFF"
		else:
			god_mode_value.text = "N/A"
	
	# Debug Mode
	if debug_mode_value:
		debug_mode_value.text = "ON" if OS.is_debug_build() else "OFF"
	
	# EventBus Signals
	if eventbus_signals_value and EventBus:
		# Count connected signals (simplified)
		eventbus_signals_value.text = "Active"
	
	# Active Modals
	if active_modals_value and ModalManager:
		var active_count := 0
		if ModalManager.has_method("is_modal_active") and ModalManager.is_modal_active():
			active_count = 1
		var queued_count := 0
		if ModalManager.has_method("get_queue_size"):
			queued_count = ModalManager.get_queue_size()
		# Show active modal count and queued for extra context
		active_modals_value.text = "%d (queued: %d)" % [active_count, queued_count]

func _ensure_encounter_ids_ui() -> void:
	# Create a simple titled, scrollable list under SystemDebug to show encountered IDs
	var system_debug := get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug")
	if system_debug == null:
		return

	# If already present, cache and exit
	var container := system_debug.get_node_or_null("EncounterIDs")
	if container:
		encountered_ids_title = container.get_node_or_null("Title") as Label
		var existing_scroll := container.get_node_or_null("EncounterIDsScroll")
		if existing_scroll:
			encountered_ids_list = existing_scroll.get_node_or_null("Value") as RichTextLabel
		return

	# Build UI dynamically
	container = VBoxContainer.new()
	container.name = "EncounterIDs"

	var title := Label.new()
	title.name = "Title"
	title.text = "Encounter IDs Seen (0)"
	container.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "EncounterIDsScroll"
	scroll.custom_minimum_size = Vector2(320, 120)

	var list := RichTextLabel.new()
	list.name = "Value"
	list.bbcode_enabled = false
	list.scroll_active = true
	list.fit_content = true

	scroll.add_child(list)
	container.add_child(scroll)
	system_debug.add_child(container)

	# Cache references
	encountered_ids_title = title
	encountered_ids_list = list

func _update_encounter_ids() -> void:
	# Update encounter IDs list and title count from EncounterManager
	if encountered_ids_list == null:
		_ensure_encounter_ids_ui()
	if encountered_ids_list == null:
		return

	var id_map: Dictionary = {}
	# Prefer autoload singleton if available
	if typeof(EncounterManager) != TYPE_NIL and EncounterManager:
		id_map = EncounterManager.encountered_ids if EncounterManager.encountered_ids else {}
	else:
		var mgr := get_node_or_null("/root/EncounterManager")
		if mgr:
			id_map = mgr.encountered_ids if mgr.encountered_ids else {}

	var keys := id_map.keys()
	keys.sort()
	var lines: Array[String] = []
	for k in keys:
		lines.append("%s: %s" % [str(k), str(id_map.get(k, 0))])

	var text := "(none)"
	if lines.size() > 0:
		text = "\n".join(lines)

	# RichTextLabel update
	encountered_ids_list.clear()
	encountered_ids_list.append_text(text)

	if encountered_ids_title:
		encountered_ids_title.text = "Encounter IDs Seen (%d)" % id_map.size()

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60.0)
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
