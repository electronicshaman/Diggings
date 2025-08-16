extends Node

var region_id: StringName = &""
var tiles: Dictionary = {}
var player_q: int = 0
var player_r: int = 0
var player_mp: int = 0
var hour: int = 6
var rng_state: Dictionary = {}

func clear():
	region_id = &""
	tiles = {}
	player_q = 0
	player_r = 0
	player_mp = 0
	hour = 6
	rng_state = {}

func begin_new_map(selected_region: StringName) -> void:
	clear()
	region_id = selected_region

func has_saved_map() -> bool:
	return not tiles.is_empty()

func save_from_scene(hex_grid: HexGrid, player: HexMapPlayer) -> void:
	if not is_instance_valid(hex_grid) or not is_instance_valid(player):
		return
	tiles = hex_grid.save_grid()
	player_q = player.current_hex.q
	player_r = player.current_hex.r
	player_mp = player.current_movement_points
	hour = player.current_hour
	if is_instance_valid(SeedManager) and SeedManager.has_method("get_rng_state"):
		rng_state = SeedManager.get_rng_state()

func apply_to_scene(hex_grid: HexGrid, player: HexMapPlayer) -> void:
	if tiles.is_empty():
		return
	if is_instance_valid(SeedManager) and rng_state and SeedManager.has_method("set_rng_state"):
		SeedManager.set_rng_state(rng_state)
	hex_grid.load_grid(tiles)
	if player and player.current_hex:
		player.current_hex.q = player_q
		player.current_hex.r = player_r
		player.position = hex_grid.hex_to_pixel(player.current_hex)
		player.current_movement_points = player_mp
		player.current_hour = hour
		hex_grid.update_visibility(player.current_hex, player.sight_range)
		player.movement_points_changed.emit(player.current_movement_points, player.max_movement_points)
		player.time_changed.emit(player.current_hour)
