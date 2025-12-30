extends Resource
class_name CardData

# Theme-agnostic card data resource

@export var card_name: String = "Card"
@export var energy_cost: int = 1
@export var description: String = ""
@export var card_type: String = "Gold"
@export var card_icon: Texture2D
@export var flavor_text: String = ""

# Modular card effects system - temporarily untyped during migration
@export var effects: Array = []

# Core card costs (not effects)
@export var sanity_cost: int = 0  # Cost to sanity when played

# Card durability - number of times card can be played before being removed
@export var base_durability: int = -1  # -1 = infinite, 0+ = limited uses

# Card handling behavior - theme-agnostic strings
@export var card_handling: String = "Standard"

# Type-specific properties
@export var volatile_bonus: bool = false  # For power cards with random effects
@export var luck_modifier: float = 0.0    # For fortune cards that affect RNG

# Character class relationships
@export_group("Class Accessibility")
@export var class_affinity: Array[String] = []  # Empty = all classes can use, populated = restricted
@export var accessibility_tier: String = "Neutral"  # Starting/Class/Neutral/Rare
@export var mechanical_category: String = "Attack"  # Attack/Skill/Power/Fortune

# Helper methods for mechanical behavior
func discards_after_use() -> bool:
	var handling_def: Dictionary = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("discards_after_use"):
		return handling_def["discards_after_use"]
	return true

func discards_end_of_turn() -> bool:
	var handling_def: Dictionary = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("discards_end_of_turn"):
		return handling_def["discards_end_of_turn"]
	return true

func starts_in_hand() -> bool:
	var handling_def: Dictionary = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("starts_in_hand"):
		return handling_def["starts_in_hand"]
	return false

func removed_after_use() -> bool:
	var handling_def: Dictionary = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("removed_after_use"):
		return handling_def["removed_after_use"]
	return false

func triggers_on_draw() -> bool:
	var handling_def: Dictionary = (load("res://scripts/autoloads/theme_manager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("triggers_on_draw"):
		return handling_def["triggers_on_draw"]
	return false

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

func get_mechanical_category() -> String:
	"""Get the theme-agnostic mechanical category"""
	return mechanical_category

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
