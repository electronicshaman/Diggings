extends Resource
class_name CardData

# Theme-agnostic card data resource

@export var card_name: String = "Card"
@export var energy_cost: int = 1
@export var description: String = ""
@export var card_type: String = "Gold"
@export var card_icon: Texture2D
@export var flavor_text: String = ""

# Modular card effects system
@export var effects: Array[CardEffect] = []

# Core card costs (not effects)
@export var sanity_cost: int = 0  # Cost to sanity when played

# Card handling behavior - theme-agnostic strings
@export var card_handling: String = "Standard"

# Type-specific properties
@export var volatile_bonus: bool = false  # For power cards with random effects
@export var luck_modifier: float = 0.0    # For fortune cards that affect RNG

# Helper methods for mechanical behavior
func discards_after_use() -> bool:
	if not ThemeManager:
		return true
	var handling_def: Dictionary = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("discards_after_use"):
		return handling_def["discards_after_use"]
	return true

func discards_end_of_turn() -> bool:
	if not ThemeManager:
		return true
	var handling_def: Dictionary = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("discards_end_of_turn"):
		return handling_def["discards_end_of_turn"]
	return true

func starts_in_hand() -> bool:
	if not ThemeManager:
		return false
	var handling_def: Dictionary = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("starts_in_hand"):
		return handling_def["starts_in_hand"]
	return false

func removed_after_use() -> bool:
	if not ThemeManager:
		return false
	var handling_def: Dictionary = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("removed_after_use"):
		return handling_def["removed_after_use"]
	return false

func triggers_on_draw() -> bool:
	if not ThemeManager:
		return false
	var handling_def: Dictionary = (load("res://scripts/theme/ThemeManager.gd") as GDScript).get_card_handling_definition(card_handling)
	if handling_def.has("triggers_on_draw"):
		return handling_def["triggers_on_draw"]
	return false
