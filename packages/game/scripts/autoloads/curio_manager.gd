extends Node

const DEBUG_ENABLED: bool = true

# Signals for curio events
signal curio_acquired(curio: Resource)
signal curio_removed(curio: Resource)
signal curio_triggered(curio: Resource, effect_name: String)
signal curio_stack_changed(curio: Resource, new_count: int)

# Active curios and their stack counts
var active_curios: Array = []  # Array of CurioData resources
var curio_stacks: Dictionary = {}  # curio_name -> stack_count

# Track curios offered to avoid duplicates (for non-stackable)
var curios_offered_this_run: Array[String] = []

# References to other systems
var game_manager: Node = null
var event_bus: Node = null

func _ready() -> void:
	GLog.debug("CurioManager initialized - Ancient artifacts await discovery")
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# Get references to other autoloads
	game_manager = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	event_bus = get_node("/root/EventBus") if has_node("/root/EventBus") else null
	
	# Connect to relevant events
	if event_bus:
		setup_event_connections()

func setup_event_connections() -> void:
	# Combat events
	event_bus.connect_safe("duel_started", _on_combat_started)
	event_bus.connect_safe("duel_ended", _on_combat_ended)
	event_bus.connect_safe("turn_started", _on_turn_started)
	event_bus.connect_safe("turn_ended", _on_turn_ended)
	
	# Card events
	event_bus.connect_safe("card_played", _on_card_played)
	
	# Damage events
	event_bus.connect_safe("damage_dealt", _on_damage_dealt)
	# Note: damage_taken signal doesn't exist in EventBus yet
	
	# Enemy events
	event_bus.connect_safe("enemy_defeated", _on_enemy_defeated)
	
	# Map events
	event_bus.connect_safe("node_selected", _on_node_selected)
	event_bus.connect_safe("shop_entered", _on_shop_entered)

# Add a curio to the player's collection
func add_curio(curio: Resource) -> bool:
	if not curio:
		GLog.error("Attempted to add null curio")
		return false
	
	var curio_name_str = curio.curio_name if curio.curio_name else "Unknown"
	GLog.debug("Adding curio: " + curio_name_str)
	
	# Check if this curio can stack with existing ones
	var curio_name = curio.curio_name if curio.curio_name else ""
	var is_stackable = curio.stackable if curio.stackable != null else false
	if is_stackable:
		if curio_stacks.has(curio_name):
			var current_stacks = curio_stacks[curio_name]
			var max_stacks = curio.max_stacks if curio.max_stacks != null else 1
			if current_stacks < max_stacks:
				curio_stacks[curio_name] = current_stacks + 1
				curio_stack_changed.emit(curio, current_stacks + 1)
				GLog.debug("Stacked curio '%s' to %d stacks" % [curio_name, current_stacks + 1])
				trigger_curio_effects("passive", {"curio_added": curio})
				return true
			else:
				GLog.debug("Curio '%s' already at max stacks (%d)" % [curio_name, max_stacks])
				return false
		else:
			curio_stacks[curio_name] = 1
	
	# Add to active curios
	active_curios.append(curio)
	
	# Apply corruption cost if any
	var corruption_cost = curio.corruption_cost if curio.corruption_cost != null else 0
	if corruption_cost > 0 and game_manager:
		game_manager.add_corruption(corruption_cost)
		GLog.debug("Added %d corruption from curio" % corruption_cost)
	
	# Track that this curio has been offered
	if not curio_name in curios_offered_this_run:
		curios_offered_this_run.append(curio_name)
	
	# Emit acquisition signal
	curio_acquired.emit(curio)
	if event_bus:
		event_bus.emit_signal("curio_acquired", curio)
	
	# Trigger any passive effects immediately
	trigger_curio_effects("passive", {"curio_added": curio})
	
	return true

# Remove a curio from the player's collection
func remove_curio(curio: Resource) -> void:
	if not curio:
		return
	
	var curio_name = curio.curio_name if curio.curio_name else "Unknown"
	GLog.debug("Removing curio: " + curio_name)
	
	# Handle stacked curios
	var is_stackable = curio.stackable if curio.stackable != null else false
	if is_stackable and curio_stacks.has(curio_name):
		var current_stacks = curio_stacks[curio_name]
		if current_stacks > 1:
			curio_stacks[curio_name] = current_stacks - 1
			curio_stack_changed.emit(curio, current_stacks - 1)
			GLog.debug("Reduced curio '%s' to %d stacks" % [curio_name, current_stacks - 1])
			return
		else:
			curio_stacks.erase(curio_name)
	
	# Remove from active curios
	active_curios.erase(curio)
	
	# Emit removal signal
	curio_removed.emit(curio)
	if event_bus:
		event_bus.emit_signal("curio_removed", curio)

# Check if player has a specific curio
func has_curio(curio_name: String) -> bool:
	for curio in active_curios:
		var check_name = curio.curio_name if curio.curio_name else ""
		if check_name == curio_name:
			return true
	return false

# Get stack count for a curio
func get_curio_stack_count(curio_name: String) -> int:
	return curio_stacks.get(curio_name, 0)

# Get all active curios
func get_active_curios() -> Array:
	return active_curios.duplicate()

# Trigger curio effects for a specific event
func trigger_curio_effects(event_type: String, context: Dictionary = {}) -> void:
	if active_curios.is_empty():
		return
	
	GLog.debug("Triggering curio effects for event: " + event_type)
	
	for curio in active_curios:
		var effects = curio.effects if curio.effects != null else []
		for effect in effects:
			var trigger = effect.trigger_event if effect.trigger_event else ""
			if effect and trigger == event_type:
				if effect.can_trigger(self, context):
					var effect_name = "Unknown"
					if effect and effect.has_method("get_effect_name"):
						effect_name = effect.get_effect_name()
					var curio_name = curio.curio_name if curio.curio_name else "Unknown"
					GLog.debug("Triggering effect '%s' from curio '%s'" % [effect_name, curio_name])
					effect.apply_effect(self, curio, context)
					effect.mark_triggered()
					curio_triggered.emit(curio, effect_name)
					if event_bus:
						event_bus.emit_signal("curio_triggered", curio, effect_name)

# Calculate cumulative stat modifiers from all curios
func get_stat_modifier(stat_name: String) -> float:
	var total_modifier = 0.0
	
	for curio in active_curios:
		# Get stack multiplier
		var curio_name = curio.curio_name if curio.curio_name else ""
		var stack_mult = curio_stacks.get(curio_name, 1)
		
		# Each curio effect can contribute to stat modifiers
		var effects = curio.effects if curio.effects != null else []
		for effect in effects:
			if effect and effect.has_method("get_stat_modifier"):
				total_modifier += effect.get_stat_modifier(stat_name) * stack_mult
	
	return total_modifier

# Event handlers
func _on_combat_started(_enemy_data: Resource) -> void:
	# Reset combat tracking for all effects
	for curio in active_curios:
		var effects = curio.effects if curio.effects != null else []
		for effect in effects:
			if effect and effect.has_method("reset_combat_tracking"):
				effect.reset_combat_tracking()
	
	# Trigger combat start effects
	trigger_curio_effects("combat_start", {"enemy": _enemy_data})

func _on_combat_ended(victory: bool) -> void:
	trigger_curio_effects("combat_end", {"victory": victory})

func _on_turn_started(turn_number: int) -> void:
	# Reset turn tracking for all effects
	for curio in active_curios:
		var effects = curio.effects if curio.effects != null else []
		for effect in effects:
			if effect and effect.has_method("reset_turn_tracking"):
				effect.reset_turn_tracking()
	
	# Trigger turn start effects
	trigger_curio_effects("turn_start", {"turn_number": turn_number})

func _on_turn_ended(turn_number: int) -> void:
	trigger_curio_effects("turn_end", {"turn_number": turn_number})

func _on_card_played(card: Node) -> void:
	var context = {
		"card": card,
		"card_data": card.card_data if card.card_data else null
	}
	trigger_curio_effects("card_played", context)

func _on_damage_dealt(target: Node, amount: int, source: Node) -> void:
	trigger_curio_effects("damage_dealt", {
		"target": target,
		"amount": amount,
		"source": source
	})

# Note: damage_taken not implemented yet
# func _on_damage_taken(target: Node, amount: int) -> void:
#	trigger_curio_effects("damage_taken", {"amount": amount})

func _on_enemy_defeated(enemy: Node) -> void:
	trigger_curio_effects("enemy_defeated", {"enemy": enemy})

func _on_node_selected(node: Node) -> void:
	trigger_curio_effects("node_selected", {"node": node})

func _on_shop_entered() -> void:
	trigger_curio_effects("shop_entered", {})

# ============================================
# REWARD POOL SELECTION METHODS
# ============================================

# Cached reward pool to avoid repeated disk access
var _reward_pool_cache: Array = []
var _reward_pool_cached: bool = false

## Get all reward-tier curios (excludes starting/ directory)
func get_reward_curio_pool() -> Array:
	if _reward_pool_cached:
		return _reward_pool_cache.duplicate()

	_reward_pool_cache.clear()

	var reward_directories = [
		"res://data/curios/common/",
		"res://data/curios/rare/",
		"res://data/curios/legendary/",
		"res://data/curios/corrupted/"
	]

	for dir_path in reward_directories:
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres") and not file_name.begins_with("template"):
					var full_path = dir_path + file_name
					var curio = load(full_path)
					if curio and curio is Resource:
						_reward_pool_cache.append(curio)
						GLog.debug("Loaded reward curio: %s" % file_name)
				file_name = dir.get_next()
			dir.list_dir_end()

	_reward_pool_cached = true
	GLog.debug("Cached %d reward-tier curios" % _reward_pool_cache.size())
	return _reward_pool_cache.duplicate()

## Filter to curios available for reward (not owned, not offered, unlocks met)
func get_available_curios_for_reward(character_class: String) -> Array:
	var pool = get_reward_curio_pool()
	var available: Array = []

	for curio in pool:
		var curio_name = curio.curio_name if "curio_name" in curio else ""

		# Skip if already owned and not stackable (or at max stacks)
		if has_curio(curio_name):
			var is_stackable = curio.stackable if "stackable" in curio else false
			if not is_stackable:
				continue
			var max_stacks = curio.max_stacks if "max_stacks" in curio else 1
			if get_curio_stack_count(curio_name) >= max_stacks:
				continue

		# Skip if already offered this run (for non-stackable)
		var is_stackable = curio.stackable if "stackable" in curio else false
		if not is_stackable and curio_name in curios_offered_this_run:
			continue

		# Check unlock requirements (if any)
		var unlock_req = curio.unlock_requirement if "unlock_requirement" in curio else ""
		if unlock_req != "" and not _check_unlock_requirement(unlock_req):
			continue

		available.append(curio)

	GLog.debug("Found %d available curios for reward (class: %s)" % [available.size(), character_class])
	return available

## Get weighted selection based on class synergy
func get_weighted_curio_selection(character_class: String, count: int = 3) -> Array:
	var available = get_available_curios_for_reward(character_class)

	if available.is_empty():
		GLog.debug("No curios available for selection")
		return []

	# Build weighted selection
	var selected: Array = []
	var remaining = available.duplicate()

	for i in range(mini(count, remaining.size())):
		# Calculate weights based on class synergy
		var weights: Array[float] = []
		var total_weight: float = 0.0

		for curio in remaining:
			var weight: float = 1.0
			if curio.has_method("get_synergy_for_class"):
				weight = curio.get_synergy_for_class(character_class)
			elif character_class != "":
				# Fallback: check synergy properties directly
				var synergy_prop = character_class.to_lower() + "_synergy"
				if synergy_prop in curio:
					weight = curio.get(synergy_prop)

			# Ensure minimum weight
			weight = maxf(weight, 0.1)
			weights.append(weight)
			total_weight += weight

		# Weighted random selection
		var roll = randf() * total_weight
		var cumulative: float = 0.0
		var selected_index: int = 0

		for j in range(weights.size()):
			cumulative += weights[j]
			if roll <= cumulative:
				selected_index = j
				break

		# Add to selection and remove from remaining
		var chosen = remaining[selected_index]
		selected.append(chosen)
		remaining.remove_at(selected_index)

		# Track that this curio was offered
		var curio_name = chosen.curio_name if "curio_name" in chosen else ""
		if curio_name != "" and not curio_name in curios_offered_this_run:
			curios_offered_this_run.append(curio_name)

	GLog.debug("Selected %d curios with class weighting" % selected.size())
	return selected

## Clear all active curios and their stacks
func clear_curios() -> void:
	active_curios.clear()
	curio_stacks.clear()
	GLog.debug("Cleared all active curios")

## Reset curio tracking at run start
func reset_run_curios() -> void:
	curios_offered_this_run.clear()
	GLog.debug("Reset curios_offered_this_run for new run")

## Invalidate the reward pool cache (call if curios are added/modified)
func invalidate_reward_pool_cache() -> void:
	_reward_pool_cached = false
	_reward_pool_cache.clear()

## Check unlock requirement (placeholder for future implementation)
func _check_unlock_requirement(requirement: String) -> bool:
	# TODO: Implement unlock requirement checks
	# For now, all curios are considered unlocked
	if requirement.is_empty():
		return true
	return true

# ============================================
# CURIO STAT HELPER (for player stat queries)
# ============================================

## Get curio-based modifier for a specific stat (used by player systems)
func get_curio_stat_modifier(_stat_name: String) -> float:
	# Alias for get_stat_modifier for clearer API
	return get_stat_modifier(_stat_name)

# ============================================
# SAVE/LOAD SUPPORT
# ============================================

# Save/Load support
func get_save_data() -> Dictionary:
	var save_data = {
		"curios": [],
		"curio_stacks": curio_stacks.duplicate(),
		"curios_offered": curios_offered_this_run.duplicate()
	}
	
	# Save curio resource paths
	for curio in active_curios:
		var resource_path = curio.resource_path if curio.resource_path else ""
		if resource_path:
			save_data["curios"].append(resource_path)
	
	return save_data

func load_from_data(data: Dictionary) -> void:
	# Clear current state
	active_curios.clear()
	curio_stacks.clear()
	curios_offered_this_run.clear()
	
	# Load curios
	var curio_paths = data.get("curios", [])
	for path in curio_paths:
		var curio = load(path)
		if curio:
			active_curios.append(curio)
	
	# Load stacks
	curio_stacks = data.get("curio_stacks", {}).duplicate()
	
	# Load offered curios
	curios_offered_this_run = data.get("curios_offered", []).duplicate()
	
	GLog.debug("Loaded %d curios from save data" % active_curios.size())

# Debug methods
func debug_add_curio(curio_name: String) -> void:
	# Try to find and load the curio
	var search_paths = [
		"res://data/curios/common/",
		"res://data/curios/rare/",
		"res://data/curios/legendary/",
		"res://data/curios/corrupted/"
	]
	
	for path in search_paths:
		var file_path = path + curio_name.to_lower().replace(" ", "_") + ".tres"
		if ResourceLoader.exists(file_path):
			var curio = load(file_path)
			if curio:
				add_curio(curio)
				GLog.debug("Debug: Added curio '%s'" % curio_name)
				return
	
	GLog.error("Debug: Could not find curio '%s'" % curio_name)

func debug_list_curios() -> void:
	print("\n=== Active Curios ===")
	for curio in active_curios:
		var curio_name = curio.curio_name if curio.curio_name else "Unknown"
		var stacks = curio_stacks.get(curio_name, 1)
		var rarity = curio.rarity if curio.rarity else "Common"
		var description = curio.description if curio.description else ""
		print("- %s (x%d) [%s]" % [curio_name, stacks, rarity])
		print("  %s" % description)
	print("Total: %d curios\n" % active_curios.size())
