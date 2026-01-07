extends Resource
class_name CardData

# Card data resource - defines card properties and effects

@export var card_name: String = "Card"
@export var energy_cost: int = 1
@export var description: String = ""
@export var card_type: String = "Attack"
@export var card_icon: Texture2D
@export var flavor_text: String = ""

# Modular card effects system - temporarily untyped during migration
@export var effects: Array = []

# Core card costs (not effects)
@export var sanity_cost: int = 0 # Cost to sanity when played

# Custom resource costs (e.g. {"Ammo": 1, "Faith": 2})
@export var unique_resource_costs: Dictionary = {}

# Card durability - number of times card can be played before being removed
@export var base_durability: int = -1 # -1 = infinite, 0+ = limited uses

# Card handling behavior (Standard/Equipped/Flash/Keep/Hold/Oneshot)
@export var card_handling: String = "Standard"

# Type-specific properties
@export var volatile_bonus: bool = false # For power cards with random effects
@export var luck_modifier: float = 0.0 # For fortune cards that affect RNG

# Character class relationships
@export_group("Class Accessibility")
@export var class_affinity: Array[String] = [] # Empty = all classes can use, populated = restricted
@export var accessibility_tier: String = "Neutral" # Starting/Class/Neutral/Rare

@export_group("Rarity")
@export var rarity: String = "Common" # Common, Uncommon, Rare, Eldritch

# Helper methods for mechanical behavior
func discards_after_use() -> bool:
	var handling_def: Dictionary = CardTypeUtils.get_card_handling_definition(card_handling)
	return handling_def.get("discards_after_use", true)

func discards_end_of_turn() -> bool:
	var handling_def: Dictionary = CardTypeUtils.get_card_handling_definition(card_handling)
	return handling_def.get("discards_end_of_turn", true)

func starts_in_hand() -> bool:
	var handling_def: Dictionary = CardTypeUtils.get_card_handling_definition(card_handling)
	return handling_def.get("starts_in_hand", false)

func removed_after_use() -> bool:
	var handling_def: Dictionary = CardTypeUtils.get_card_handling_definition(card_handling)
	return handling_def.get("removed_after_use", false)

func triggers_on_draw() -> bool:
	var handling_def: Dictionary = CardTypeUtils.get_card_handling_definition(card_handling)
	return handling_def.get("triggers_on_draw", false)

# Class affinity helper methods
func get_class_affinity() -> Array[String]:
	"""Get list of character classes that can use this card"""
	return class_affinity

func is_available_to_class(character_class: String) -> bool:
	"""Check if this card is available to a specific character class"""
	# Empty affinity means available to all classes
	if class_affinity.is_empty():
		return true
	# Otherwise check if class is in affinity list
	return character_class in class_affinity

func get_accessibility_tier() -> String:
	"""Get the accessibility tier (Starting/Class/Neutral/Rare)"""
	return accessibility_tier

func is_starting_card() -> bool:
	"""Check if this card appears in starting decks"""
	return accessibility_tier == "Starting"

func is_class_card() -> bool:
	"""Check if this card is class-specific content"""
	return accessibility_tier == "Class"

func is_neutral_card() -> bool:
	"""Check if this card is available to all classes"""
	return accessibility_tier == "Neutral"

# Card type helper methods
func is_attack() -> bool:
	"""Check if this card is an Attack type"""
	return card_type == "Attack"

func is_skill() -> bool:
	"""Check if this card is a Skill type"""
	return card_type == "Skill"

func is_power() -> bool:
	"""Check if this card is a Power type"""
	return card_type == "Power"

func is_fortune() -> bool:
	"""Check if this card is a Fortune type"""
	return card_type == "Fortune"

# --- Description generation helpers ---
# Prefer effect-provided descriptions as the source of truth. These helpers let
# UIs/tooltips render dynamic, parameterized text without relying on duplicated
# strings saved into .tres resources.

func get_effect_descriptions(separator: String = " ") -> String:
	"""Join effect descriptions using get_formatted_description() where available.
	Fallback to effect.description if needed. Skips empty strings."""
	if not (effects is Array) or effects.is_empty():
		return ""

	var parts: Array[String] = []
	for effect in effects:
		if not is_instance_valid(effect):
			continue
		var text := ""
		if effect.has_method("get_formatted_description"):
			text = str(effect.get_formatted_description())
		elif "description" in effect:
			text = str(effect.description)
		text = text.strip_edges()
		if text != "":
			parts.append(text)

	return separator.join(parts)

func get_display_description(prefer_generated: bool = true, separator: String = " ") -> String:
	"""Return the description to display. If prefer_generated is true, try to
	build from effects first; otherwise, use the card's description and fall back
	to generated when empty."""
	if prefer_generated:
		var gen := get_effect_descriptions(separator)
		if gen != "":
			return gen
		# Fallback to explicit card description
		return description
	# Not preferring generated: honor explicit description first
	if description and description.strip_edges() != "":
		return description
	return get_effect_descriptions(separator)

func has_first_card_played_condition() -> bool:
	"""Check if this card has quick draw/first turn mechanics (FIRST_CARD_PLAYED condition)"""
	if not (effects is Array) or effects.is_empty():
		return false

	for effect in effects:
		if not is_instance_valid(effect):
			continue

		# Check direct activation_condition on effect
		if "activation_condition" in effect and effect.activation_condition:
			var condition = effect.activation_condition
			if "condition_type" in condition:
				if condition.condition_type == 0: # ConditionType.FIRST_CARD_PLAYED
					return true

		# Check conditional_values array for conditional damage/draw amounts
		if "conditional_values" in effect and effect.conditional_values is Array:
			for conditional_value in effect.conditional_values:
				if "condition" in conditional_value and conditional_value.condition:
					var condition = conditional_value.condition
					if "condition_type" in condition:
						if condition.condition_type == 0: # ConditionType.FIRST_CARD_PLAYED
							return true

	return false
