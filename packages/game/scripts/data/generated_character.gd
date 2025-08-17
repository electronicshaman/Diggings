extends Resource
class_name GeneratedCharacter

# Represents a fully generated character with procedural backstory
# This extends the base character class concept with narrative elements

# ============================================
# CHARACTER IDENTITY
# ============================================
@export_group("Identity")
@export var full_name: String = ""  # e.g., "Martha Sullivan"
@export var nickname: String = ""  # e.g., "Goldpan"
@export var formatted_name: String = ""  # e.g., "Martha 'Goldpan' Sullivan"
@export var character_class: String = "Prospector"  # Base class
@export var generation_seed: int = 0  # Seed used to generate this character

# ============================================
# BACKSTORY ELEMENTS
# ============================================
@export_group("Backstory")
@export var origin: Resource  # BackstoryElement resource
@export var tragedy: Resource  # BackstoryElement resource
@export var motivation: Resource  # BackstoryElement resource
@export var quirk: Resource  # BackstoryElement resource
@export_multiline var backstory_summary: String = ""  # Generated narrative summary

# Backstory element IDs for save/load
@export var origin_id: String = ""
@export var tragedy_id: String = ""
@export var motivation_id: String = ""
@export var quirk_id: String = ""

# ============================================
# STARTING CONDITIONS
# ============================================
@export_group("Starting Conditions")
@export var starting_curio: Resource  # CurioData resource
@export var starting_curio_id: String = ""  # For save/load
@export var starting_deck: Array[Resource] = []  # Starting deck cards
@export var starting_gold: int = 10
@export var starting_corruption: int = 0

# ============================================
# BASE STATS (Modified by backstory)
# ============================================
@export_group("Stats")
@export var base_health: int = 50
@export var base_sanity: int = 100
@export var base_energy: int = 3
@export var base_defense: int = 0

# ============================================
# MODIFIERS FROM BACKSTORY
# ============================================
@export_group("Modifiers")
@export var stat_modifiers: Dictionary = {}  # Flat stat changes
@export var percentage_modifiers: Dictionary = {}  # Percentage multipliers
@export var special_modifiers: Dictionary = {}  # Complex gameplay changes
@export var gameplay_rules: Array[String] = []  # Special rules/restrictions

# ============================================
# OBJECTIVES AND GOALS
# ============================================
@export_group("Objectives")
@export var has_special_objective: bool = false
@export var objective_type: String = ""  # "gold_target", "time_limit", etc.
@export var objective_value: int = 0
@export var objective_description: String = ""
@export var objective_reward: String = ""
@export var objective_deadline: int = -1  # Turn/day limit if applicable

# ============================================
# DIALOGUE AND FLAVOR
# ============================================
@export_group("Dialogue")
@export var greeting_bark: String = ""  # Character's greeting
@export var victory_bark: String = ""  # Victory quote
@export var defeat_bark: String = ""  # Defeat quote
@export var special_barks: Dictionary = {}  # Contextual dialogue

# ============================================
# HELPER METHODS
# ============================================

func apply_backstory_modifiers() -> void:
	"""Apply all backstory element modifiers to this character."""
	var elements = [origin, tragedy, motivation, quirk]
	
	# Apply stat modifiers from each element
	for element in elements:
		if element and element is BackstoryElement:
			# Apply stat modifiers
			for stat in element.stat_modifiers:
				match stat:
					"base_health":
						base_health += element.stat_modifiers[stat]
					"base_sanity":
						base_sanity += element.stat_modifiers[stat]
					"base_energy":
						base_energy += element.stat_modifiers[stat]
					"starting_gold":
						starting_gold += element.stat_modifiers[stat]
					"starting_corruption":
						starting_corruption += element.stat_modifiers[stat]
			
			# Merge percentage modifiers
			for modifier in element.percentage_modifiers:
				if percentage_modifiers.has(modifier):
					percentage_modifiers[modifier] += element.percentage_modifiers[modifier]
				else:
					percentage_modifiers[modifier] = element.percentage_modifiers[modifier]
			
			# Merge special modifiers
			for modifier in element.special_modifiers:
				special_modifiers[modifier] = element.special_modifiers[modifier]
			
			# Append gameplay rules
			gameplay_rules.append_array(element.gameplay_rules)

func get_modifier_dict() -> Dictionary:
	"""Get a dictionary representation of all modifiers for processing."""
	return {
		"base_health": base_health,
		"base_sanity": base_sanity,
		"base_energy": base_energy,
		"starting_gold": starting_gold,
		"starting_corruption": starting_corruption,
		"stat_modifiers": stat_modifiers,
		"percentage_modifiers": percentage_modifiers,
		"special_modifiers": special_modifiers,
		"gameplay_rules": gameplay_rules
	}

func apply_modifier_dict(mod_dict: Dictionary) -> void:
	"""Apply a modifier dictionary back to this character."""
	if mod_dict.has("base_health"):
		base_health = mod_dict["base_health"]
	if mod_dict.has("base_sanity"):
		base_sanity = mod_dict["base_sanity"]
	if mod_dict.has("base_energy"):
		base_energy = mod_dict["base_energy"]
	if mod_dict.has("starting_gold"):
		starting_gold = mod_dict["starting_gold"]
	if mod_dict.has("starting_corruption"):
		starting_corruption = mod_dict["starting_corruption"]
	if mod_dict.has("stat_modifiers"):
		stat_modifiers = mod_dict["stat_modifiers"]
	if mod_dict.has("percentage_modifiers"):
		percentage_modifiers = mod_dict["percentage_modifiers"]
	if mod_dict.has("special_modifiers"):
		special_modifiers = mod_dict["special_modifiers"]
	if mod_dict.has("gameplay_rules"):
		gameplay_rules = mod_dict["gameplay_rules"]
	if mod_dict.has("objective"):
		var obj = mod_dict["objective"]
		has_special_objective = true
		objective_type = obj.get("type", "")
		objective_value = obj.get("value", 0)
		objective_reward = obj.get("reward", "")

func generate_backstory_summary() -> String:
	"""Generate a narrative summary from backstory elements."""
	var parts: Array[String] = []
	
	if origin:
		parts.append(origin.description)
	
	if tragedy:
		parts.append(tragedy.description)
	
	if motivation:
		parts.append("Now driven by " + motivation.description.to_lower())
	
	if quirk:
		parts.append("Known for " + quirk.description.to_lower())
	
	var summary = ". ".join(parts)
	if summary != "":
		summary += "."
	else:
		summary = "A " + character_class.to_lower() + " seeking fortune in the goldfields."
	
	backstory_summary = summary
	return summary

func get_modifier_summary() -> String:
	"""Get a UI-friendly summary of all modifiers."""
	var summary_parts = []
	
	# Check backstory elements for summaries
	if origin and origin.has_method("get_modifier_summary"):
		var origin_mods = origin.get_modifier_summary()
		if origin_mods != "No modifiers":
			summary_parts.append(origin_mods)
	
	# Add objective if present
	if has_special_objective:
		summary_parts.append(objective_description)
	
	# Add any special rules
	for rule in gameplay_rules:
		summary_parts.append(rule.replace("_", " ").capitalize())
	
	return "\n".join(summary_parts) if summary_parts.size() > 0 else "No special modifiers"

func get_class_color() -> Color:
	"""Get the color associated with this character's class."""
	match character_class:
		"Bushranger":
			return Color(0.8, 0.2, 0.2)  # Red
		"Prospector":
			return Color(0.8, 0.7, 0.2)  # Gold
		"Tracker":
			return Color(0.2, 0.6, 0.2)  # Green
		"Publican":
			return Color(0.4, 0.2, 0.6)  # Purple
		_:
			return Color.WHITE

func get_save_data() -> Dictionary:
	"""Get save data for this character."""
	return {
		"full_name": full_name,
		"nickname": nickname,
		"formatted_name": formatted_name,
		"character_class": character_class,
		"generation_seed": generation_seed,
		"origin_id": origin_id,
		"tragedy_id": tragedy_id,
		"motivation_id": motivation_id,
		"quirk_id": quirk_id,
		"starting_curio_id": starting_curio_id,
		"backstory_summary": backstory_summary,
		"stats": {
			"base_health": base_health,
			"base_sanity": base_sanity,
			"base_energy": base_energy,
			"starting_gold": starting_gold,
			"starting_corruption": starting_corruption
		},
		"modifiers": {
			"stat_modifiers": stat_modifiers,
			"percentage_modifiers": percentage_modifiers,
			"special_modifiers": special_modifiers,
			"gameplay_rules": gameplay_rules
		},
		"objective": {
			"has_objective": has_special_objective,
			"type": objective_type,
			"value": objective_value,
			"description": objective_description,
			"reward": objective_reward,
			"deadline": objective_deadline
		}
	}

func load_from_save_data(data: Dictionary) -> void:
	"""Load character from save data."""
	full_name = data.get("full_name", "")
	nickname = data.get("nickname", "")
	formatted_name = data.get("formatted_name", "")
	character_class = data.get("character_class", "Prospector")
	generation_seed = data.get("generation_seed", 0)
	origin_id = data.get("origin_id", "")
	tragedy_id = data.get("tragedy_id", "")
	motivation_id = data.get("motivation_id", "")
	quirk_id = data.get("quirk_id", "")
	starting_curio_id = data.get("starting_curio_id", "")
	backstory_summary = data.get("backstory_summary", "")
	
	if data.has("stats"):
		var stats = data["stats"]
		base_health = stats.get("base_health", 50)
		base_sanity = stats.get("base_sanity", 100)
		base_energy = stats.get("base_energy", 3)
		starting_gold = stats.get("starting_gold", 10)
		starting_corruption = stats.get("starting_corruption", 0)
	
	if data.has("modifiers"):
		var mods = data["modifiers"]
		stat_modifiers = mods.get("stat_modifiers", {})
		percentage_modifiers = mods.get("percentage_modifiers", {})
		special_modifiers = mods.get("special_modifiers", {})
		gameplay_rules = mods.get("gameplay_rules", [])
	
	if data.has("objective"):
		var obj = data["objective"]
		has_special_objective = obj.get("has_objective", false)
		objective_type = obj.get("type", "")
		objective_value = obj.get("value", 0)
		objective_description = obj.get("description", "")
		objective_reward = obj.get("reward", "")
		objective_deadline = obj.get("deadline", -1)
