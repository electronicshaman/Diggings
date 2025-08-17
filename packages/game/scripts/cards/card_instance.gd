extends Resource
class_name CardInstance

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED = true

# CardInstance - Runtime wrapper around CardData with instance-specific state
# This allows cards to have dynamic properties like hold counters, upgrades, etc.
# while keeping the original CardData resources immutable.

# Reference to the immutable card template
@export var card_data: CardData

# Runtime instance state
@export var turns_held: int = 0
@export var instance_id: String = ""  # Unique identifier for this instance

# Dynamic properties that override CardData when set
var _dynamic_description: String = ""
var _dynamic_card_handling: String = ""

func _init(data: CardData = null) -> void:
	if data:
		card_data = data
		instance_id = _generate_instance_id()
		GLog.debug("Created CardInstance for '%s' with ID: %s" % [card_data.card_name, instance_id])

func _generate_instance_id() -> String:
	return "%s_%d_%d" % [card_data.resource_path.get_file().get_basename(), Time.get_unix_time_from_system(), randi()]

# Core CardData passthrough properties
func get_card_name() -> String:
	return card_data.card_name if card_data else "Unknown Card"

func get_energy_cost() -> int:
	return card_data.energy_cost if card_data else 0

func get_sanity_cost() -> int:
	return card_data.sanity_cost if card_data else 0

func get_card_type() -> String:
	return card_data.card_type if card_data else ""

func get_card_icon() -> Texture2D:
	return card_data.card_icon if card_data else null

func get_flavor_text() -> String:
	return card_data.flavor_text if card_data else ""

func get_effects() -> Array[CardEffect]:
	return card_data.effects if card_data else []

func get_volatile_bonus() -> bool:
	return card_data.volatile_bonus if card_data else false

func get_luck_modifier() -> float:
	return card_data.luck_modifier if card_data else 0.0

func get_class_affinity() -> Array[String]:
	return card_data.class_affinity if card_data else []

func get_accessibility_tier() -> String:
	return card_data.accessibility_tier if card_data else ""

func get_mechanical_category() -> String:
	return card_data.mechanical_category if card_data else ""

# Dynamic properties with Hold X logic
func get_description() -> String:
	if _dynamic_description != "":
		return _dynamic_description
	
	if not card_data:
		return "Unknown card"
	
	# Check if this card has HoldBonus effects
	var hold_bonus_effect = _get_hold_bonus_effect()
	if hold_bonus_effect:
		return _generate_dynamic_description(hold_bonus_effect)
	
	return card_data.description

func get_card_handling() -> String:
	if _dynamic_card_handling != "":
		return _dynamic_card_handling
	
	if not card_data:
		return "Standard"
	
	# Auto-convert Hold cards to Standard when they reach their threshold
	var hold_bonus_effect = _get_hold_bonus_effect()
	if hold_bonus_effect and card_data.card_handling == "Hold":
		if turns_held >= hold_bonus_effect.turns_required:
			return "Standard"  # Card is "charged up" and should be discarded after use
	
	return card_data.card_handling

# Hold mechanic implementation
func increment_turns_held() -> void:
	turns_held += 1
	GLog.debug("Card '%s' held for %d turns" % [get_card_name(), turns_held])
	_update_dynamic_properties()

func reset_turns_held() -> void:
	if turns_held > 0:
		GLog.debug("Resetting turns_held for '%s' (was %d)" % [get_card_name(), turns_held])
		turns_held = 0
		_update_dynamic_properties()

func is_hold_threshold_reached() -> bool:
	var hold_bonus_effect = _get_hold_bonus_effect()
	if hold_bonus_effect:
		return turns_held >= hold_bonus_effect.turns_required
	return false

# Dynamic property management
func set_dynamic_description(desc: String) -> void:
	_dynamic_description = desc

func set_dynamic_card_handling(handling: String) -> void:
	_dynamic_card_handling = handling

func clear_dynamic_properties() -> void:
	_dynamic_description = ""
	_dynamic_card_handling = ""

# Internal helper methods
func _get_hold_bonus_effect() -> HoldBonus:
	if not card_data or not card_data.effects:
		return null
	
	for effect in card_data.effects:
		if effect is HoldBonus:
			return effect as HoldBonus
	
	return null

func _generate_dynamic_description(hold_bonus: HoldBonus) -> String:
	var base_desc = card_data.description
	
	# If we haven't reached the threshold, show the hold requirement
	if turns_held < hold_bonus.turns_required:
		var _turns_remaining = hold_bonus.turns_required - turns_held
		var bonus_text = hold_bonus.get_formatted_description()
		return "%s %s" % [base_desc, bonus_text]
	else:
		# We've reached the threshold - show the upgraded effect
		return _generate_upgraded_description(hold_bonus)

func _generate_upgraded_description(hold_bonus: HoldBonus) -> String:
	# This is a simplified implementation - you might want to make this more sophisticated
	var base_desc = card_data.description
	
	# Look for base numeric values and add the bonuses
	if hold_bonus.bonus_energy > 0:
		# Try to upgrade energy gain descriptions
		var regex = RegEx.new()
		regex.compile("Gain (\\d+) energy")
		var result = regex.search(base_desc)
		if result:
			var base_energy = result.get_string(1).to_int()
			var new_energy = base_energy + hold_bonus.bonus_energy
			base_desc = base_desc.replace(result.get_string(), "Gain %d energy" % new_energy)
	
	if hold_bonus.bonus_damage > 0:
		# Try to upgrade damage descriptions
		var regex = RegEx.new()
		regex.compile("Deal (\\d+) damage")
		var result = regex.search(base_desc)
		if result:
			var base_damage = result.get_string(1).to_int()
			var new_damage = base_damage + hold_bonus.bonus_damage
			base_desc = base_desc.replace(result.get_string(), "Deal %d damage" % new_damage)
	
	# Add similar logic for defense, healing as needed
	
	return base_desc

func _update_dynamic_properties() -> void:
	# Clear dynamic overrides to force recalculation
	clear_dynamic_properties()
	
	# This will trigger recalculation of description and handling
	get_description()  # Force calculation
	get_card_handling()  # Force calculation

# Serialization support
func get_save_data() -> Dictionary:
	return {
		"card_path": card_data.resource_path if card_data else "",
		"turns_held": turns_held,
		"instance_id": instance_id
	}

func load_from_save_data(data: Dictionary) -> void:
	var card_path = data.get("card_path", "")
	if card_path != "":
		card_data = load(card_path) as CardData
	
	turns_held = data.get("turns_held", 0)
	instance_id = data.get("instance_id", _generate_instance_id())
	
	_update_dynamic_properties()

# Utility methods
func duplicate_instance() -> CardInstance:
	var new_instance = CardInstance.new(card_data)
	new_instance.turns_held = turns_held
	new_instance._dynamic_description = _dynamic_description
	new_instance._dynamic_card_handling = _dynamic_card_handling
	return new_instance

func equals(other: CardInstance) -> bool:
	if not other:
		return false
	return instance_id == other.instance_id

func _to_string() -> String:
	return "CardInstance[%s, held:%d, id:%s]" % [get_card_name(), turns_held, instance_id]