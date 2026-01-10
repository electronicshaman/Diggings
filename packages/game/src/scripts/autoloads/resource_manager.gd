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
	"attack_cards": "res://data/cards/player/attack/",
	"skill_cards": "res://data/cards/player/skill/",
	"power_cards": "res://data/cards/player/power/",
	"fortune_cards": "res://data/cards/player/fortune/",
	"enemies": "res://data/enemies/",
	"characters": "res://data/characters/",
	"themes": "res://data/themes/",
	"curios": "res://data/curios/",
	"events": "res://data/events/"
}

func _ready() -> void:
	GLog.debug("ResourceManager initialized - Reality's assets under control")
	initialize_resource_pools()

# Safe property existence helper for Objects/Resources without has_property()
func _has_prop(obj, prop_name: String) -> bool:
	if obj == null:
		return false
	if obj is Dictionary:
		return (obj as Dictionary).has(prop_name)
	if obj is Object:
		var o: Object = obj
		var plist: Array = o.get_property_list()
		for p in plist:
			if typeof(p) == TYPE_DICTIONARY and (p as Dictionary).get("name", "") == prop_name:
				return true
	return false

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
	# Input validation
	if path.is_empty():
		push_error("ResourceManager: Cannot load resource - path is empty")
		return _create_fallback_resource(path)
	
	# Return cached resource if available
	if loaded_resources.has(path):
		var cached = loaded_resources[path]
		if is_instance_valid(cached):
			GLog.debug("Returning cached resource: " + path)
			return cached
		else:
			# Remove invalid cached resource
			loaded_resources.erase(path)
			push_warning("ResourceManager: Removed invalid cached resource: " + path)
	
	# Check if resource exists
	if not ResourceLoader.exists(path):
		push_error("ResourceManager: Resource does not exist: " + path)
		return _create_fallback_resource(path)
	
	# Attempt to load resource with error handling
	var resource: Resource = null
	var load_result := _safe_load_resource(path)
	
	if load_result.error != OK:
		push_error("ResourceManager: Failed to load resource '%s' - Error: %s" % [path, error_string(load_result.error)])
		return _create_fallback_resource(path)
	
	resource = load_result.resource
	
	# Validate loaded resource
	if not is_instance_valid(resource):
		push_error("ResourceManager: Loaded resource is invalid: " + path)
		return _create_fallback_resource(path)
	
	# Cache if requested
	if cache:
		loaded_resources[path] = resource
	
	GLog.debug("Successfully loaded resource: " + path)
	resource_loaded.emit(path, resource)
	return resource

## Safe resource loading with error handling
func _safe_load_resource(path: String) -> Dictionary:
	var result = {"error": OK, "resource": null}
	
	# Validate path format
	if not _is_valid_resource_path(path):
		result.error = ERR_INVALID_PARAMETER
		return result
	
	# Attempt to load with error catching
	var resource: Resource
	
	# Use appropriate loading method based on path
	if path.begins_with("res://"):
		resource = load(path)
	else:
		push_warning("ResourceManager: Non-standard resource path: " + path)
		resource = load(path)
	
	if resource == null:
		result.error = ERR_FILE_NOT_FOUND
		return result
	
	result.resource = resource
	return result

## Create fallback resource for failed loads
func _create_fallback_resource(original_path: String) -> Resource:
	# Determine resource type from path and create appropriate fallback
	var fallback: Resource = null
	
	if original_path.ends_with(".tres") or original_path.ends_with(".res"):
		if "card" in original_path.to_lower():
			fallback = _create_fallback_card_resource()
		elif "character" in original_path.to_lower():
			fallback = _create_fallback_character_resource()
		elif "enemy" in original_path.to_lower():
			fallback = _create_fallback_enemy_resource()
		else:
			fallback = Resource.new()
			fallback.resource_name = "Fallback_" + original_path.get_file().get_basename()
	else:
		# Generic fallback for other resource types
		fallback = Resource.new()
		fallback.resource_name = "Fallback_" + original_path.get_file()
	
	GLog.warn("Created fallback resource for: " + original_path)
	return fallback

## Validate resource path format
func _is_valid_resource_path(path: String) -> bool:
	if path.is_empty():
		return false
	
	# Check for valid Godot resource path format
	if not (path.begins_with("res://") or path.begins_with("user://")):
		return false
	
	# Check for valid extension
	var valid_extensions = [".tres", ".res", ".tscn", ".gd", ".cs", ".png", ".jpg", ".ogg", ".wav"]
	for ext in valid_extensions:
		if path.ends_with(ext):
			return true
	
	return false

## Create fallback card resource
func _create_fallback_card_resource() -> Resource:
	var card_resource = Resource.new()
	card_resource.resource_name = "Fallback Card"
	# Add basic card properties that systems expect
	card_resource.set_meta("card_name", "Missing Card")
	card_resource.set_meta("cost", 1)
	card_resource.set_meta("type", "attack")
	card_resource.set_meta("description", "This card failed to load")
	return card_resource

## Create fallback character resource
func _create_fallback_character_resource() -> Resource:
	var character_resource = Resource.new()
	character_resource.resource_name = "Fallback Character"
	character_resource.set_meta("character_name", "Unknown Character")
	character_resource.set_meta("health", 50)
	character_resource.set_meta("class", "unknown")
	return character_resource

## Create fallback enemy resource
func _create_fallback_enemy_resource() -> Resource:
	var enemy_resource = Resource.new()
	enemy_resource.resource_name = "Fallback Enemy"
	enemy_resource.set_meta("enemy_name", "Unknown Enemy")
	enemy_resource.set_meta("health", 30)
	enemy_resource.set_meta("type", "basic")
	return enemy_resource

func load_resource_async(path: String, callback: Callable) -> void:
	# Input validation
	if path.is_empty():
		push_error("ResourceManager: Cannot load async - path is empty")
		callback.call(null)
		return
	
	if not callback.is_valid():
		push_error("ResourceManager: Invalid callback provided for async load")
		return
	
	# Return cached resource if available
	if loaded_resources.has(path):
		var cached = loaded_resources[path]
		if is_instance_valid(cached):
			callback.call(cached)
			return
		else:
			loaded_resources.erase(path)
	
	# Check if resource exists before attempting threaded load
	if not ResourceLoader.exists(path):
		push_error("ResourceManager: Cannot load async - resource does not exist: " + path)
		callback.call(_create_fallback_resource(path))
		return
	
	# Start threaded load
	var request_result = ResourceLoader.load_threaded_request(path)
	if request_result != OK:
		push_error("ResourceManager: Failed to start threaded load for: " + path)
		callback.call(_create_fallback_resource(path))
		return
	
	_wait_for_resource(path, callback)

func _wait_for_resource(path: String, callback: Callable) -> void:
	if not callback.is_valid():
		push_error("ResourceManager: Callback became invalid while waiting for resource: " + path)
		return
	
	var status := ResourceLoader.load_threaded_get_status(path)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(path)
			if is_instance_valid(resource):
				loaded_resources[path] = resource
				callback.call(resource)
				resource_loaded.emit(path, resource)
				GLog.debug("Async load completed: " + path)
			else:
				push_error("ResourceManager: Threaded load returned invalid resource: " + path)
				callback.call(_create_fallback_resource(path))
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("ResourceManager: Failed to load resource async: " + path)
			callback.call(_create_fallback_resource(path))
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Continue waiting
			await get_tree().process_frame
			_wait_for_resource(path, callback)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("ResourceManager: Invalid resource requested for async load: " + path)
			callback.call(_create_fallback_resource(path))
		_:
			push_warning("ResourceManager: Unknown thread load status for: " + path)
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
	
	# Input validation
	if dir_path.is_empty():
		push_error("ResourceManager: Cannot load directory - path is empty")
		return resources
	
	if extension.is_empty():
		push_warning("ResourceManager: No extension specified, defaulting to 'tres'")
		extension = "tres"
	
	# Attempt to open directory
	var dir := DirAccess.open(dir_path)
	if dir == null:
		var error_code = DirAccess.get_open_error()
		push_error("ResourceManager: Cannot open directory '%s' - Error: %s" % [dir_path, error_string(error_code)])
		return resources
	
	# Track loading statistics
	var total_files = 0
	var loaded_count = 0
	var failed_count = 0
	
	# Begin directory listing
	var list_result = dir.list_dir_begin()
	if list_result != OK:
		push_error("ResourceManager: Failed to begin directory listing for: " + dir_path)
		return resources
	
	var file_name := dir.get_next()
	
	while file_name != "":
		# Skip directories and system files
		if not dir.current_is_dir() and not file_name.begins_with("."):
			if file_name.ends_with("." + extension):
				total_files += 1
				var full_path := dir_path.path_join(file_name) # Use path_join for better path handling
				
				var resource := load_resource(full_path)
				if is_instance_valid(resource):
					resources.append(resource)
					loaded_count += 1
				else:
					failed_count += 1
					GLog.warn("Failed to load resource: " + full_path)
		
		file_name = dir.get_next()
	
	# Log loading results
	if failed_count > 0:
		push_warning("ResourceManager: Loaded %d/%d resources from '%s' (%d failed)" % [loaded_count, total_files, dir_path, failed_count])
	else:
		GLog.debug("Successfully loaded %d resources from: %s" % [loaded_count, dir_path])
	
	return resources

func clear_cache() -> void:
	loaded_resources.clear()
	GLog.debug("Resource cache cleared")

func get_cache_size() -> int:
	return loaded_resources.size()

func validate_resource(resource: Resource, required_properties: Array[String]) -> bool:
	if not is_instance_valid(resource):
		push_error("ResourceManager: Cannot validate - resource is invalid")
		return false
	
	if required_properties.is_empty():
		push_warning("ResourceManager: No required properties specified for validation")
		return true
	
	var missing_properties: Array[String] = []
	
	for prop in required_properties:
		if prop.is_empty():
			continue

		# Check if property exists using safe helper and fallbacks
		var has_prop_flag := false
		if _has_prop(resource, prop):
			has_prop_flag = true
		elif resource.has_meta(prop):
			has_prop_flag = true
		elif prop in resource:
			has_prop_flag = true

		if not has_prop_flag:
			missing_properties.append(prop)
	
	if not missing_properties.is_empty():
		push_error("ResourceManager: Resource '%s' missing required properties: %s" % [resource.resource_name, str(missing_properties)])
		return false
	
	GLog.debug("Resource validation passed: " + resource.resource_name)
	return true

func get_resource_path(category: String, filename: String) -> String:
	# Input validation
	if category.is_empty():
		push_error("ResourceManager: Cannot get path - category is empty")
		return ""
	
	if filename.is_empty():
		push_error("ResourceManager: Cannot get path - filename is empty")
		return ""
	
	if not RESOURCE_PATHS.has(category):
		push_error("ResourceManager: Unknown resource category: " + category)
		push_warning("ResourceManager: Available categories: " + str(RESOURCE_PATHS.keys()))
		return ""
	
	var base_path = RESOURCE_PATHS[category]
	var full_path = base_path.path_join(filename)
	
	GLog.debug("Generated resource path: " + full_path)
	return full_path


## Get diagnostic information about resource manager state
func get_diagnostics() -> Dictionary:
	var diagnostics = {
		"loaded_resources": loaded_resources.size(),
		"preload_queue_size": preload_queue.size(),
		"is_preloading": is_preloading,
		"resource_pools": {},
		"cache_memory_usage": 0
	}
	
	# Pool diagnostics
	for pool_name in resource_pools:
		var pool = resource_pools[pool_name]
		diagnostics.resource_pools[pool_name] = {
			"available": pool.available.size(),
			"in_use": pool.in_use.size(),
			"max_size": pool.max_size,
			"has_factory": pool.factory != null and pool.factory.is_valid()
		}
	
	return diagnostics
