extends Resource
class_name CardInstance

# Per-file debug control (GLog will check this)
const DEBUG_ENABLED = true

# CardInstance - Runtime wrapper around CardData with instance-specific state
# This allows cards to have dynamic properties like hold counters, upgrades, etc.
# while keeping the original CardData resources immutable.

# Reference to the immutable card template
@export var card_data: CardData

# Card ownership tracking
enum Owner { PLAYER, ENEMY, NEUTRAL }
@export var owner: Owner = Owner.PLAYER

# Runtime instance state
@export var turns_held: int = 0
@export var instance_id: String = ""  # Unique identifier for this instance

# Durability tracking
@export var current_durability: int = -1  # Current durability, initialized from card_data.base_durability

# Dynamic properties that override CardData when set
var _dynamic_description: String = ""
var _dynamic_card_handling: String = ""

func _init(data: CardData = null, card_owner: Owner = Owner.PLAYER) -> void:
	if data:
		card_data = data
		owner = card_owner
		instance_id = _generate_instance_id()
		current_durability = data.base_durability
		GLog.debug("Created CardInstance for '%s' with ID: %s, owner: %s, durability: %d" % [card_data.card_name, instance_id, "PLAYER" if owner == Owner.PLAYER else ("ENEMY" if owner == Owner.ENEMY else "NEUTRAL"), current_durability])

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

func get_effects() -> Array:
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

# Durability methods
func get_base_durability() -> int:
	return card_data.base_durability if card_data else -1

func get_current_durability() -> int:
	return current_durability

func has_durability() -> bool:
	return get_base_durability() > 0

func is_broken() -> bool:
	return has_durability() and current_durability <= 0

func decrement_durability() -> bool:
	if not has_durability():
		return false
	
	current_durability -= 1
	GLog.debug("Card '%s' durability decremented to %d/%d" % [get_card_name(), current_durability, get_base_durability()])
	
	if is_broken():
		GLog.info("Card '%s' is broken (durability reached 0)" % get_card_name())
		return true
	
	return false

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
		var turns_required = hold_bonus_effect.get("turns_required", 2)
		if turns_held >= turns_required:
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
		var turns_required = hold_bonus_effect.get("turns_required", 2)
		return turns_held >= turns_required
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
func _get_hold_bonus_effect():
	if not card_data or not card_data.effects:
		return null
	
	for effect in card_data.effects:
		# Check if this effect has hold bonus characteristics (duck typing)
		if effect.has_method("get_effect_name") and "Hold" in effect.get_effect_name():
			return effect

	return null

func _generate_dynamic_description(hold_bonus) -> String:
	var base_desc = card_data.description
	
	# If we have a hold bonus effect, try to get its description
	if hold_bonus and hold_bonus.has_method("get_formatted_description"):
		var turns_required = hold_bonus.get("turns_required", 2)
		
		# If we haven't reached the threshold, show the hold requirement
		if turns_held < turns_required:
			var bonus_text = hold_bonus.get_formatted_description()
			return "%s %s" % [base_desc, bonus_text]
		else:
			# We've reached the threshold - show the upgraded effect
			return _generate_upgraded_description(hold_bonus)
	
	return base_desc

func _generate_upgraded_description(hold_bonus) -> String:
	# This is a simplified implementation - you might want to make this more sophisticated
	var base_desc = card_data.description
	
	# Handle both GameEffect and CardEffect hold bonuses
	if hold_bonus.has("bonus_energy") and hold_bonus.bonus_energy > 0:
		# Try to upgrade energy gain descriptions
		var regex = RegEx.new()
		regex.compile("Gain (\\d+) energy")
		var result = regex.search(base_desc)
		if result:
			var base_energy = result.get_string(1).to_int()
			var new_energy = base_energy + hold_bonus.bonus_energy
			base_desc = base_desc.replace(result.get_string(), "Gain %d energy" % new_energy)
	
	if hold_bonus.has("bonus_damage") and hold_bonus.bonus_damage > 0:
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
		"instance_id": instance_id,
		"current_durability": current_durability
	}

func load_from_save_data(data: Dictionary) -> void:
	var card_path = data.get("card_path", "")
	if card_path != "":
		card_data = load(card_path) as CardData
	
	turns_held = data.get("turns_held", 0)
	instance_id = data.get("instance_id", _generate_instance_id())
	current_durability = data.get("current_durability", card_data.base_durability if card_data else -1)
	
	_update_dynamic_properties()

# Description generation (instance-aware)
func get_effect_descriptions(separator: String = " ") -> String:
	"""Generate descriptions that account for conditional effects and runtime state"""
	if not card_data or not card_data.effects:
		return ""
	
	var descriptions: Array[String] = []
	for effect in card_data.effects:
		var desc = ""
		
		# Check if this is a GameEffect with conditional values
		if effect.has_method("get") and effect.get("conditional_values") != null:
			var conditional_values = effect.get("conditional_values")
			if conditional_values is Array and conditional_values.size() > 0:
				desc = _generate_conditional_description(effect)
			else:
				desc = _get_standard_description(effect)
		else:
			desc = _get_standard_description(effect)
		
		desc = desc.strip_edges()
		if desc != "":
			descriptions.append(desc)
	
	return separator.join(descriptions)

func _generate_conditional_description(effect: Resource) -> String:
	"""Generate description showing all conditional outcomes"""
	var conditional_values = effect.get("conditional_values")
	if not conditional_values or conditional_values.size() == 0:
		return _get_standard_description(effect)

	# Get curio bonuses if available
	# Note: CardInstance descriptions are typically for player cards (hand, deck, shop, etc.)
	# Enemy cards rarely show full descriptions, so defaulting to true is safe
	var curio_damage_bonus = 0
	var curio_defense_bonus = 0
	if CurioManager and card_data:
		var mods = CurioManager.calculate_card_modifications(card_data, true)
		curio_damage_bonus = mods.get("damage", 0)
		curio_defense_bonus = mods.get("defense", 0)

	# Get the base description for the effect type
	var base_text = _get_effect_base_description(effect)

	# Find conditional values for important properties
	for cv in conditional_values:
		if cv.property_name == "amount":
			var condition_desc = cv.condition.get_description() if cv.condition else "unknown condition"

			# Generate conditional text based on effect type
			if effect.get_script().get_global_name() == "DamageEffect":
				var val_true = cv.value_if_true
				var val_false = cv.value_if_false
				if curio_damage_bonus > 0:
					return "Deal %d [color=gold](+%d)[/color] damage if %s, otherwise deal %d [color=gold](+%d)[/color] damage" % [
						val_true, curio_damage_bonus, condition_desc, val_false, curio_damage_bonus
					]
				else:
					return "Deal %d damage if %s, otherwise deal %d damage" % [
						val_true, condition_desc, val_false
					]
			elif effect.get_script().get_global_name() == "DefenseEffect":
				var val_true = cv.value_if_true
				var val_false = cv.value_if_false
				if curio_defense_bonus > 0:
					return "Gain %d [color=gold](+%d)[/color] block if %s, otherwise gain %d [color=gold](+%d)[/color] block" % [
						val_true, curio_defense_bonus, condition_desc, val_false, curio_defense_bonus
					]
				else:
					return "Gain %d block if %s, otherwise gain %d block" % [
						val_true, condition_desc, val_false
					]
			elif effect.get_script().get_global_name() == "CardManipulationEffect":
				var action = effect.get("action") if effect.get("action") else "draw"
				if cv.value_if_false == 0:
					return "%s %d card(s) if %s" % [action.capitalize(), cv.value_if_true, condition_desc]
				else:
					return "%s %d card(s) if %s, otherwise %s %d card(s)" % [
						action.capitalize(), cv.value_if_true, condition_desc,
						action, cv.value_if_false
					]

	# Fallback to standard description if we can't handle the conditional
	return _get_standard_description(effect)

func _get_standard_description(effect: Resource) -> String:
	"""Get standard description for an effect"""
	# Create context with curio modifications ONCE for all paths
	var preview_context = EffectContext.new() if EffectContext else null
	if preview_context and card_data:
		preview_context.source_type = "card"
		preview_context.source_object = card_data
		# Populate curio modifications for preview
		# Note: CardInstance descriptions are typically for player cards (hand, deck, shop, etc.)
		if CurioManager:
			preview_context.curio_modifications = CurioManager.calculate_card_modifications(card_data, true)

	# Use the context for all description methods
	if effect.has_method("get_formatted_description"):
		return effect.get_formatted_description(preview_context)
	elif effect.has_method("get_preview_text"):
		return effect.get_preview_text(preview_context)
	elif "description" in effect:
		return str(effect.description)
	else:
		return ""

func _get_effect_base_description(effect: Resource) -> String:
	"""Get the basic description template for an effect type"""
	# This could be expanded to provide base templates for different effect types
	return _get_standard_description(effect)

# Utility methods
func duplicate_instance() -> CardInstance:
	var new_instance = CardInstance.new(card_data)
	new_instance.turns_held = turns_held
	new_instance.current_durability = current_durability
	new_instance._dynamic_description = _dynamic_description
	new_instance._dynamic_card_handling = _dynamic_card_handling
	return new_instance

func equals(other: CardInstance) -> bool:
	if not other:
		return false
	return instance_id == other.instance_id

func _to_string() -> String:
	if has_durability():
		return "CardInstance[%s, held:%d, durability:%d/%d, id:%s]" % [get_card_name(), turns_held, current_durability, get_base_durability(), instance_id]
	else:
		return "CardInstance[%s, held:%d, id:%s]" % [get_card_name(), turns_held, instance_id]
