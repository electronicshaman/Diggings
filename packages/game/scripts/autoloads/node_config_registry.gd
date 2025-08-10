extends Node

const DEBUG_ENABLED: bool = true

var node_configs: Dictionary = {}
var type_defaults: Dictionary = {}
var random_pools: Dictionary = {}

signal configs_loaded()
signal config_registered(config_path: String)

func _ready():
	GLog.debug("MapNodeRegistry initializing...")
	load_all_configs()

func load_all_configs():
	var base_path = "res://data/map_nodes/"
	var categories = ["cities", "camps", "mines", "settlements", "pois", "junctions", "bosses"]
	
	for category in categories:
		var dir_path = base_path + category + "/"
		_load_configs_from_directory(dir_path, category)
	
	GLog.debug("MapNodeRegistry loaded " + str(node_configs.size()) + " node configurations")
	
	_validate_defaults()
	configs_loaded.emit()

func _load_configs_from_directory(dir_path: String, category: String):
	var dir = DirAccess.open(dir_path)
	if not dir:
		GLog.debug("MapNodeRegistry: Directory not found: " + dir_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = dir_path + file_name
			var config = load(full_path) as NodeConfig
			
			if config:
				var key = full_path.replace("res://", "")
				node_configs[key] = config
				
				if not random_pools.has(category):
					random_pools[category] = []
				random_pools[category].append(key)
				
				if file_name == "default.tres":
					var node_type = _category_to_node_type(category)
					type_defaults[node_type] = key
				
				GLog.debug("Loaded node config: " + key)
				config_registered.emit(key)
			else:
				GLog.warn("Failed to load node config: " + full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _category_to_node_type(category: String) -> int:
	match category:
		"cities": return 0  # MapNode.NodeType.CITY
		"camps": return 1   # MapNode.NodeType.CAMP
		"mines": return 2   # MapNode.NodeType.MINE
		"settlements": return 3  # MapNode.NodeType.SETTLEMENT
		"pois": return 4    # MapNode.NodeType.POI
		"junctions": return 5  # MapNode.NodeType.JUNCTION
		"bosses": return 6  # MapNode.NodeType.BOSS
		_: return 5  # Default to JUNCTION

func _node_type_to_category(node_type: int) -> String:
	match node_type:
		0: return "cities"
		1: return "camps"
		2: return "mines"
		3: return "settlements"
		4: return "pois"
		5: return "junctions"
		6: return "bosses"
		_: return "junctions"

func _validate_defaults():
	for type in range(7):  # 0-6 for all NodeTypes
		if not type_defaults.has(type):
			GLog.warn("MapNodeRegistry: No default config for node type " + str(type))

func get_config(config_path: String) -> NodeConfig:
	var key = config_path.replace("res://", "")
	
	if node_configs.has(key):
		return node_configs[key]
	
	if ResourceLoader.exists("res://" + key):
		var config = load("res://" + key) as NodeConfig
		if config:
			node_configs[key] = config
			return config
	
	GLog.error("MapNodeRegistry: Config not found: " + config_path)
	return null

func get_default_config_for_type(node_type: int) -> NodeConfig:
	if type_defaults.has(node_type):
		return get_config(type_defaults[node_type])
	
	var category = _node_type_to_category(node_type)
	if random_pools.has(category) and not random_pools[category].is_empty():
		return get_config(random_pools[category][0])
	
	GLog.error("MapNodeRegistry: No config available for node type " + str(node_type))
	return null

func get_random_config_for_type(node_type: int) -> NodeConfig:
	var category = _node_type_to_category(node_type)
	
	if random_pools.has(category) and not random_pools[category].is_empty():
		var pool = random_pools[category]
		var random_index = randi() % pool.size()
		return get_config(pool[random_index])
	
	return get_default_config_for_type(node_type)

func get_random_config_for_category(category: String) -> NodeConfig:
	if random_pools.has(category) and not random_pools[category].is_empty():
		var pool = random_pools[category]
		var random_index = randi() % pool.size()
		return get_config(pool[random_index])
	
	GLog.warn("MapNodeRegistry: No configs in category: " + category)
	return null

func create_node(node_id: String, config_or_path, position: Vector2 = Vector2.ZERO) -> MapNode:
	var config: NodeConfig = null
	
	if config_or_path is String:
		config = get_config(config_or_path)
	elif config_or_path is NodeConfig:
		config = config_or_path
	elif typeof(config_or_path) == TYPE_INT:
		config = get_default_config_for_type(config_or_path)
	
	if not config:
		GLog.error("MapNodeRegistry: Cannot create node without valid config")
		return null
	
	var node = MapNode.new()
	node.id = node_id
	node.position = position
	node.config = config
	node.type = config.node_type
	
	node._generate_actions_from_config()
	
	return node

func create_node_with_random_config(node_id: String, node_type: int, position: Vector2 = Vector2.ZERO) -> MapNode:
	var config = get_random_config_for_type(node_type)
	if not config:
		return null
	
	return create_node(node_id, config, position)

func get_all_configs_for_type(node_type: int) -> Array[NodeConfig]:
	var results: Array[NodeConfig] = []
	var category = _node_type_to_category(node_type)
	
	if random_pools.has(category):
		for config_key in random_pools[category]:
			var config = get_config(config_key)
			if config:
				results.append(config)
	
	return results

func get_config_count() -> int:
	return node_configs.size()

func has_config(config_path: String) -> bool:
	var key = config_path.replace("res://", "")
	return node_configs.has(key) or ResourceLoader.exists("res://" + key)

func reload_configs():
	node_configs.clear()
	type_defaults.clear()
	random_pools.clear()
	load_all_configs()

