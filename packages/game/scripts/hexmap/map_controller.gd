class_name HexmapMapController
extends Node2D



@export var hex_grid_scene: PackedScene
@export var player_scene: PackedScene

var hex_grid: HexGrid
var hex_renderer: HexRenderer
var player: HexMapPlayer
var camera: Camera2D
var ui_layer: CanvasLayer
var generation_ui_panel
var last_preview_target: HexCoordinates = null
var hud_ui_panel

func _ready():
	set_process_input(true)
	set_process_unhandled_input(true)
	
	_setup_camera()
	_setup_hex_grid()
	_setup_player()
	_setup_input()
	_connect_signals()
	_setup_generation_ui()
	_setup_hud()
	_update_hud()
	
	# Force an initial render
	await get_tree().process_frame
	if hex_renderer:
		hex_renderer.queue_redraw()



func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_input(event)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse_click(event.position)
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_input(event)

func _handle_mouse_hover(screen_pos: Vector2):
	if not hex_grid or not player:
		return
	# Skip expensive hover work while moving
	if player.is_moving:
		if not show_reachable_area:
			hex_grid.clear_highlights()
		return
	
	# Convert screen to world coordinates
	var world_pos = _screen_to_world(screen_pos)
	
	# Convert to hex coordinates  
	var hex_coords = hex_grid.pixel_to_hex(world_pos)
	
	# Get tile
	var tile = hex_grid.get_tile(hex_coords)
	if tile and tile.is_explored:
		# Avoid re-calculating preview for the same target repeatedly
		if last_preview_target and last_preview_target.equals(hex_coords):
			return
		last_preview_target = hex_coords
		_show_path_preview(hex_coords)
	else:
		hex_grid.clear_highlights()
		last_preview_target = null

func _handle_mouse_click(screen_pos: Vector2):
	if not hex_grid or not player:
		return
	# Ignore clicks while moving
	if player.is_moving:
		return
	
	# Convert screen to world coordinates
	var world_pos = _screen_to_world(screen_pos)
	
	# Convert to hex coordinates  
	var hex_coords = hex_grid.pixel_to_hex(world_pos)
	
	# Check bounds using grid settings
	var settings = _get_map_settings()
	if hex_coords.q < settings.min_q or hex_coords.q >= settings.max_q or hex_coords.r < settings.min_r or hex_coords.r >= settings.max_r:
		return
	
	# Get tile
	var tile = hex_grid.get_tile(hex_coords)
	if tile and tile.is_explored:
		if player.can_move_to(hex_coords):
			var _success = player.request_move(hex_coords)

func _handle_keyboard_input(event: InputEventKey):
	if event.keycode == KEY_R:  # R key to toggle reachable area
		_toggle_reachable_area_display()
	elif event.keycode == KEY_SPACE:  # Space to reset movement points
		if player:
			player.reset_movement_points()
	elif event.keycode == KEY_V and event.shift_pressed:  # Shift+V to toggle reveal-all debug
		if hex_grid:
			hex_grid.set_reveal_all_debug(!hex_grid.reveal_all_debug)
			print("Reveal-all debug: ", "ON" if hex_grid.reveal_all_debug else "OFF")
			# Refresh visibility/rendering
			if player and not hex_grid.reveal_all_debug:
				hex_grid.update_visibility(player.current_hex, player.sight_range)
			if hex_renderer:
				hex_renderer.update_display()

var show_reachable_area: bool = false
var reachable_tiles_cache: Array[HexCoordinates] = []

func _toggle_reachable_area_display():
	show_reachable_area = !show_reachable_area
	print("Reachable area display: ", "ON" if show_reachable_area else "OFF")
	
	if show_reachable_area:
		_update_reachable_area_cache()
		_show_reachable_area()
	else:
		hex_grid.clear_highlights()

func _update_reachable_area_cache():
	if player:
		reachable_tiles_cache = player.get_reachable_tiles()
		print("Updated reachable area cache: ", reachable_tiles_cache.size(), " tiles")

func _show_reachable_area():
	if not hex_grid or reachable_tiles_cache.is_empty():
		return
	# Get tiles to highlight
	var tiles_to_highlight: Array[HexTile] = []
	for coord in reachable_tiles_cache:
		var tile = hex_grid.get_tile(coord)
		if tile:
			tiles_to_highlight.append(tile)
	# Highlight reachable area in bright green
	hex_grid.highlight_tiles(tiles_to_highlight, Color.LIME_GREEN)
	print("Showing reachable area: ", tiles_to_highlight.size(), " tiles highlighted")

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# Simple coordinate conversion using camera
	if camera:
		# Convert screen position to world coordinates
		var _viewport = get_viewport()
		return camera.get_global_mouse_position()
	return screen_pos

func _show_path_preview(target: HexCoordinates):
	if not player or player.is_moving:
		return
	# Calculate movement path
	var movement_path = player.calculate_movement_path_to(target)
	if not movement_path or not movement_path.is_valid:
		return
	# Visualize affordable vs unaffordable segments with distinct colors
	var affordable_color := Color.YELLOW
	var unaffordable_color := Color.ORANGE_RED
	hex_grid.clear_highlights()
	hex_grid.highlight_movement_path(movement_path, player.get_movement_points_remaining(), affordable_color, unaffordable_color)

func _setup_generation_ui():
	# Create a lightweight panel to tweak terrain gen and regenerate
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 50
	add_child(ui_layer)

	var GenerationPanelClass = load("res://scripts/hexmap/ui/GenerationPanel.gd")
	generation_ui_panel = GenerationPanelClass.new()
	ui_layer.add_child(generation_ui_panel)
	generation_ui_panel.build()

	# Initialize values
	var tg: TerrainGenerator = hex_grid.terrain_generator if hex_grid else null
	if tg and tg.map_generation_settings:
		generation_ui_panel.set_from_settings(tg.map_generation_settings, player.sight_range if player else 6, camera.zoom.x if camera else 1.0)

	# Wire events
	generation_ui_panel.regenerate_pressed.connect(func():
		_apply_generation_settings()
		if hex_grid and hex_grid.terrain_generator:
			hex_grid.terrain_generator.regenerate_with_new_settings(hex_grid)
			if hex_renderer:
				hex_renderer.update_display()
			if player:
				hex_grid.update_visibility(player.current_hex, player.sight_range)
			# Persist new map state after regeneration
			var _hexmap_state := get_node_or_null("/root/HexmapState")
			if _hexmap_state:
				_hexmap_state.call("save_from_scene", hex_grid, player)
	)

	generation_ui_panel.randomize_pressed.connect(func():
		if not hex_grid or not hex_grid.terrain_generator:
			return
		if hex_grid.terrain_generator.map_generation_settings:
			var s: MapGenerationSettings = hex_grid.terrain_generator.map_generation_settings
			if is_instance_valid(SeedManager) and SeedManager.is_run_active():
				s.elevation_seed = SeedManager.get_map_random_int(1, 0x7FFFFFFF)
				s.moisture_seed = SeedManager.get_map_random_int(1, 0x7FFFFFFF)
			else:
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				s.elevation_seed = rng.randi()
				s.moisture_seed = rng.randi()
		_apply_generation_settings()
		hex_grid.terrain_generator.regenerate_with_new_settings(hex_grid)
		if hex_renderer:
			hex_renderer.update_display()
		if player:
			hex_grid.update_visibility(player.current_hex, player.sight_range)
		# Persist new map state after randomize
		var _hexmap_state := get_node_or_null("/root/HexmapState")
		if _hexmap_state:
			_hexmap_state.call("save_from_scene", hex_grid, player)
	)

	generation_ui_panel.sight_range_changed.connect(func(v):
		if player and hex_grid:
			player.sight_range = int(v)
			hex_grid.update_visibility(player.current_hex, player.sight_range)
	)

	generation_ui_panel.camera_zoom_changed.connect(func(v):
		if camera:
			camera.zoom = Vector2(v, v)
	)

func _setup_camera():
	camera = Camera2D.new()
	camera.name = "MainCamera"
	# Start zoomed in a bit by default
	camera.zoom = Vector2(1.5, 1.5)
	camera.position = Vector2(0, 0)  # Start at origin
	camera.enabled = true
	add_child(camera)
	# Make camera current
	camera.make_current()

func _setup_hex_grid():
	hex_grid = HexGrid.new()
	hex_grid.name = "HexGrid"
	# Always prevent internal autogeneration; we'll control it explicitly
	hex_grid.autogenerate_on_ready = false
	add_child(hex_grid)
	
	hex_renderer = HexRenderer.new(hex_grid)
	hex_renderer.name = "HexRenderer"
	hex_grid.add_child(hex_renderer)
	
	print("HexGrid created with ", hex_grid.tiles.size(), " tiles")
	print("HexRenderer created with size: ", hex_renderer.hex_size)

	# Restore or generate via HexmapState
	var _hexmap_state := get_node_or_null("/root/HexmapState")
	if _hexmap_state and _hexmap_state.call("has_saved_map"):
		print("HexmapState: restoring saved map")
		_hexmap_state.call("apply_to_scene", hex_grid, null)
		if hex_renderer:
			hex_renderer.update_display()
	else:
		print("HexmapState: no saved map, generating new")
		# Apply deterministic seeds before first generation
		if hex_grid.terrain_generator and hex_grid.terrain_generator.map_generation_settings:
			var s: MapGenerationSettings = hex_grid.terrain_generator.map_generation_settings
			if is_instance_valid(SeedManager) and SeedManager.is_run_active():
				var base_seed := SeedManager.map_rng.seed
				if s.elevation_seed == 12345:
					s.elevation_seed = int((base_seed ^ 0xA5A5A5) & 0x7FFFFFFF)
				if s.moisture_seed == 67890:
					var _tmp = SeedManager.get_map_random_int(0, 0x7FFFFFFF)
					s.moisture_seed = int((base_seed ^ 0x5A5A5A ^ _tmp) & 0x7FFFFFFF)
				if hex_grid.terrain_generator.has_method("_setup_noise_generators"):
					hex_grid.terrain_generator._setup_noise_generators()
		# Manually generate world once
		hex_grid._generate_world()
		if hex_renderer:
			hex_renderer.update_display()

func _setup_player():
	player = HexMapPlayer.new()
	player.name = "Player"
	hex_grid.add_child(player)
	
	var _hexmap_state := get_node_or_null("/root/HexmapState")
	var start_pos = HexCoordinates.new(0, 0)
	var restored := false
	if _hexmap_state and _hexmap_state.call("has_saved_map"):
		# We'll let HexmapState set player state after initialization
		start_pos = HexCoordinates.new(0, 0)
		restored = true
	player.initialize(hex_grid, start_pos)
	if restored:
		_hexmap_state.call("apply_to_scene", hex_grid, player)
		if hex_renderer:
			hex_renderer.update_display()
	else:
		# First-time map entry: save initial state
		var _hexmap_state2 := get_node_or_null("/root/HexmapState")
		if _hexmap_state2:
			_hexmap_state2.call("save_from_scene", hex_grid, player)
	
	camera.position = player.position
	print("Player created at: ", player.position)
	print("Camera positioned at: ", camera.position)

func _setup_input():
	# Input is handled directly in _input() and _unhandled_input()
	pass

func _setup_hud():
	if not ui_layer:
		return
	# Create HUD panel showing time of day and MP
	var HudPanelClass = load("res://scripts/hexmap/ui/HudPanel.gd")
	hud_ui_panel = HudPanelClass.new()
	ui_layer.add_child(hud_ui_panel)
	hud_ui_panel.build()

	# Wire button actions
	hud_ui_panel.camp_pressed.connect(func():
		if not player or player.is_moving:
			return
		player.camp_full()
		if hex_renderer:
			hex_renderer.update_display()
		if hex_grid and player:
			hex_grid.update_visibility(player.current_hex, player.sight_range)
		_update_hud()
		if show_reachable_area:
			_update_reachable_area_cache()
			_show_reachable_area()
	)

	hud_ui_panel.short_rest_pressed.connect(func():
		if not player or player.is_moving:
			return
		player.short_rest()
		_update_hud()
		if show_reachable_area:
			_update_reachable_area_cache()
			_show_reachable_area()
	)

	hud_ui_panel.stimulant_pressed.connect(func():
		if not player or player.is_moving:
			return
		player.use_stimulant()
		_update_hud()
		if show_reachable_area:
			_update_reachable_area_cache()
			_show_reachable_area()
	)

func _update_hud():
	if not player or not hud_ui_panel:
		return
	var time_text := ""
	if player.game_time and player.game_time.has_method("get_time_string"):
		time_text = player.game_time.get_time_string()
	else:
		var hh := str(player.current_hour)
		if player.current_hour < 10:
			hh = "0" + hh
		time_text = "Time: %s:00" % [hh]
	var phase := player.get_time_phase_name() if player.has_method("get_time_phase_name") else ""
	if phase != "":
		time_text += " (" + phase + ")"
	hud_ui_panel.set_time_and_mp(time_text, "MP: %d/%d" % [player.get_movement_points_remaining(), player.max_movement_points])

# UI helper methods moved into GenerationPanel and HudPanel

func _apply_generation_settings():
	if not hex_grid or not hex_grid.terrain_generator:
		return
	var tg: TerrainGenerator = hex_grid.terrain_generator
	var s := tg.map_generation_settings
	if not s:
		# Fallback to default settings if missing
		s = load("res://data/hexmap/default_map_generation_settings.tres")
		tg.map_generation_settings = s
	# Pull values from GenerationPanel and apply
	if generation_ui_panel:
		var extras = generation_ui_panel.apply_to_settings(s)
		if player and "sight_range" in extras:
			player.sight_range = int(extras["sight_range"])
		if camera and "camera_zoom" in extras:
			var z = float(extras["camera_zoom"])
			camera.zoom = Vector2(z, z)

func _connect_signals():
	if player:
		player.moved.connect(_on_player_moved)
		player.movement_blocked.connect(_on_movement_blocked)
		player.movement_points_depleted.connect(_on_points_depleted)
		# HUD updates
		if player.has_signal("time_changed"):
			player.time_changed.connect(func(_hour): _update_hud())
		if player.has_signal("movement_points_changed"):
			player.movement_points_changed.connect(func(_c, _m): _update_hud())
	


func _on_player_moved(new_position: HexCoordinates):
	var target_pos = hex_grid.hex_to_pixel(new_position)
	var tween = create_tween()
	tween.tween_property(camera, "position", target_pos, 0.3)
	
	hex_renderer.update_display()
	
	# Minimal logging on move to avoid console pauses

	# After each move, update HUD and check if we are stuck (no affordable adjacent moves)
	_update_hud()
	_maybe_prompt_camp_if_stuck()

func _on_movement_blocked():
	print("Movement blocked!")
	# If we can't proceed and there are no affordable adjacent moves, prompt to camp
	_maybe_prompt_camp_if_stuck()

func _on_points_depleted():
	print("Movement points depleted - use HUD Camp button to restore")

func _maybe_prompt_camp_if_stuck():
	if not player or not hex_grid:
		return
	if player.is_moving:
		return
	var remaining := player.get_movement_points_remaining()
	# If out of points, normal depletion flow handles this
	if remaining <= 0:
		return
	# Inspect adjacent tiles for any affordable, passable move
	for neighbor in player.current_hex.get_all_neighbors():
		var t: HexTile = hex_grid.get_tile(neighbor)
		if t and t.can_move_to() and t.get_movement_cost() <= remaining:
			return
	# No affordable moves around; player is stuck but has points
	print("Player is stuck - use HUD Camp button to restore movement points")

func _on_hex_clicked(coords: HexCoordinates):
	var tile = hex_grid.get_tile(coords)
	if tile:
		print("Clicked: ", tile.get_terrain_name(), " at ", coords._to_string())

func _on_hex_hovered(_coords: HexCoordinates):
	pass

func _process(_delta):
	# Only update display when needed
	if hex_renderer and (player.is_moving or Input.is_action_just_pressed("ui_accept")):
		hex_renderer.update_display()

func _get_map_settings() -> MapGenerationSettings:
	if hex_grid and hex_grid.terrain_generator and hex_grid.terrain_generator.map_generation_settings:
		return hex_grid.terrain_generator.map_generation_settings
	# Fallback to default settings
	return load("res://data/hexmap/default_map_generation_settings.tres")
