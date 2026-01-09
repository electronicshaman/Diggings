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

var encountered_ids_title: Label
var encountered_ids_list: RichTextLabel

# Deck section
var deck_list: VBoxContainer
var deck_total_value: Label
var deck_composition_value: Label
var hand_count_value: Label
var discard_count_value: Label
var removed_count_value: Label

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
	update_timer.wait_time = 0.5 # Update twice per second
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


	# Cache Encounter IDs UI references from scene
	encountered_ids_title = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/EncounterIDs/Title")
	encountered_ids_list = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/SystemDebug/EncounterIDs/EncounterIDsScroll/Value")
	
	# Cache Deck UI references from scene
	deck_total_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/TotalCount/Value")
	deck_composition_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/Composition/Value")
	hand_count_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/HandCount/Value")
	discard_count_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/DiscardCount/Value")
	removed_count_value = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/RemovedCount/Value")
	deck_list = get_node_or_null("CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Deck/DeckScroll/DeckList")

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
			_update_all_data() # Force update when showing
			GLog.debug("Debug HUD shown")
		else:
			GLog.debug("Debug HUD hidden")
		return

	# Fallback to Node2D visibility if container missing
	visible = !visible
	if visible:
		_update_all_data() # Force update when showing
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
	update_deck_info()

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
	

func update_deck_info() -> void:
	# Only show deck info if DeckManager is available and we're in a duel or deck is loaded
	if not is_instance_valid(DeckManager):
		return
	
	# Update persistent deck info (always available if deck loaded)
	if DeckManager.is_deck_available():
		if deck_total_value:
			deck_total_value.text = str(DeckManager.get_deck_size())
		
		if deck_composition_value:
			var composition = DeckManager.get_deck_composition()
			var comp_text = ""
			for category in composition:
				if comp_text != "":
					comp_text += ", "
				comp_text += "%s: %d" % [category, composition[category]]
			deck_composition_value.text = comp_text if comp_text != "" else "Empty"
		
		# Update deck list with card names
		if deck_list:
			# Clear existing labels
			for child in deck_list.get_children():
				child.queue_free()
			
			var deck = DeckManager.get_current_deck()
			
			if deck.is_empty():
				var label = Label.new()
				label.text = "No deck loaded"
				label.modulate = Color.GRAY
				deck_list.add_child(label)
			else:
				# Group cards by name and show counts
				var card_counts = {}
				for card in deck:
					if is_instance_valid(card):
						var card_name_str = card.card_name
						if card_counts.has(card_name_str):
							card_counts[card_name_str] += 1
						else:
							card_counts[card_name_str] = 1
				
				# Sort and display
				var names = card_counts.keys()
				names.sort()
				for card_name in names:
					var label = Label.new()
					var count = card_counts[card_name]
					label.text = "%s (x%d)" % [card_name, count] if count > 1 else card_name
					deck_list.add_child(label)
	else:
		# No deck loaded
		if deck_total_value:
			deck_total_value.text = "0"
		if deck_composition_value:
			deck_composition_value.text = "No deck loaded"
		if deck_list:
			for child in deck_list.get_children():
				child.queue_free()
			var label = Label.new()
			label.text = "No deck loaded"
			label.modulate = Color.GRAY
			deck_list.add_child(label)
	
	# Update duel-specific counts (only when in duel)
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name.contains("duel"):
		# Try to get duel manager from the current scene
		var duel_manager = current_scene.get_node_or_null("DuelManager")
		if not duel_manager:
			duel_manager = current_scene.find_child("DuelManager", true, false)
		
		if is_instance_valid(duel_manager):
			if hand_count_value:
				var hand_count = 0
				if duel_manager.has_method("get_hand_cards"):
					hand_count = duel_manager.get_hand_cards().size()
				hand_count_value.text = str(hand_count)
			
			if discard_count_value:
				var discard_count = 0
				if duel_manager.has_method("get_discard_count"):
					discard_count = duel_manager.get_discard_count()
				discard_count_value.text = str(discard_count)
			
			if removed_count_value:
				# Try to get removed pile count if available
				removed_count_value.text = "0" # Placeholder for now
		else:
			# Not in duel scene - clear duel-specific info
			if hand_count_value:
				hand_count_value.text = "---"
			if discard_count_value:
				discard_count_value.text = "---"
			if removed_count_value:
				removed_count_value.text = "---"
	else:
		# Not in duel scene
		if hand_count_value:
			hand_count_value.text = "---"
		if discard_count_value:
			discard_count_value.text = "---"
		if removed_count_value:
			removed_count_value.text = "---"


func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60.0)
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]
