extends RefCounted
class_name StatusEffectManager
## Manages all active status effects on an entity (player or enemy).
## Handles applying, removing, querying, and processing status effects.

const DEBUG_ENABLED: bool = false

## Reference to the owning entity (PlayerData or EnemyState)
var owner: Resource

## Active effects mapped by effect_id
var active_effects: Dictionary = {}  # String -> StatusEffectInstance

## Change listeners for UI updates
var _change_listeners: Array[Callable] = []


func _init(owner_entity: Resource = null) -> void:
	owner = owner_entity


## Apply a status effect to this entity
func apply_status(effect_data: StatusEffectData, stacks: int = 1, source: Resource = null) -> void:
	if not effect_data:
		return

	var effect_id := effect_data.effect_id

	if active_effects.has(effect_id):
		var existing := active_effects[effect_id] as StatusEffectInstance
		match effect_data.stack_behavior:
			"add_stacks":
				existing.add_stacks(stacks)
			"refresh_duration":
				existing.set_stacks(maxi(existing.current_stacks, stacks))
			"take_higher":
				existing.set_stacks(maxi(existing.current_stacks, stacks))
	else:
		var instance := StatusEffectInstance.new(effect_data, stacks, source)
		instance.effect_expired.connect(_on_effect_expired.bind(effect_id))
		active_effects[effect_id] = instance

	_emit_change("applied", {"effect_id": effect_id, "stacks": get_stacks(effect_id)})

	if EventBus:
		EventBus.status_applied.emit(owner, effect_id, get_stacks(effect_id))


## Remove a status effect completely
func remove_status(effect_id: String) -> void:
	if active_effects.has(effect_id):
		active_effects.erase(effect_id)
		_emit_change("removed", {"effect_id": effect_id})

		if EventBus:
			EventBus.status_removed.emit(owner, effect_id)


## Check if entity has a specific status effect
func has_status(effect_id: String) -> bool:
	return active_effects.has(effect_id)


## Get current stack count for an effect (0 if not present)
func get_stacks(effect_id: String) -> int:
	if active_effects.has(effect_id):
		return (active_effects[effect_id] as StatusEffectInstance).current_stacks
	return 0


## Modify stacks by delta (positive to add, negative to remove)
func modify_stacks(effect_id: String, delta: int) -> void:
	if not active_effects.has(effect_id):
		return

	var instance := active_effects[effect_id] as StatusEffectInstance
	if delta > 0:
		instance.add_stacks(delta)
	else:
		instance.remove_stacks(-delta)

	_emit_change("stacks_changed", {"effect_id": effect_id, "stacks": instance.current_stacks})


## Get the StatusEffectInstance for an effect (or null)
func get_effect(effect_id: String) -> StatusEffectInstance:
	if active_effects.has(effect_id):
		return active_effects[effect_id] as StatusEffectInstance
	return null


## Get all active effect IDs
func get_active_effect_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in active_effects.keys():
		ids.append(key as String)
	return ids


# =============================================================================
# MODIFIER QUERIES - Used by CardResolver for damage/defense calculations
# =============================================================================

## Get flat damage bonus (Grit stacks)
func get_damage_bonus() -> int:
	return get_stacks("grit")


## Get damage multiplier (Weak = 0.75)
func get_damage_multiplier() -> float:
	if has_status("weak"):
		return 0.75
	return 1.0


## Get damage taken multiplier (Wounded = 1.5)
func get_damage_taken_multiplier() -> float:
	if has_status("wounded"):
		return 1.5
	return 1.0


## Get flat defense bonus (Guard stacks)
func get_defense_bonus() -> int:
	return get_stacks("guard")


## Get defense multiplier (Rattled = 0.75)
func get_defense_multiplier() -> float:
	if has_status("rattled"):
		return 0.75
	return 1.0


## Get draw modifier (+Clarity, -Confusion)
func get_draw_modifier() -> int:
	return get_stacks("clarity") - get_stacks("confusion")


## Get resource gain modifier (Focus stacks, consumed on use)
func get_resource_gain_modifier() -> int:
	return get_stacks("focus")


## Calculate reflection damage from Thorns (5% per stack, capped at 100%)
func get_reflection_damage(damage_taken: int) -> int:
	if not has_status("thorns"):
		return 0
	var instance := active_effects["thorns"] as StatusEffectInstance
	var percentage := instance.get_capped_percentage()
	return int(damage_taken * percentage)


## Calculate lifesteal amount from Drain (5% per stack, capped at 100%)
func get_lifesteal_amount(damage_dealt: int) -> int:
	if not has_status("drain"):
		return 0
	var instance := active_effects["drain"] as StatusEffectInstance
	var percentage := instance.get_capped_percentage()
	return int(damage_dealt * percentage)


## Check if entity can play Attack cards (blocked by Disarmed)
func can_play_attack() -> bool:
	return not has_status("disarmed")


# =============================================================================
# TURN PHASE PROCESSING
# =============================================================================

## Process effects that trigger at turn start. Returns array of effect results.
func process_turn_start() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	# Poison - deal damage equal to stacks
	if has_status("poison"):
		var stacks := get_stacks("poison")
		results.append({"type": "damage", "value": stacks, "effect_id": "poison", "bypasses_defense": true})
		modify_stacks("poison", -1)

	# Dread - deal sanity damage equal to stacks
	if has_status("dread"):
		var stacks := get_stacks("dread")
		results.append({"type": "sanity_damage", "value": stacks, "effect_id": "dread"})
		modify_stacks("dread", -1)

	# Recovery - heal health equal to stacks
	if has_status("recovery"):
		var stacks := get_stacks("recovery")
		results.append({"type": "heal", "value": stacks, "effect_id": "recovery"})
		modify_stacks("recovery", -1)

	# Surge - gain energy (consumed)
	if has_status("surge"):
		var stacks := get_stacks("surge")
		results.append({"type": "energy_gain", "value": stacks, "effect_id": "surge"})
		remove_status("surge")

	return results


## Process effects that trigger at turn end. Returns array of effect results.
func process_turn_end() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	# Burn - deal damage equal to total value (consumed)
	if has_status("burn"):
		var instance := active_effects["burn"] as StatusEffectInstance
		var damage := int(instance.get_total_value())
		results.append({"type": "damage", "value": damage, "effect_id": "burn", "bypasses_defense": true})
		remove_status("burn")

	# Resolve - heal sanity (consumed)
	if has_status("resolve"):
		var stacks := get_stacks("resolve")
		results.append({"type": "sanity_heal", "value": stacks, "effect_id": "resolve"})
		remove_status("resolve")

	return results


## Decay effects that decay at the specified phase
func decay_effects(phase: String) -> void:
	var to_remove: Array[String] = []

	for effect_id in active_effects:
		var instance := active_effects[effect_id] as StatusEffectInstance
		var data := instance.effect_data

		if data.decay_type == phase:
			if instance.remove_stacks(data.decay_amount):
				to_remove.append(effect_id)

	for effect_id in to_remove:
		remove_status(effect_id)


## Consume Focus stacks (called when resource is gained)
func consume_focus() -> void:
	if has_status("focus"):
		remove_status("focus")


# =============================================================================
# CHANGE LISTENERS
# =============================================================================

## Add a listener for status changes (for UI updates)
func add_change_listener(callback: Callable) -> void:
	if not callback in _change_listeners:
		_change_listeners.append(callback)


## Remove a change listener
func remove_change_listener(callback: Callable) -> void:
	var idx := _change_listeners.find(callback)
	if idx >= 0:
		_change_listeners.remove_at(idx)


func _emit_change(change_type: String, data: Dictionary = {}) -> void:
	for listener in _change_listeners:
		listener.call(change_type, data)


func _on_effect_expired(effect_id: String) -> void:
	remove_status(effect_id)


# =============================================================================
# PERSISTENCE
# =============================================================================

## Get save data for all active effects
func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for effect_id in active_effects:
		var instance := active_effects[effect_id] as StatusEffectInstance
		data[effect_id] = instance.current_stacks
	return data


## Load effects from save data
func load_from_data(data: Dictionary) -> void:
	clear_all()
	for effect_id in data:
		var effect_data := _load_effect_data(effect_id)
		if effect_data:
			apply_status(effect_data, data[effect_id])


## Clear all active effects
func clear_all() -> void:
	var ids := active_effects.keys()
	for effect_id in ids:
		remove_status(effect_id)


## Load a status effect resource by ID
func _load_effect_data(effect_id: String) -> StatusEffectData:
	# Check multiple possible paths
	var search_paths := [
		"res://data/status_effects/%s.tres" % effect_id,
		"res://data/status_effects/debuffs/%s.tres" % effect_id,
		"res://data/status_effects/buffs/%s.tres" % effect_id,
	]

	for path in search_paths:
		if ResourceLoader.exists(path):
			return load(path) as StatusEffectData

	push_warning("StatusEffectManager: Could not find effect data for '%s'" % effect_id)
	return null
