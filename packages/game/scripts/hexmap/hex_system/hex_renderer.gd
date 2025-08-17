class_name HexRenderer
extends Node2D

var hex_grid: HexGrid
var hex_size: float = 32.0
var flat_top: bool = false

func _init(grid: HexGrid = null):
	if grid:
		hex_grid = grid
		hex_size = grid.hex_size
		flat_top = grid.flat_top

func _ready():
	queue_redraw()

func _draw():
	if not hex_grid or hex_grid.tiles.is_empty():
		return
	
	# Draw all visible tiles
	for key in hex_grid.tiles:
		var tile: HexTile = hex_grid.tiles[key]
		if tile.is_explored or tile.is_visible:
			_draw_hex_tile(tile)

func _draw_hex_tile(tile: HexTile):
	var center = tile.coordinates.to_pixel(hex_size, flat_top)
	var points = _get_hex_points(center)
	
	# Strictly use base_color for fill; don't darken/tint to ensure visuals match terrain data
	var color = Color.WHITE
	if tile.terrain_resource:
		color = tile.terrain_resource.base_color
	
	draw_colored_polygon(points, color)

	# Draw outlines for all terrains (including roads and creeks)
	var outline_color = Color.DARK_GRAY
	if tile.terrain_resource:
		# Use resource outline color; dim if not visible to hint fog without changing fill
		outline_color = tile.terrain_resource.outline_color
		if not tile.is_visible:
			outline_color = outline_color.darkened(0.4)
	
	for i in range(points.size()):
		var next_i = (i + 1) % points.size()
		draw_line(points[i], points[next_i], outline_color, 1.0)

	# Overlay: show encounters/resources with a simple marker so they're visible on the map
	if tile.has_encounter and tile.encounter_data:
		var kind: String = str(tile.encounter_data.get("resource", ""))
		var marker_color := Color(0.95, 0.85, 0.1, 1.0) if kind == "gold" else Color(0.9, 0.3, 0.3, 1.0)
		# Draw a small filled circle at the center
		draw_circle(center, max(2.0, hex_size * 0.15), Color.BLACK) # outline
		draw_circle(center, max(1.5, hex_size * 0.12), marker_color) # fill

func _get_hex_points(center: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_offset = 0.0 if flat_top else PI / 6.0
	
	for i in range(6):
		var angle = angle_offset + i * PI / 3.0
		var point = center + Vector2(
			hex_size * cos(angle),
			hex_size * sin(angle)
		)
		points.append(point)
	
	return points

func _get_hex_points_scaled(center: Vector2, radius_scale: float) -> PackedVector2Array:
	var points = PackedVector2Array()
	var angle_offset = 0.0 if flat_top else PI / 6.0
	var radius = hex_size * radius_scale
	for i in range(6):
		var angle = angle_offset + i * PI / 3.0
		var point = center + Vector2(
			radius * cos(angle),
			radius * sin(angle)
		)
		points.append(point)
	return points

func update_display():
	queue_redraw()
