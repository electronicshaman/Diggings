class_name HexMapPlayer
extends Node2D

signal moved(new_position: HexCoordinates)
signal movement_blocked()
signal movement_points_depleted()
signal time_changed(current_hour: int) # Deprecated: retained for HUD compatibility
signal movement_points_changed(current: int, max_val: int)

@export var game_settings: Resource
@export var game_time: GameTime

# Cached settings for performance
var max_movement_points: int = 20
var sight_range: int = 7
var move_speed: float = 200.0
var start_hour: int = 6
var prohibit_night_movement: bool = false
var guide_active: bool = false
var guide_reduction: int = 1

var current_hour: int = 6  # kept in sync with game_time for backward compatibility
var stimulant_crash_in_hours: int = -1
var stimulant_crash_amount: int = 0

var current_movement_points: int

var current_hex: HexCoordinates
var hex_grid: HexGrid
var is_moving: bool = false
var move_path: Array[HexCoordinates] = []
var encounter_in_progress: bool = false

# Chance for a random non-tile event to occur on each movement step (0.0 - 1.0)
@export var random_event_chance_per_step: float = 0.08

var initialized: bool = false

func _ready():
	_load_settings()
	# Only set defaults if not initialized via initialize()
	if not initialized:
		current_hex = HexCoordinates.new(0, 0)
		current_movement_points = max_movement_points
	# Initialize game_time if not provided
	if not game_time:
		game_time = GameTime.new()
		game_time.year = 1850
		game_time.month = 1
		game_time.day = 1
		game_time.hour = start_hour % 24
	current_hour = game_time.hour
	game_time.time_changed.connect(func(_y,_m,_d,h):
		current_hour = h
		time_changed.emit(current_hour)
	)
	if get_parent() is HexGrid:
		hex_grid = get_parent()
		# Only apply default placement if not already initialized
		if not initialized:
			position = hex_grid.hex_to_pixel(current_hex)
			hex_grid.update_visibility(current_hex, sight_range)
	# If we are reloaded into a restored map, clear encounter gate for fresh triggers
	encounter_in_progress = false

func initialize(grid: HexGrid, start_position: HexCoordinates):
	_load_settings()
	hex_grid = grid
	current_hex = start_position
	current_movement_points = max_movement_points
	if not game_time:
		game_time = GameTime.new()
		game_time.year = 1850
		game_time.month = 1
		game_time.day = 1
		game_time.hour = start_hour % 24
	current_hour = game_time.hour
	position = hex_grid.hex_to_pixel(current_hex)
	hex_grid.update_visibility(current_hex, sight_range)
	time_changed.emit(current_hour)
	movement_points_changed.emit(current_movement_points, max_movement_points)
	initialized = true

func _load_settings():
	if not game_settings:
		game_settings = load("res://data/hexmap/default_game_settings.tres")
		print("HexMapPlayer: Loaded default game settings")
	
	if game_settings:
		max_movement_points = game_settings.max_movement_points
		sight_range = game_settings.sight_range
		move_speed = game_settings.move_speed
		start_hour = game_settings.start_hour
		prohibit_night_movement = game_settings.prohibit_night_movement
		guide_active = game_settings.guide_active
		guide_reduction = game_settings.guide_cost_reduction

func can_move_to(target: HexCoordinates) -> bool:
	if is_moving:
		return false
	# Don't allow requesting a move to the current position
	if current_hex and target and current_hex.equals(target):
		return false
	# Prohibit movement at night if configured
	if prohibit_night_movement and _is_night():
		return false
	
	# Calculate path and cost to target
	var movement_path = calculate_movement_path_to(target)
	if not movement_path.is_valid:
		return false
	
	if not movement_path.can_afford(current_movement_points):
		return false
	
	var target_tile = hex_grid.get_tile(target)
	if not target_tile or not target_tile.can_move_to():
		return false

	return true

func calculate_movement_path_to(target: HexCoordinates) -> Resource:
	var movement_path_class = load("res://scripts/hexmap/hex_system/movement_path.gd")
	if not hex_grid:
		return movement_path_class.new()

	# Use pathfinding to get route with costs
	var prefer_roads = false
	var current_tile = hex_grid.get_tile(current_hex)
	if current_tile and current_tile.terrain_resource and current_tile.terrain_resource.is_road:
		prefer_roads = true
	var path_coords = hex_grid.find_path_to(current_hex, target, prefer_roads)
	var mp: Resource = movement_path_class.from_pathfinding_result(path_coords, hex_grid)
	# Approximate preview: apply current time-of-day modifier and guide reduction uniformly per step
	if mp and mp.is_valid and mp.get_length() > 1:
		var mod := _time_of_day_modifier()
		var adj_individual: Array[int] = []
		var adj_cumulative: Array[int] = []
		var running := 0
		for i in range(1, mp.get_length()):
			var coord: HexCoordinates = mp.coordinates[i]
			var tile := hex_grid.get_tile(coord)
			var base_cost: int = tile.get_movement_cost() if tile else 1
			var reduction_val: int = guide_reduction if guide_active else 0
			var eff: int = max(1, base_cost + mod - reduction_val)
			adj_individual.append(eff)
			running += eff
			adj_cumulative.append(running)
		mp.individual_costs = adj_individual
		mp.cumulative_costs = adj_cumulative
		mp.total_cost = running
	return mp

func get_reachable_tiles() -> Array[HexCoordinates]:
	# Use HexGrid's efficient reachable tiles calculation
	if not hex_grid:
		return []
	
	return hex_grid.find_reachable_tiles(current_hex, current_movement_points)

func consume_movement_points(cost: int):
	current_movement_points -= cost
	print("Consumed ", cost, " MP. Remaining: ", current_movement_points, "/", max_movement_points)
	# Advance time by 1 hour per movement point consumed
	_advance_time(cost)
	movement_points_changed.emit(current_movement_points, max_movement_points)

func reset_movement_points():
	current_movement_points = max_movement_points
	print("Movement points reset to: ", current_movement_points)
	movement_points_changed.emit(current_movement_points, max_movement_points)

func get_movement_points_remaining() -> int:
	return current_movement_points

func request_move(target: HexCoordinates) -> bool:
	# Calculate movement cost before validation
	var movement_path = calculate_movement_path_to(target)
	
	if not can_move_to(target):
		movement_blocked.emit()
		return false

	_move_along_path(movement_path)
	return true

func move_to(target: HexCoordinates, movement_cost: int = 0):
	print("=== HEXMAPPLAYER move_to called with target: ", target._to_string(), " cost: ", movement_cost, " ===")
	
	if is_moving:
		print("Already moving, ignoring move request")
		return
	
	var tile = hex_grid.get_tile(target)
	if not tile or not tile.can_move_to():
		print("Cannot move to target: no tile or blocked")
		movement_blocked.emit()
		return
	
	# Consume movement points before starting movement
	if movement_cost > 0:
		consume_movement_points(movement_cost)
	
	print("Starting move from ", current_hex._to_string(), " to ", target._to_string())
	is_moving = true
	
	var target_pos = hex_grid.hex_to_pixel(target)
	print("Moving from pixel position ", position, " to ", target_pos)
	
	print("Creating tween for movement animation")
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.3)
	tween.tween_callback(func(): _on_move_complete(target))
	print("Tween created and started")
	
	# Failsafe timeout in case tween fails
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_moving:
			print("Movement timeout, forcing completion")
			_on_move_complete(target)
	)

func _on_move_complete(target: HexCoordinates):
	print("=== HEXMAPPLAYER _on_move_complete called with target: ", target._to_string(), " ===")
	is_moving = false
	current_hex = target  # Ensure current_hex is updated
	hex_grid.update_visibility(current_hex, sight_range)
	moved.emit(current_hex)
	print("Move completed to: ", current_hex._to_string(), " at position: ", position)
	
	var tile = hex_grid.get_tile(current_hex)
	if tile and tile.has_encounter:
		_trigger_encounter(tile)
	else:
		# Consider a lightweight random event on arrival if no fixed encounter
		_maybe_trigger_random_event()

	# If movement points are fully spent, notify
	if current_movement_points <= 0:
		movement_points_depleted.emit()
	
	print("=== HEXMAPPLAYER movement fully completed ===")

# New: Move step-by-step along a MovementPath
func _move_along_path(movement_path: Resource):
	if is_moving:
		print("Already moving, ignoring _move_along_path request")
		return
	if not movement_path or not movement_path.is_valid or movement_path.get_length() <= 1:
		print("No steps to move or invalid path")
		movement_blocked.emit()
		return

	is_moving = true
	move_path = movement_path.coordinates.duplicate()
	# Start from the first step after current position
	_move_step(1)

func _move_step(step_index: int):
	if step_index >= move_path.size():
		print("Completed all steps in path")
		is_moving = false
		if current_movement_points <= 0:
			movement_points_depleted.emit()
		return

	var next_hex: HexCoordinates = move_path[step_index]
	var tile := hex_grid.get_tile(next_hex)
	if not tile or not tile.can_move_to():
		print("Blocked step at ", next_hex._to_string())
		is_moving = false
		movement_blocked.emit()
		return

	# Compute effective step cost with time-of-day modifiers and guide
	if prohibit_night_movement and _is_night():
		print("Night movement prohibited")
		is_moving = false
		movement_blocked.emit()
		return
	var base_cost: int = tile.get_movement_cost()
	var eff_mod: int = _time_of_day_modifier()
	var reduction: int = guide_reduction if guide_active else 0
	var step_cost: int = max(1, base_cost + eff_mod - reduction)
	if current_movement_points < step_cost:
		print("Insufficient points for next step: need ", step_cost, ", have ", current_movement_points)
		is_moving = false
		movement_blocked.emit()
		return

	# Consume cost per step
	consume_movement_points(step_cost)

	var target_pos = hex_grid.hex_to_pixel(next_hex)
	var distance = position.distance_to(target_pos)
	var duration = max(0.05, distance / move_speed)

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)
	tween.tween_callback(func():
		# Update state at tile arrival
		current_hex = next_hex
		hex_grid.update_visibility(current_hex, sight_range)
		moved.emit(current_hex)
		# Handle encounter per step
		var arrived_tile = hex_grid.get_tile(current_hex)
		if arrived_tile and arrived_tile.has_encounter:
			_trigger_encounter(arrived_tile)
			# Stop path progression if an encounter has begun
			return
		# If no fixed encounter, maybe roll for a random event this step
		if _maybe_trigger_random_event():
			# Random event triggered; stop path progression
			return
		# If we've spent all movement points, and no further steps, notify; otherwise continue
		if current_movement_points <= 0 and step_index + 1 >= move_path.size():
			movement_points_depleted.emit()
		# Continue to next step
		_move_step(step_index + 1)
	)

	# Failsafe: if tween fails, force next step after a short delay
	get_tree().create_timer(max(0.5, duration * 2.0)).timeout.connect(func():
		if is_moving and current_hex != next_hex:
			print("Tween fallback triggered for step to ", next_hex._to_string())
			position = target_pos
			current_hex = next_hex
			hex_grid.update_visibility(current_hex, sight_range)
			moved.emit(current_hex)
			_move_step(step_index + 1)
	)

func _trigger_encounter(tile: HexTile):
	if encounter_in_progress:
		return
	encounter_in_progress = true

	print("Encounter triggered at ", tile.coordinates._to_string())
	# Mark tile so we don't immediately re-trigger on return
	tile.has_encounter = false

	# Persist map and player state before leaving the scene
	_save_map_and_player_state()

	# Route ALL encounters through EncounterManager for unified flow
	var encounter_manager = get_node_or_null("/root/EncounterManager")
	if encounter_manager:
		# Use EncounterManager to create EncounterInstance from tile
		var encounter_instance = encounter_manager.trigger_from_context({"tile": tile})
		if encounter_instance:
			print("EncounterManager created instance: ", encounter_instance.get_encounter_name())
			_start_event({"encounter_instance": encounter_instance, "tile": tile})
		else:
			print("EncounterManager could not create encounter from tile")
			_start_fallback_encounter()
	else:
		print("EncounterManager not found, using fallback")
		_start_fallback_encounter()

func _start_fallback_encounter():
	"""Fallback when EncounterManager is unavailable"""
	# Decide encounter type from tile data; fallback to duel
	var enc_data: Dictionary = {}
	var enc_type := "duel"  # Default fallback
	
	if enc_type == "event":
		_start_event(enc_data)
	else:
		_start_duel(enc_data)

func _maybe_trigger_random_event() -> bool:
	# Only consider random events if not in an encounter and chance passes
	if encounter_in_progress:
		return false
	if random_event_chance_per_step <= 0.0:
		return false
	var roll := SeedManager.get_event_random_float() if is_instance_valid(SeedManager) else randf()
	if roll <= clampf(random_event_chance_per_step, 0.0, 1.0):
		encounter_in_progress = true
		print("Random event triggered (roll=", roll, ") at ", current_hex._to_string())
		_save_map_and_player_state()
		
		# Use EncounterManager to trigger terrain-appropriate encounter
		var terrain_name = ""
		var tile = hex_grid.get_tile(current_hex) if hex_grid else null
		if tile and tile.terrain_resource:
			terrain_name = tile.terrain_resource.terrain_name.to_lower()
		
		var encounter_manager = get_node_or_null("/root/EncounterManager")
		if encounter_manager and encounter_manager.has_method("trigger_random_event"):
			var encounter_instance = encounter_manager.trigger_random_event(terrain_name)
			if encounter_instance:
				print("EncounterManager triggered: ", encounter_instance.get_encounter_name())
				_start_event({"terrain": terrain_name, "encounter_instance": encounter_instance})
			else:
				print("EncounterManager found no suitable encounters for terrain: ", terrain_name)
				_start_event({"random": true, "terrain": terrain_name})
		else:
			# Fallback to basic event if EncounterManager unavailable
			_start_event({"random": true, "terrain": terrain_name})
		return true
	return false

func _start_duel(_encounter_context: Dictionary = {}):
	is_moving = false
	# Transition to duel scene; the duel scene will bootstrap a test duel
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
		SceneManager.load_scene_by_name("duel")
	else:
		push_warning("HexMapPlayer: SceneManager unavailable; cannot start duel")

func _start_event(_encounter_context: Dictionary = {}):
	is_moving = false
	# Increment event statistic if available
	if is_instance_valid(GameManager) and GameManager.has_method("increment_statistic"):
		GameManager.increment_statistic("events_encountered", 1)
	
	# Check if we have an encounter instance to preview
	if _encounter_context.has("encounter_instance") and _encounter_context.encounter_instance:
		var encounter_instance = _encounter_context.encounter_instance
		print("Showing encounter preview for: ", encounter_instance.get_encounter_name())
		
		# Store encounter context for after modal
		var stored_context = _encounter_context.duplicate()
		
		# Show encounter preview modal
		var modal_manager = get_node_or_null("/root/ModalManager")
		if modal_manager:
			# Connect to modal result before showing
			if not EventBus.is_connected("modal_closed", Callable(self, "_on_encounter_modal_closed")):
				EventBus.connect_safe("modal_closed", Callable(self, "_on_encounter_modal_closed"))
			
			# Store context for later use
			set_meta("pending_encounter_context", stored_context)
			
			# Show the modal
			modal_manager.show_encounter_preview(encounter_instance)
		else:
			print("ModalManager not found, proceeding directly to event")
			_proceed_to_event_scene()
	else:
		# No encounter instance - this should not happen with unified flow
		print("Warning: _start_event called without encounter_instance in unified flow")
		_proceed_to_event_scene()

func _proceed_to_event_scene():
	"""Proceed directly to the event scene"""
	if is_instance_valid(SceneManager) and SceneManager.has_method("load_scene_by_name"):
		SceneManager.load_scene_by_name("event")
	else:
		push_warning("HexMapPlayer: SceneManager unavailable; cannot start event")

func _on_encounter_modal_closed(modal_type: String, result: Variant):
	"""Handle encounter preview modal result"""
	if modal_type != "encounter_preview":
		return
	
	# Disconnect the signal to avoid duplicate calls
	if EventBus.is_connected("modal_closed", Callable(self, "_on_encounter_modal_closed")):
		EventBus.disconnect("modal_closed", Callable(self, "_on_encounter_modal_closed"))
	
	print("Encounter modal closed with result: ", str(result))
	
	if result == "enter":
		# Player chose to enter the encounter
		print("Player entered encounter, proceeding to event scene")
		_proceed_to_event_scene()
	elif result == "retreat":
		# Player chose to retreat
		print("Player retreated from encounter")
		encounter_in_progress = false
		# Player stays on current tile, encounter is avoided
	else:
		# Unknown result, default to retreat for safety
		print("Unknown modal result, treating as retreat")
		encounter_in_progress = false

func _save_map_and_player_state():
	if not is_instance_valid(hex_grid):
		return
	var _hexmap_state := get_node_or_null("/root/HexmapState")
	if _hexmap_state:
		_hexmap_state.call("save_from_scene", hex_grid, self)
	# Optional: autosave on encounter
	if is_instance_valid(SaveSystem) and SaveSystem.autosave_enabled:
		SaveSystem.save_game(SaveSystem.AUTOSAVE_PATH, true)

# ==== Time-of-day and recovery mechanics ====

func _advance_time(hours: int):
	if hours <= 0:
		return
	if game_time:
		game_time.advance_hours(hours)
		current_hour = game_time.hour
	else:
		current_hour = (current_hour + hours) % 24
	# Handle stimulant crash countdown
	if stimulant_crash_in_hours > 0:
		stimulant_crash_in_hours -= hours
		if stimulant_crash_in_hours <= 0 and stimulant_crash_amount > 0:
			print("Stimulant crash: -", stimulant_crash_amount, " MP")
			current_movement_points = max(0, current_movement_points - stimulant_crash_amount)
			stimulant_crash_amount = 0
			stimulant_crash_in_hours = -1
			movement_points_changed.emit(current_movement_points, max_movement_points)
	# Notify listeners
	time_changed.emit(current_hour)

func _time_of_day_modifier() -> int:
	if game_settings:
		return game_settings.get_movement_modifier(current_hour)
	# Fallback: Day: 0, Dawn/Dusk: +1, Night: +2
	if _is_night():
		return 2
	elif _is_dawn() or _is_dusk():
		return 1
	return 0

func _is_dawn() -> bool:
	if game_settings:
		return current_hour >= game_settings.dawn_start_hour and current_hour < game_settings.dawn_end_hour
	return game_time and game_time.is_dawn() or (current_hour >= 5 and current_hour < 7)

func _is_day() -> bool:
	if game_settings:
		return current_hour >= game_settings.day_start_hour and current_hour < game_settings.day_end_hour
	return current_hour >= 7 and current_hour < 18

func _is_dusk() -> bool:
	if game_settings:
		return current_hour >= game_settings.dusk_start_hour and current_hour < game_settings.dusk_end_hour
	return game_time and game_time.is_dusk() or (current_hour >= 18 and current_hour < 20)

func _is_night() -> bool:
	if game_settings:
		var phase = game_settings.get_time_phase(current_hour)
		return phase == "Night"
	return game_time and game_time.is_night() or (current_hour >= 20 or current_hour < 5)

func get_time_phase_name() -> String:
	if game_settings:
		return game_settings.get_time_phase(current_hour)
	# Fallback
	if _is_night():
		return "Night"
	if _is_dusk():
		return "Dusk"
	if _is_dawn():
		return "Dawn"
	return "Day"

func camp_full():
	# Determine if current tile is a safe camping spot (e.g., Town)
	var safe := false
	if hex_grid:
		var tile := hex_grid.get_tile(current_hex)
		safe = tile and tile.terrain_resource and tile.terrain_resource.is_settlement
	
	var safe_full_recovery = true
	var success_chance = 0.6
	var min_rec = 2
	var max_rec = 5
	
	if game_settings:
		safe_full_recovery = game_settings.safe_camp_full_recovery
		success_chance = game_settings.wilderness_camp_success_chance
		min_rec = game_settings.wilderness_camp_min_recovery
		max_rec = game_settings.wilderness_camp_max_recovery
	
	if safe and safe_full_recovery:
		# Advance to next 6am and restore full MP
		var to_morning := (24 + 6 - current_hour) % 24
		if to_morning == 0:
			to_morning = 24
		_advance_time(to_morning)
		reset_movement_points()
	else:
		# Wilderness risk
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		if rng.randf() < success_chance:
			var to_morning2 := (24 + 6 - current_hour) % 24
			if to_morning2 == 0:
				to_morning2 = 24
			_advance_time(to_morning2)
			reset_movement_points()
		else:
			# Interrupted: still reaches morning, but recovery is partial
			var to_morning3 := (24 + 6 - current_hour) % 24
			if to_morning3 == 0:
				to_morning3 = 24
			_advance_time(to_morning3)
			var rec := rng.randi_range(min_rec, max_rec)
			current_movement_points = min(max_movement_points, current_movement_points + rec)
			movement_points_changed.emit(current_movement_points, max_movement_points)

func short_rest():
	var rest_hours = 2
	var min_rec = 2
	var max_rec = 3
	
	if game_settings:
		rest_hours = game_settings.short_rest_hours
		min_rec = game_settings.short_rest_min_recovery
		max_rec = game_settings.short_rest_max_recovery
	
	_advance_time(rest_hours)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rec := rng.randi_range(min_rec, max_rec)
	current_movement_points = min(max_movement_points, current_movement_points + rec)
	movement_points_changed.emit(current_movement_points, max_movement_points)

func use_stimulant():
	var min_bonus = 2
	var max_bonus = 3
	var crash_hours = 6
	
	if game_settings:
		min_bonus = game_settings.stimulant_min_bonus
		max_bonus = game_settings.stimulant_max_bonus
		crash_hours = game_settings.stimulant_crash_hours
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var bonus := rng.randi_range(min_bonus, max_bonus)
	current_movement_points = min(max_movement_points, current_movement_points + bonus)
	stimulant_crash_amount = bonus
	stimulant_crash_in_hours = crash_hours
	movement_points_changed.emit(current_movement_points, max_movement_points)

func get_valid_moves() -> Array[HexCoordinates]:
	var valid_moves: Array[HexCoordinates] = []
	var neighbors = current_hex.get_all_neighbors()
	
	for neighbor in neighbors:
		if can_move_to(neighbor):
			valid_moves.append(neighbor)
	
	return valid_moves

func highlight_valid_moves():
	if not hex_grid:
		return
	
	var valid_moves = get_valid_moves()
	var tiles_to_highlight: Array[HexTile] = []
	
	for coord in valid_moves:
		var tile = hex_grid.get_tile(coord)
		if tile:
			tiles_to_highlight.append(tile)
	
	hex_grid.highlight_tiles(tiles_to_highlight, Color.GREEN)

func clear_move_highlights():
	if hex_grid:
		hex_grid.clear_highlights()

func _draw():
	draw_circle(Vector2.ZERO, 16, Color.RED)
	draw_circle(Vector2.ZERO, 12, Color.WHITE)
	draw_circle(Vector2.ZERO, 8, Color.BLUE)
