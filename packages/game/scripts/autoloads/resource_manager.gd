extends Node

const DEBUG_ENABLED: bool = true

signal resource_loaded(resource_path: String, resource: Resource)
signal resource_pool_created(pool_name: String)
signal resource_pool_cleared(pool_name: String)

var loaded_resources: Dictionary = {}
var resource_pools: Dictionary = {}
var preload_queue: Array[String] = []
var is_preloading: bool = false

const POOL_SIZES: Dictionary = {
	"cards": 50,
	"effects": 100,
	"particles": 50,
	"damage_numbers": 30,
	"status_icons": 20
}

const RESOURCE_PATHS: Dictionary = {
	"cards": "res://data/cards/",
	"attack_cards": "res://data/cards/attack/",
	"skill_cards": "res://data/cards/skill/",
	"power_cards": "res://data/cards/power/",
	"fortune_cards": "res://data/cards/fortune/",
	"enemies": "res://data/enemies/",
	"characters": "res://data/characters/",
	"themes": "res://data/themes/",
	"curios": "res://data/curios/",
	"events": "res://data/events/"
}

func _ready() -> void:
	GLog.debug("ResourceManager initialized - Reality's assets under control")
	initialize_resource_pools()

func initialize_resource_pools() -> void:
	for pool_name in POOL_SIZES:
		create_resource_pool(pool_name, POOL_SIZES[pool_name])

func create_resource_pool(pool_name: String, size: int) -> void:
	if resource_pools.has(pool_name):
		GLog.warn("Resource pool already exists: " + pool_name)
		return
	
	resource_pools[pool_name] = {
		"available": [],
		"in_use": [],
		"max_size": size,
		"factory": null
	}
	
	GLog.debug("Created resource pool: " + pool_name + " (size: " + str(size) + ")")
	resource_pool_created.emit(pool_name)

func set_pool_factory(pool_name: String, factory: Callable) -> void:
	if not resource_pools.has(pool_name):
		GLog.error("Resource pool does not exist: " + pool_name)
		return
	
	resource_pools[pool_name].factory = factory
	populate_pool(pool_name)

func populate_pool(pool_name: String) -> void:
	if not resource_pools.has(pool_name):
		return
	
	var pool: Dictionary = resource_pools[pool_name]
	if pool.factory == null:
		GLog.warn("No factory set for pool: " + pool_name)
		return
	
	while pool.available.size() < pool.max_size:
		var instance = pool.factory.call()
		if instance:
			pool.available.append(instance)
			if instance is Node:
				instance.set_process(false)
				instance.visible = false

func get_from_pool(pool_name: String) -> Variant:
	if not resource_pools.has(pool_name):
		GLog.error("Resource pool does not exist: " + pool_name)
		return null
	
	var pool: Dictionary = resource_pools[pool_name]
	
	if pool.available.is_empty():
		if pool.factory:
			GLog.debug("Pool exhausted, creating new instance: " + pool_name)
			return pool.factory.call()
		else:
			GLog.error("Pool exhausted and no factory set: " + pool_name)
			return null
	
	var instance = pool.available.pop_back()
	pool.in_use.append(instance)
	
	if instance is Node:
		instance.set_process(true)
		instance.visible = true
	
	return instance

func return_to_pool(pool_name: String, instance: Variant) -> void:
	if not resource_pools.has(pool_name):
		GLog.error("Resource pool does not exist: " + pool_name)
		return
	
	var pool: Dictionary = resource_pools[pool_name]
	var index: int = pool.in_use.find(instance)
	
	if index == -1:
		GLog.warn("Instance not found in pool: " + pool_name)
		return
	
	pool.in_use.remove_at(index)
	
	if instance is Node:
		instance.set_process(false)
		instance.visible = false
		if instance.has_method("reset"):
			instance.reset()
	
	if pool.available.size() < pool.max_size:
		pool.available.append(instance)
	else:
		if instance is Node:
			instance.queue_free()

func clear_pool(pool_name: String) -> void:
	if not resource_pools.has(pool_name):
		return
	
	var pool: Dictionary = resource_pools[pool_name]
	
	for instance in pool.available + pool.in_use:
		if instance is Node:
			instance.queue_free()
	
	pool.available.clear()
	pool.in_use.clear()
	
	GLog.debug("Cleared resource pool: " + pool_name)
	resource_pool_cleared.emit(pool_name)

func load_resource(path: String, cache: bool = true) -> Resource:
	if loaded_resources.has(path):
		GLog.debug("Returning cached resource: " + path)
		return loaded_resources[path]
	
	if not ResourceLoader.exists(path):
		GLog.error("Resource does not exist: " + path)
		return null
	
	var resource := load(path) as Resource
	if resource == null:
		GLog.error("Failed to load resource: " + path)
		return null
	
	if cache:
		loaded_resources[path] = resource
	
	GLog.debug("Loaded resource: " + path)
	resource_loaded.emit(path, resource)
	return resource

func load_resource_async(path: String, callback: Callable) -> void:
	if loaded_resources.has(path):
		callback.call(loaded_resources[path])
		return
	
	ResourceLoader.load_threaded_request(path)
	_wait_for_resource(path, callback)

func _wait_for_resource(path: String, callback: Callable) -> void:
	var status := ResourceLoader.load_threaded_get_status(path)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			loaded_resources[path] = resource
			callback.call(resource)
			resource_loaded.emit(path, resource)
		ResourceLoader.THREAD_LOAD_FAILED:
			GLog.error("Failed to load resource async: " + path)
			callback.call(null)
		_:
			await get_tree().process_frame
			_wait_for_resource(path, callback)

func preload_resources(paths: Array[String]) -> void:
	preload_queue.append_array(paths)
	if not is_preloading:
		_process_preload_queue()

func _process_preload_queue() -> void:
	if preload_queue.is_empty():
		is_preloading = false
		GLog.debug("Preload queue completed")
		return
	
	is_preloading = true
	var path: String = preload_queue.pop_front()
	load_resource_async(path, _on_preload_complete)

func _on_preload_complete(_resource: Resource) -> void:
	_process_preload_queue()

func load_all_in_directory(dir_path: String, extension: String = "tres") -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	
	if dir == null:
		GLog.error("Cannot open directory: " + dir_path)
		return resources
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if file_name.ends_with("." + extension):
			var full_path := dir_path + "/" + file_name
			var resource := load_resource(full_path)
			if resource:
				resources.append(resource)
		file_name = dir.get_next()
	
	GLog.debug("Loaded " + str(resources.size()) + " resources from: " + dir_path)
	return resources

func clear_cache() -> void:
	loaded_resources.clear()
	GLog.debug("Resource cache cleared")

func get_cache_size() -> int:
	return loaded_resources.size()

func validate_resource(resource: Resource, required_properties: Array[String]) -> bool:
	if resource == null:
		return false
	
	for prop in required_properties:
		if not prop in resource:
			GLog.error("Resource missing required property: " + prop)
			return false
	
	return true

func get_resource_path(category: String, filename: String) -> String:
	if not RESOURCE_PATHS.has(category):
		GLog.error("Unknown resource category: " + category)
		return ""
	
	return RESOURCE_PATHS[category] + filename
