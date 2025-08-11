extends Resource
class_name BackstoryElement

# Base class for all backstory elements (origins, tragedies, motivations, quirks)
# These define the procedural narrative and mechanical modifiers for generated characters

# ============================================
# CORE PROPERTIES
# ============================================
@export_group("Identity")
@export var element_id: String = ""  # Unique identifier like "failed_banker"
@export_enum("origin", "tragedy", "motivation", "quirk") var element_type: String = "origin"
@export var display_name: String = ""  # Human-readable name
@export_multiline var description: String = ""  # Full narrative description
@export_multiline var flavor_text: String = ""  # Optional atmospheric text

# ============================================
# GENERATION WEIGHTS
# ============================================
@export_group("Generation")
@export var weight: float = 10.0  # Base weight for random selection
@export var class_compatibility: Dictionary = {
	"Bushranger": 1.0,
	"Prospector": 1.0,
	"Tracker": 1.0,
	"Publican": 1.0
}  # Multipliers for each class (0.5 = rare, 2.0 = common)

# ============================================
# GAME MODIFIERS
# ============================================
@export_group("Stat Modifiers")
@export var stat_modifiers: Dictionary = {}  # Direct stat changes like {"max_health": 5, "starting_gold": 20}
@export var percentage_modifiers: Dictionary = {}  # Percentage changes like {"gold_gain": 0.1, "corruption_rate": -0.2}

@export_group("Special Modifiers")
@export var special_modifiers: Dictionary = {}  # Complex modifiers like {"shop_price_per_visit": 0.05}
@export var gameplay_rules: Array[String] = []  # Special rules like "cannot_enter_turn_13"
@export var conditional_modifiers: Array[Dictionary] = []  # Modifiers with conditions

# ============================================
# NARRATIVE CONNECTIONS
# ============================================
@export_group("Graph Grammar")
@export var compatible_next_elements: Array[String] = []  # IDs of elements that can follow this one
@export var incompatible_elements: Array[String] = []  # IDs of elements that conflict with this
@export var required_elements: Array[String] = []  # IDs of elements that must be present

# ============================================
# OBJECTIVES AND REWARDS
# ============================================
@export_group("Objectives")
@export var adds_objective: bool = false
@export var objective_type: String = ""  # "gold_target", "time_limit", "kill_count", etc.
@export var objective_value: int = 0  # Target value for objective
@export var objective_reward: String = ""  # Reward for completing objective

# ============================================
# UI AND PRESENTATION
# ============================================
@export_group("Presentation")
@export var icon: Texture2D  # Optional icon for UI
@export var color_theme: Color = Color.WHITE  # Color for UI elements
@export var nickname_pool: Array[String] = []  # Nicknames this element can generate

# ============================================
# HELPER METHODS
# ============================================

func get_weighted_chance_for_class(class_name: String) -> float:
	"""Calculate the weighted chance of this element being selected for a given class."""
	var base_weight = weight
	var class_modifier = class_compatibility.get(class_name, 1.0)
	return base_weight * class_modifier

func is_compatible_with(other_element: BackstoryElement) -> bool:
	"""Check if this element is compatible with another element."""
	if other_element.element_id in incompatible_elements:
		return false
	if required_elements.size() > 0:
		# If we have requirements, the other element must be one of them
		return other_element.element_id in required_elements
	return true

func can_follow(previous_element_id: String) -> bool:
	"""Check if this element can follow a specific previous element in the graph."""
	# If no restrictions, anything can follow
	if compatible_next_elements.is_empty():
		return true
	# Otherwise check if we're in the previous element's next list
	return previous_element_id in compatible_next_elements

func apply_modifiers(character_data: Dictionary) -> void:
	"""Apply this element's modifiers to a character data dictionary."""
	# Apply stat modifiers
	for stat_name in stat_modifiers:
		var current = character_data.get(stat_name, 0)
		character_data[stat_name] = current + stat_modifiers[stat_name]
	
	# Apply percentage modifiers
	for stat_name in percentage_modifiers:
		var modifier_key = stat_name + "_modifier"
		var current = character_data.get(modifier_key, 1.0)
		character_data[modifier_key] = current + percentage_modifiers[stat_name]
	
	# Store special modifiers for later processing
	if not character_data.has("special_modifiers"):
		character_data["special_modifiers"] = {}
	for key in special_modifiers:
		character_data["special_modifiers"][key] = special_modifiers[key]
	
	# Add gameplay rules
	if not character_data.has("gameplay_rules"):
		character_data["gameplay_rules"] = []
	character_data["gameplay_rules"].append_array(gameplay_rules)
	
	# Add objective if present
	if adds_objective:
		character_data["objective"] = {
			"type": objective_type,
			"value": objective_value,
			"reward": objective_reward
		}

func get_nickname() -> String:
	"""Get a random nickname from this element's pool."""
	if nickname_pool.is_empty():
		return ""
	return nickname_pool[randi() % nickname_pool.size()]

func get_short_description() -> String:
	"""Get a brief one-line description for UI."""
	if description.length() > 50:
		return description.substr(0, 47) + "..."
	return description

func get_modifier_summary() -> String:
	"""Generate a human-readable summary of modifiers."""
	var summary_parts = []
	
	# Stat modifiers
	for stat in stat_modifiers:
		var value = stat_modifiers[stat]
		var sign = "+" if value > 0 else ""
		summary_parts.append("%s%d %s" % [sign, value, stat.replace("_", " ")])
	
	# Percentage modifiers
	for stat in percentage_modifiers:
		var value = int(percentage_modifiers[stat] * 100)
		var sign = "+" if value > 0 else ""
		summary_parts.append("%s%d%% %s" % [sign, value, stat.replace("_", " ")])
	
	# Special rules
	for rule in gameplay_rules:
		summary_parts.append(rule.replace("_", " ").capitalize())
	
	return ", ".join(summary_parts) if summary_parts.size() > 0 else "No modifiers"