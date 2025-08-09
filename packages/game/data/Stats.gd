extends Resource
class_name Stats

# Stats Resource - Handles health, energy, sanity, and defense with change tracking
# Part of the resource-based architecture migration for better performance and reusability

# Health stats
@export var current_health: int = 50:
	set(value):
		if current_health != value:
			var old_value: int = current_health
			current_health = clamp(value, 0, max_health)
			_emit_change("health_changed", old_value, current_health)

@export var max_health: int = 50:
	set(value):
		if max_health != value:
			var old_value: int = max_health
			max_health = max(1, value)
			# Adjust current health if it exceeds new max
			if current_health > max_health:
				current_health = max_health
			_emit_change("max_health_changed", old_value, max_health)

# Energy stats
@export var current_energy: int = 3:
	set(value):
		if current_energy != value:
			var old_value: int = current_energy
			current_energy = clamp(value, 0, max_energy)
			_emit_change("energy_changed", old_value, current_energy)

@export var max_energy: int = 3:
	set(value):
		if max_energy != value:
			var old_value: int = max_energy
			max_energy = max(1, value)
			# Adjust current energy if it exceeds new max
			if current_energy > max_energy:
				current_energy = max_energy
			_emit_change("max_energy_changed", old_value, max_energy)

# Sanity stats
@export var current_sanity: int = 100:
	set(value):
		if current_sanity != value:
			var old_value: int = current_sanity
			current_sanity = clamp(value, 0, max_sanity)
			_emit_change("sanity_changed", old_value, current_sanity)
			
			# Check for insanity
			if current_sanity <= 0 and old_value > 0:
				_emit_change("went_insane", null, null)

@export var max_sanity: int = 100:
	set(value):
		if max_sanity != value:
			var old_value: int = max_sanity
			max_sanity = max(1, value)
			# Adjust current sanity if it exceeds new max
			if current_sanity > max_sanity:
				current_sanity = max_sanity
			_emit_change("max_sanity_changed", old_value, max_sanity)

# Defense (temporary defense)
@export var defense: int = 0:
	set(value):
		if defense != value:
			var old_value: int = defense
			defense = max(0, value)
			_emit_change("defense_changed", old_value, defense)

# Gold (currency)
@export var current_gold: int = 0:
	set(value):
		if current_gold != value:
			var old_value: int = current_gold
			current_gold = max(0, value)
			_emit_change("gold_changed", old_value, current_gold)

# Change tracking system - since Resources don't have signals, we use a callback system
var _change_listeners: Array[Callable] = []

# Add a callback to be notified of stat changes
func add_change_listener(callback: Callable) -> void:
	if callback not in _change_listeners:
		_change_listeners.append(callback)

# Remove a callback from change notifications
func remove_change_listener(callback: Callable) -> void:
	_change_listeners.erase(callback)

# Emit change notification to all listeners
func _emit_change(change_type: String, old_value: Variant, new_value: Variant) -> void:
	for callback in _change_listeners:
		callback.call(change_type, old_value, new_value)

# Utility methods

# Check if the entity is alive (health > 0)
func is_alive() -> bool:
	return current_health > 0

# Check if the entity is dead
func is_dead() -> bool:
	return current_health <= 0

# Check if the entity is sane (sanity > 0)
func is_sane() -> bool:
	return current_sanity > 0

# Check if the entity is insane
func is_insane() -> bool:
	return current_sanity <= 0

# Get health as percentage (0.0 to 1.0)
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

# Get energy as percentage (0.0 to 1.0)
func get_energy_percentage() -> float:
	if max_energy <= 0:
		return 0.0
	return float(current_energy) / float(max_energy)

# Get sanity as percentage (0.0 to 1.0)
func get_sanity_percentage() -> float:
	if max_sanity <= 0:
		return 0.0
	return float(current_sanity) / float(max_sanity)

# Stat modification methods

# Take damage, returns actual damage taken after defense
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var actual_damage: int = amount
	
	# Apply defense reduction
	if defense > 0:
		var defense_reduction: int = min(defense, amount)
		actual_damage -= defense_reduction
		defense -= defense_reduction
	
	# Apply remaining damage to health
	if actual_damage > 0:
		current_health -= actual_damage
		
		# Check for death
		if current_health <= 0 and (current_health + actual_damage) > 0:
			_emit_change("died", null, null)
	
	return actual_damage

# Heal health, capped at max_health
func heal(amount: int) -> void:
	if amount > 0:
		current_health = min(current_health + amount, max_health)

# Restore energy, capped at max_energy
func restore_energy(amount: int) -> void:
	if amount > 0:
		current_energy = min(current_energy + amount, max_energy)

# Spend energy if available, returns true if successful
func spend_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		return true
	return false

# Restore sanity, capped at max_sanity
func restore_sanity(amount: int) -> void:
	if amount > 0:
		current_sanity = min(current_sanity + amount, max_sanity)

# Lose sanity
func lose_sanity(amount: int) -> void:
	if amount > 0:
		current_sanity -= amount

# Gain defense
func gain_defense(amount: int) -> void:
	if amount > 0:
		defense = defense + amount  # Use assignment to trigger setter and signal

# Lose defense
func lose_defense(amount: int) -> void:
	if amount > 0:
		defense = max(0, defense - amount)

# Gain gold
func gain_gold(amount: int) -> void:
	if amount > 0:
		current_gold = current_gold + amount  # Use assignment to trigger setter and signal

# Spend gold if available, returns true if successful
func spend_gold(amount: int) -> bool:
	if current_gold >= amount:
		current_gold -= amount
		return true
	return false

# Check if can afford gold cost
func can_afford_gold(amount: int) -> bool:
	return current_gold >= amount

# Max stat modification methods

# Modify maximum health (can be negative)
func modify_max_health(change: int) -> void:
	max_health += change

# Modify maximum energy (can be negative)
func modify_max_energy(change: int) -> void:
	max_energy += change

# Modify maximum sanity (can be negative)
func modify_max_sanity(change: int) -> void:
	max_sanity += change

# Reset methods

# Reset all current stats to their maximum values
func reset_to_max() -> void:
	current_health = max_health
	current_energy = max_energy
	current_sanity = max_sanity
	defense = 0

# Reset energy to maximum (for new turn)
func reset_energy() -> void:
	current_energy = max_energy

# Serialization support (Resources handle this automatically, but we can add custom logic)

# Get save data dictionary for custom serialization if needed
func get_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"current_energy": current_energy,
		"max_energy": max_energy,
		"current_sanity": current_sanity,
		"max_sanity": max_sanity,
		"defense": defense
	}

# Load stats from save data dictionary
func load_from_data(data: Dictionary) -> void:
	current_health = data.get("current_health", current_health)
	max_health = data.get("max_health", max_health)
	current_energy = data.get("current_energy", current_energy)
	max_energy = data.get("max_energy", max_energy)
	current_sanity = data.get("current_sanity", current_sanity)
	max_sanity = data.get("max_sanity", max_sanity)
	defense = data.get("defense", defense)

# Debug methods

# Print current stats for debugging
func print_status() -> void:
	print("Stats: %d/%d HP, %d/%d Energy, %d/%d Sanity, %d Defense" % [
		current_health, max_health,
		current_energy, max_energy, 
		current_sanity, max_sanity,
		defense
	])
