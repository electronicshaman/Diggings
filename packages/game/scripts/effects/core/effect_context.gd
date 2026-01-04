extends Resource
class_name EffectContext

# Source information
@export var source_type: String = "" # "card", "encounter", "curio", "status", etc.
@export var source_object: Resource = null # The card/encounter/curio that triggered this

# State references (not exported because this is a Resource)
var game_manager: Node = null
var duel_manager: Node = null # May be null outside combat
@export var player_data: Resource = null
@export var enemy_data: Resource = null # May be null outside combat

# Trigger information
@export var trigger_event: String = "" # "card_played", "turn_start", "enemy_defeated", etc.
@export var trigger_data: Dictionary = {} # Event-specific data

# Curio modifications (populated by EffectProcessor when resolving card effects)
@export var curio_modifications: Dictionary = {} # {damage: int, defense: int, cost: int, draw: int}

# Targeting
@export var primary_target: Resource = null
@export var secondary_targets: Array[Resource] = []

# Performance optimization - cached calculations and reusable data
var _curio_modifications_cache: Dictionary = {}
var _conditional_values_cache: Dictionary = {}
var _cache_dirty: bool = true
var _creation_timestamp: int = 0
var _last_access_timestamp: int = 0
var _access_count: int = 0

# Enhanced caching for frequently accessed data
var _validation_cache: Dictionary = {}
var _target_cache: Dictionary = {}
var _state_snapshot_cache: Dictionary = {}
var _cache_generation: int = 0

# Object reuse tracking
var _reuse_count: int = 0
var _pool_generation: int = 0
var _is_pooled: bool = false

# Static performance monitoring
static var _total_contexts_created: int = 0
static var _total_cache_hits: int = 0
static var _total_cache_misses: int = 0
static var _total_creation_time_ms: int = 0
static var _total_reuse_count: int = 0
static var _pool_efficiency_ratio: float = 0.0

func _init() -> void:
	_creation_timestamp = Time.get_ticks_msec()
	_last_access_timestamp = _creation_timestamp
	_total_contexts_created += 1
	_cache_generation = 0
	_reuse_count = 0
	_pool_generation = 0
	_is_pooled = false

## Get curio modifications with caching for performance
func get_curio_modifications() -> Dictionary:
	_update_access_stats()
	
	# Return cached result if available and not dirty
	if not _cache_dirty and not _curio_modifications_cache.is_empty():
		_total_cache_hits += 1
		return _curio_modifications_cache
	
	_total_cache_misses += 1
	
	# Calculate curio modifications if not cached or dirty
	if is_instance_valid(CurioManager) and source_object and source_type == "card":
		var is_player_owned = true  # Default assumption, can be refined
		if source_object.has_method("get_owner"):
			is_player_owned = source_object.get_owner() == "player"
		elif "owner" in source_object:
			is_player_owned = source_object.owner == "player"
		
		if is_instance_valid(CurioManager) and CurioManager.has_method("calculate_card_modifications"):
			_curio_modifications_cache = CurioManager.calculate_card_modifications(source_object, is_player_owned)
		else:
			_curio_modifications_cache = {}
	else:
		_curio_modifications_cache = curio_modifications.duplicate()
	
	_cache_dirty = false
	return _curio_modifications_cache

## Cache conditional values for an effect to avoid repeated calculations
func cache_conditional_values(effect: GameEffect) -> void:
	if not effect:
		return
	
	_update_access_stats()
	
	var effect_id = effect.effect_id if effect.effect_id else "unknown_effect"
	
	# Skip if already cached for this effect
	if _conditional_values_cache.has(effect_id):
		return
	
	var cached_values = {}
	
	# Cache commonly used conditional values
	if player_data:
		cached_values["player_health"] = player_data.health if "health" in player_data else 0
		cached_values["player_max_health"] = player_data.max_health if "max_health" in player_data else 0
		cached_values["player_sanity"] = player_data.sanity if "sanity" in player_data else 0
		cached_values["player_max_sanity"] = player_data.max_sanity if "max_sanity" in player_data else 0
		cached_values["player_gold"] = player_data.gold if "gold" in player_data else 0
		
		# Cache health/sanity percentages for conditional effects
		if cached_values.player_max_health > 0:
			cached_values["player_health_percentage"] = float(cached_values.player_health) / float(cached_values.player_max_health)
		else:
			cached_values["player_health_percentage"] = 0.0
			
		if cached_values.player_max_sanity > 0:
			cached_values["player_sanity_percentage"] = float(cached_values.player_sanity) / float(cached_values.player_max_sanity)
		else:
			cached_values["player_sanity_percentage"] = 0.0
	
	if enemy_data:
		cached_values["enemy_health"] = enemy_data.health if "health" in enemy_data else 0
		cached_values["enemy_max_health"] = enemy_data.max_health if "max_health" in enemy_data else 0
		
		if cached_values.enemy_max_health > 0:
			cached_values["enemy_health_percentage"] = float(cached_values.enemy_health) / float(cached_values.enemy_max_health)
		else:
			cached_values["enemy_health_percentage"] = 0.0
	
	# Cache duel state information if available
	if duel_manager and duel_manager.has_method("get_duel_state"):
		var duel_state = duel_manager.get_duel_state()
		if duel_state:
			cached_values["turn_number"] = duel_state.turn_number if "turn_number" in duel_state else 0
			cached_values["cards_played_this_turn"] = duel_state.cards_played_this_turn if "cards_played_this_turn" in duel_state else 0
			cached_values["player_energy"] = duel_state.player_energy if "player_energy" in duel_state else 0
			cached_values["player_max_energy"] = duel_state.player_max_energy if "player_max_energy" in duel_state else 0
	
	_conditional_values_cache[effect_id] = cached_values

## Get cached conditional value for an effect
func get_cached_conditional_value(effect: GameEffect, value_key: String, default_value = null):
	if not effect:
		return default_value
	
	_update_access_stats()
	
	var effect_id = effect.effect_id if effect.effect_id else "unknown_effect"
	
	if not _conditional_values_cache.has(effect_id):
		return default_value
	
	var effect_cache = _conditional_values_cache[effect_id]
	return effect_cache.get(value_key, default_value)

## Enhanced validation caching to avoid redundant checks
func cache_validation_result(validation_key: String, result: bool) -> void:
	"""Cache validation results to avoid redundant validation checks."""
	_validation_cache[validation_key] = {
		"result": result,
		"timestamp": Time.get_ticks_msec(),
		"generation": _cache_generation
	}

## Get cached validation result if available and not stale
func get_cached_validation_result(validation_key: String) -> Dictionary:
	"""Get cached validation result if available and not stale."""
	if not _validation_cache.has(validation_key):
		return {"valid": false, "result": false}
	
	var cache_entry = _validation_cache[validation_key]
	var current_time = Time.get_ticks_msec()
	
	# Check if cache entry is stale (older than 5 seconds or different generation)
	if (current_time - cache_entry.timestamp > 5000) or (cache_entry.generation != _cache_generation):
		_validation_cache.erase(validation_key)
		return {"valid": false, "result": false}
	
	_total_cache_hits += 1
	return {"valid": true, "result": cache_entry.result}

## Cache target information to avoid repeated lookups
func cache_target_info(target_key: String, target_info: Dictionary) -> void:
	"""Cache target information to avoid repeated target resolution."""
	_target_cache[target_key] = {
		"info": target_info,
		"timestamp": Time.get_ticks_msec(),
		"generation": _cache_generation
	}

## Get cached target information
func get_cached_target_info(target_key: String) -> Dictionary:
	"""Get cached target information if available and not stale."""
	if not _target_cache.has(target_key):
		return {}
	
	var cache_entry = _target_cache[target_key]
	var current_time = Time.get_ticks_msec()
	
	# Check if cache entry is stale (older than 2 seconds or different generation)
	if (current_time - cache_entry.timestamp > 2000) or (cache_entry.generation != _cache_generation):
		_target_cache.erase(target_key)
		return {}
	
	_total_cache_hits += 1
	return cache_entry.info

## Cache state snapshot for expensive state calculations
func cache_state_snapshot(snapshot_key: String, state_data: Dictionary) -> void:
	"""Cache expensive state calculations to avoid recomputation."""
	_state_snapshot_cache[snapshot_key] = {
		"data": state_data,
		"timestamp": Time.get_ticks_msec(),
		"generation": _cache_generation
	}

## Get cached state snapshot
func get_cached_state_snapshot(snapshot_key: String) -> Dictionary:
	"""Get cached state snapshot if available and not stale."""
	if not _state_snapshot_cache.has(snapshot_key):
		return {}
	
	var cache_entry = _state_snapshot_cache[snapshot_key]
	var current_time = Time.get_ticks_msec()
	
	# Check if cache entry is stale (older than 1 second or different generation)
	if (current_time - cache_entry.timestamp > 1000) or (cache_entry.generation != _cache_generation):
		_state_snapshot_cache.erase(snapshot_key)
		return {}
	
	_total_cache_hits += 1
	return cache_entry.data

## Clear all cached data (call when context data changes)
func clear_cache() -> void:
	_curio_modifications_cache.clear()
	_conditional_values_cache.clear()
	_validation_cache.clear()
	_target_cache.clear()
	_state_snapshot_cache.clear()
	_cache_dirty = true
	_cache_generation += 1

## Mark cache as dirty (call when underlying data changes)
func invalidate_cache() -> void:
	_cache_dirty = true
	_cache_generation += 1

## Selective cache invalidation for better performance
func invalidate_cache_selective(cache_types: Array[String]) -> void:
	"""Invalidate only specific cache types to minimize performance impact."""
	for cache_type in cache_types:
		match cache_type:
			"curio":
				_curio_modifications_cache.clear()
				_cache_dirty = true
			"conditional":
				_conditional_values_cache.clear()
			"validation":
				_validation_cache.clear()
			"target":
				_target_cache.clear()
			"state":
				_state_snapshot_cache.clear()
	
	_cache_generation += 1

## Get performance statistics for this context
func get_performance_stats() -> Dictionary:
	return {
		"creation_timestamp": _creation_timestamp,
		"last_access_timestamp": _last_access_timestamp,
		"access_count": _access_count,
		"age_ms": Time.get_ticks_msec() - _creation_timestamp,
		"cache_entries": _conditional_values_cache.size(),
		"cache_dirty": _cache_dirty,
		"reuse_count": _reuse_count,
		"pool_generation": _pool_generation,
		"is_pooled": _is_pooled,
		"cache_generation": _cache_generation,
		"total_cache_entries": _curio_modifications_cache.size() + _conditional_values_cache.size() + _validation_cache.size() + _target_cache.size() + _state_snapshot_cache.size(),
		"cache_breakdown": {
			"curio_modifications": _curio_modifications_cache.size(),
			"conditional_values": _conditional_values_cache.size(),
			"validation": _validation_cache.size(),
			"target": _target_cache.size(),
			"state_snapshot": _state_snapshot_cache.size()
		}
	}

## Get global performance statistics for all contexts
static func get_global_performance_stats() -> Dictionary:
	_update_pool_efficiency()
	return {
		"total_contexts_created": _total_contexts_created,
		"total_cache_hits": _total_cache_hits,
		"total_cache_misses": _total_cache_misses,
		"total_creation_time_ms": _total_creation_time_ms,
		"total_reuse_count": _total_reuse_count,
		"pool_efficiency_ratio": _pool_efficiency_ratio,
		"cache_hit_rate": float(_total_cache_hits) / float(_total_cache_hits + _total_cache_misses) if (_total_cache_hits + _total_cache_misses) > 0 else 0.0,
		"average_creation_time_ms": float(_total_creation_time_ms) / float(_total_contexts_created) if _total_contexts_created > 0 else 0.0,
		"average_reuse_per_context": float(_total_reuse_count) / float(_total_contexts_created) if _total_contexts_created > 0 else 0.0
	}

## Update pool efficiency calculation
static func _update_pool_efficiency() -> void:
	"""Calculate pool efficiency ratio based on reuse vs creation."""
	if _total_contexts_created > 0:
		_pool_efficiency_ratio = float(_total_reuse_count) / float(_total_contexts_created + _total_reuse_count)
	else:
		_pool_efficiency_ratio = 0.0

## Reset global performance statistics
static func reset_global_performance_stats() -> void:
	_total_contexts_created = 0
	_total_cache_hits = 0
	_total_cache_misses = 0
	_total_creation_time_ms = 0
	_total_reuse_count = 0
	_pool_efficiency_ratio = 0.0

## Update access statistics for performance monitoring
func _update_access_stats() -> void:
	_last_access_timestamp = Time.get_ticks_msec()
	_access_count += 1

## Prepare context for reuse (called by object pool)
func reset_for_reuse() -> void:
	# Track reuse statistics
	_reuse_count += 1
	_total_reuse_count += 1
	_is_pooled = true
	_pool_generation += 1
	
	# Clear all data
	source_type = ""
	source_object = null
	game_manager = null
	duel_manager = null
	player_data = null
	enemy_data = null
	trigger_event = ""
	trigger_data.clear()
	curio_modifications.clear()
	primary_target = null
	secondary_targets.clear()
	
	# Clear caches
	clear_cache()
	
	# Reset performance tracking
	_creation_timestamp = Time.get_ticks_msec()
	_last_access_timestamp = _creation_timestamp
	_access_count = 0

## Mark context as taken from pool (for tracking)
func mark_taken_from_pool() -> void:
	"""Mark this context as taken from pool for performance tracking."""
	_is_pooled = false
	_creation_timestamp = Time.get_ticks_msec()
	_last_access_timestamp = _creation_timestamp
