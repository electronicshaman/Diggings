extends Resource
class_name Stats

# Stats Resource - Handles health, energy, sanity, and cover with change tracking
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

# Cover (temporary defense)
@export var cover: int = 0:
	set(value):
		if cover != value:
			var old_value: int = cover
			cover = max(0, value)
			_emit_change("cover_changed", old_value, cover)

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

# Take damage, returns actual damage taken after cover
func take_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var actual_damage: int = amount
	
	# Apply cover reduction
	if cover > 0:
		var cover_reduction: int = min(cover, amount)
		actual_damage -= cover_reduction
		cover -= cover_reduction
	
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

# Gain cover
func gain_cover(amount: int) -> void:
	if amount > 0:
		cover = cover + amount  # Use assignment to trigger setter and signal

# Lose cover
func lose_cover(amount: int) -> void:
	if amount > 0:
		cover = max(0, cover - amount)

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
	cover = 0

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
		"cover": cover
	}

# Load stats from save data dictionary
func load_from_data(data: Dictionary) -> void:
	current_health = data.get("current_health", current_health)
	max_health = data.get("max_health", max_health)
	current_energy = data.get("current_energy", current_energy)
	max_energy = data.get("max_energy", max_energy)
	current_sanity = data.get("current_sanity", current_sanity)
	max_sanity = data.get("max_sanity", max_sanity)
	cover = data.get("cover", cover)

# Debug methods

# Print current stats for debugging
func print_status() -> void:
	print("Stats: %d/%d HP, %d/%d Energy, %d/%d Sanity, %d Cover" % [
		current_health, max_health,
		current_energy, max_energy, 
		current_sanity, max_sanity,
		cover
	])