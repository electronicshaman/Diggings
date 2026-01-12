extends RefCounted
class_name StatusEffectInstance
## Runtime instance of a status effect with current stack count.
## Created when a status is applied to an entity.

const DEBUG_ENABLED: bool = false

## The data resource defining this effect's behavior
var effect_data: StatusEffectData

## Current number of stacks
var current_stacks: int = 1

## Entity that applied this effect (for tracking source)
var source_entity: Resource

## Emitted when stack count changes
signal stacks_changed(old_stacks: int, new_stacks: int)

## Emitted when effect expires (stacks reach 0)
signal effect_expired()


func _init(data: StatusEffectData, stacks: int = 1, source: Resource = null) -> void:
	effect_data = data
	source_entity = source
	if data and data.max_stacks > 0:
		current_stacks = mini(stacks, data.max_stacks)
	else:
		current_stacks = stacks


## Add stacks to this effect, respecting max_stacks
func add_stacks(amount: int) -> void:
	var old_stacks := current_stacks
	current_stacks += amount
	if effect_data and effect_data.max_stacks > 0:
		current_stacks = mini(current_stacks, effect_data.max_stacks)
	if current_stacks != old_stacks:
		stacks_changed.emit(old_stacks, current_stacks)


## Remove stacks from this effect. Returns true if effect expired.
func remove_stacks(amount: int) -> bool:
	var old_stacks := current_stacks
	current_stacks = maxi(0, current_stacks - amount)
	if current_stacks != old_stacks:
		stacks_changed.emit(old_stacks, current_stacks)
	if current_stacks <= 0:
		effect_expired.emit()
		return true
	return false


## Set stacks directly (used for refresh_duration and take_higher behaviors)
func set_stacks(amount: int) -> void:
	var old_stacks := current_stacks
	if effect_data and effect_data.max_stacks > 0:
		current_stacks = mini(amount, effect_data.max_stacks)
	else:
		current_stacks = amount
	if current_stacks != old_stacks:
		stacks_changed.emit(old_stacks, current_stacks)


## Get total value based on stacks (flat calculation)
func get_total_value() -> float:
	if not effect_data:
		return 0.0
	return effect_data.value_per_stack * current_stacks


## Get capped percentage value (for percentage-based effects like Thorns/Drain)
func get_capped_percentage() -> float:
	if not effect_data:
		return 0.0
	var total := effect_data.value_per_stack * current_stacks
	if effect_data.is_percentage:
		return minf(total, effect_data.percentage_cap)
	return total


## Get the display description with current stacks
func get_description() -> String:
	if not effect_data:
		return ""
	return effect_data.get_description(current_stacks)


## Check if this effect should decay at the given phase
func should_decay_at(phase: String) -> bool:
	if not effect_data:
		return false
	return effect_data.should_decay_at(phase)


## Check if this effect triggers at the given phase
func triggers_at(phase: String) -> bool:
	if not effect_data:
		return false
	return effect_data.triggers_at(phase)


## Get save data for persistence
func get_save_data() -> Dictionary:
	return {
		"effect_id": effect_data.effect_id if effect_data else "",
		"stacks": current_stacks
	}
