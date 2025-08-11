extends Resource
class_name CurioData

# Theme-agnostic curio data resource
# Curios are persistent modifiers that last throughout a run

# Basic Information
@export var curio_name: String = "Curio"
@export var description: String = ""
@export var icon: Texture2D
@export var flavor_text: String = ""

# Mechanical Properties
@export_enum("Passive", "Triggered", "Modifier", "Resource") var mechanical_category: String = "Passive"
@export_enum("Common", "Rare", "Legendary", "Corrupted") var rarity: String = "Common"
@export var stackable: bool = false
@export var max_stacks: int = 1

# Modular effects system (like cards)
@export var effects: Array[Resource] = []  # Array of CurioEffect resources

# Costs and Requirements
@export var corruption_cost: int = 0  # For corrupted curios
@export var gold_cost: int = 100  # Default shop price
@export var unlock_requirement: String = ""  # Optional unlock condition

# Class Relationships (synergy scores)
@export_group("Class Synergy")
@export var bushranger_synergy: float = 1.0  # 1.0 = neutral, >1.0 = good synergy
@export var prospector_synergy: float = 1.0
@export var tracker_synergy: float = 1.0
@export var publican_synergy: float = 1.0

# Visual Properties
@export_group("Visual")
@export var glow_color: Color = Color.WHITE
@export var trigger_particle: PackedScene  # Optional particle effect on trigger

# Helper methods
func get_synergy_for_class(class_name: String) -> float:
	match class_name.to_lower():
		"bushranger":
			return bushranger_synergy
		"prospector":
			return prospector_synergy
		"tracker":
			return tracker_synergy
		"publican":
			return publican_synergy
		_:
			return 1.0

func get_rarity_color() -> Color:
	match rarity:
		"Common":
			return Color.GRAY
		"Rare":
			return Color.CYAN
		"Legendary":
			return Color.GOLD
		"Corrupted":
			return Color.PURPLE
		_:
			return Color.WHITE

func get_shop_price() -> int:
	# Base price modified by rarity
	var base_price = gold_cost
	match rarity:
		"Common":
			base_price = int(base_price * 1.0)
		"Rare":
			base_price = int(base_price * 1.5)
		"Legendary":
			base_price = int(base_price * 2.5)
		"Corrupted":
			base_price = int(base_price * 0.8)  # Cheaper but has corruption cost
	return base_price

func can_stack_with(other_curio: CurioData) -> bool:
	return stackable and curio_name == other_curio.curio_name

func get_formatted_description() -> String:
	var desc = description
	if corruption_cost > 0:
		desc += "\n[color=purple]Corruption Cost: %d[/color]" % corruption_cost
	return desc

func has_trigger_event(event_name: String) -> bool:
	for effect in effects:
		if effect and effect.trigger_event == event_name:
			return true
	return false

func apply_effects(trigger_event: String, game_state: Node, context: Dictionary) -> void:
	for effect in effects:
		if effect and effect.trigger_event == trigger_event:
			if effect.can_trigger(game_state, context):
				effect.apply_effect(game_state, self, context)