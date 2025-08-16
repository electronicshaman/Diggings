extends Node

# Legacy stub: the old MapNodeRegistry has been removed with the legacy map system.
# This no-op version remains only to avoid parser errors in existing files.

signal configs_loaded()

var node_configs := {}
var type_defaults := {}
var random_pools := {}

func _ready():
	print("MapNodeRegistry disabled: legacy map system removed.")
	emit_signal("configs_loaded")

func load_all_configs():
	node_configs.clear()
	type_defaults.clear()
	random_pools.clear()
	emit_signal("configs_loaded")

func get_config(_config_path: String):
	return null

func get_default_config_for_type(_node_type: int):
	return null

func get_random_config_for_type(_node_type: int):
	return null

func get_random_config_for_category(_category: String):
	return null

func create_node(_node_id: String, _config_or_path, _position: Vector2 = Vector2.ZERO):
	return null

func create_node_with_random_config(_node_id: String, _node_type: int, _position: Vector2 = Vector2.ZERO):
	return null

func get_all_configs_for_type(_node_type: int) -> Array:
	return []

func get_config_count() -> int:
	return 0

func has_config(_config_path: String) -> bool:
	return false

func reload_configs():
	load_all_configs()

