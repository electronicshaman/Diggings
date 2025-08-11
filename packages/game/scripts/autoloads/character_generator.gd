extends Node

# CharacterGenerator - Handles procedural character generation using seed-based randomization

var backstory_pools: Dictionary = {}
var name_pools: Dictionary = {}
var generation_rules: Dictionary = {}

func _ready():
	load_name_pools()
	load_generation_rules()

func load_name_pools():
	"""Load name pools from JSON file"""
	var file = FileAccess.open("res://data/character_generation/data_pools/names.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			name_pools = json.data
		else:
			GLog.error("Failed to parse names.json: " + str(parse_result))
	else:
		GLog.error("Failed to load names.json")

func load_generation_rules():
	"""Load generation rules from JSON file"""
	var file = FileAccess.open("res://data/character_generation/data_pools/generation_rules.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			generation_rules = json.data
		else:
			GLog.error("Failed to parse generation_rules.json: " + str(parse_result))
	else:
		GLog.error("Failed to load generation_rules.json")

func generate_character(character_class: String) -> GeneratedCharacter:
	"""Generate a character for the given class using current seed"""
	var character = GeneratedCharacter.new()
	character.character_class = character_class
	
	# Generate simple names for now
	var first_name = generate_simple_name(character_class)
	character.nickname = generate_simple_nickname()
	character.full_name = first_name
	character.formatted_name = first_name + " '" + character.nickname + "'"
	
	# Apply base stats for class with some random variation
	var base_stats = get_base_character_stats(character_class)
	character.max_health = base_stats.get("max_health", 50) + SeedManager.get_character_random_int(-5, 10)
	character.max_sanity = base_stats.get("max_sanity", 100) + SeedManager.get_character_random_int(-10, 5)
	character.max_energy = base_stats.get("max_energy", 3)
	character.starting_gold = base_stats.get("starting_gold", 10) + SeedManager.get_character_random_int(-2, 8)
	
	# Load a random starting curio
	character.starting_curio = load_random_starting_curio()
	
	# Generate simple backstory summary
	character.backstory_summary = "A " + character_class.to_lower() + " seeking fortune in the goldfields."
	
	GLog.info("Generated character: " + character.formatted_name + " the " + character_class)
	
	return character

func generate_backstory_chain(character_class: String) -> Array:
	"""Generate a coherent backstory chain using graph grammar rules"""
	var chain: Array = []
	
	# Step 1: Select origin based on class compatibility
	var origin = select_weighted_element(backstory_pools.origins, character_class)
	if origin:
		chain.append(origin)
	
	# Step 2: Select tragedy compatible with origin
	var compatible_tragedies = filter_compatible_elements(backstory_pools.tragedies, chain)
	var tragedy = select_weighted_element(compatible_tragedies, character_class)
	if tragedy:
		chain.append(tragedy)
	
	# Step 3: Select motivation compatible with previous elements
	var compatible_motivations = filter_compatible_elements(backstory_pools.motivations, chain)
	var motivation = select_weighted_element(compatible_motivations, character_class)
	if motivation:
		chain.append(motivation)
	
	# Step 4: Select quirk (optional, 70% chance)
	if SeedManager.get_character_random_float() < 0.7:
		var compatible_quirks = filter_compatible_elements(backstory_pools.quirks, chain)
		var quirk = select_weighted_element(compatible_quirks, character_class)
		if quirk:
			chain.append(quirk)
	
	return chain

func select_weighted_element(elements: Array, character_class: String):
	"""Select an element using weighted random selection based on class compatibility"""
	if elements.is_empty():
		return null
	
	var total_weight = 0.0
	var weights: Array[float] = []
	
	# Calculate weights based on class compatibility and base weight
	for element in elements:
		var class_multiplier = 1.0
		if element.class_compatibility.has(character_class):
			class_multiplier = element.class_compatibility[character_class]
		
		var weight = element.weight * class_multiplier
		weights.append(weight)
		total_weight += weight
	
	# Select based on weighted probability
	var roll = SeedManager.get_character_random_float() * total_weight
	var current_weight = 0.0
	
	for i in range(elements.size()):
		current_weight += weights[i]
		if roll <= current_weight:
			return elements[i]
	
	# Fallback to last element
	return elements[-1]

func filter_compatible_elements(elements: Array, existing_chain: Array) -> Array:
	"""Filter elements that are compatible with the existing backstory chain"""
	var compatible: Array = []
	
	for element in elements:
		var is_compatible = true
		
		# Check required elements
		for required_id in element.required_elements:
			var has_required = false
			for existing in existing_chain:
				if existing.element_id == required_id:
					has_required = true
					break
			if not has_required:
				is_compatible = false
				break
		
		# Check incompatible elements
		if is_compatible:
			for incompatible_id in element.incompatible_elements:
				for existing in existing_chain:
					if existing.element_id == incompatible_id:
						is_compatible = false
						break
				if not is_compatible:
					break
		
		if is_compatible:
			compatible.append(element)
	
	return compatible

func generate_first_name(character_class: String, backstory_chain: Array) -> String:
	"""Generate first name based on class and backstory elements"""
	if not name_pools.has(character_class.to_lower()):
		return "Unknown"
	
	var class_names = name_pools[character_class.to_lower()]
	
	# Determine cultural background from backstory
	var culture_key = "generic"
	
	for element in backstory_chain:
		if element.element_id == "aboriginal_guide":
			culture_key = "aboriginal"
			break
		elif element.element_id == "failed_banker":
			culture_key = "irish"
			break
		elif element.element_id == "wrongly_accused":
			culture_key = "welsh"
			break
		elif element.element_id == "inherited_pub":
			culture_key = "english"
			break
	
	# Select from appropriate cultural pool
	if class_names.has(culture_key) and not class_names[culture_key].is_empty():
		var names = class_names[culture_key]
		return names[SeedManager.get_character_random_int(0, names.size() - 1)]
	elif class_names.has("generic") and not class_names["generic"].is_empty():
		var names = class_names["generic"]
		return names[SeedManager.get_character_random_int(0, names.size() - 1)]
	
	return "Unknown"

func generate_nickname(backstory_chain: Array) -> String:
	"""Generate nickname from backstory elements"""
	var all_nicknames: Array[String] = []
	
	# Collect all possible nicknames from backstory elements
	for element in backstory_chain:
		all_nicknames.append_array(element.nickname_pool)
	
	if all_nicknames.is_empty():
		return "The Wanderer"
	
	return all_nicknames[SeedManager.get_character_random_int(0, all_nicknames.size() - 1)]

func select_starting_curio(character_class: String, backstory_chain: Array) -> Resource:
	"""Select starting curio based on class and backstory"""
	if not generation_rules.has("starting_curios"):
		return load("res://data/curios/starting/lucky_nugget.tres")
	
	var curio_weights = generation_rules.starting_curios
	var class_key = character_class.to_lower()
	
	if not curio_weights.has(class_key):
		return load("res://data/curios/starting/lucky_nugget.tres")
	
	var weights = curio_weights[class_key]
	
	# Modify weights based on backstory elements
	var modified_weights = weights.duplicate()
	for element in backstory_chain:
		if element.element_id == "aboriginal_guide":
			modified_weights["old_compass"] = modified_weights.get("old_compass", 10.0) * 2.0
		elif element.element_id == "family_held_hostage":
			modified_weights["canvas_bag"] = modified_weights.get("canvas_bag", 10.0) * 1.5
		elif element.element_id == "inherited_pub":
			modified_weights["iron_horseshoe"] = modified_weights.get("iron_horseshoe", 10.0) * 1.5
	
	# Select curio using weighted selection
	var total_weight = 0.0
	for weight in modified_weights.values():
		total_weight += weight
	
	var roll = SeedManager.get_character_random_float() * total_weight
	var current_weight = 0.0
	
	for curio_name in modified_weights:
		current_weight += modified_weights[curio_name]
		if roll <= current_weight:
			var curio_path = "res://data/curios/starting/" + curio_name + ".tres"
			return load(curio_path)
	
	return load("res://data/curios/starting/lucky_nugget.tres")

func calculate_stat_modifiers(backstory_chain: Array) -> Dictionary:
	"""Calculate combined stat modifiers from backstory elements"""
	var modifiers = {}
	
	for element in backstory_chain:
		for stat in element.stat_modifiers:
			var current = modifiers.get(stat, 0)
			modifiers[stat] = current + element.stat_modifiers[stat]
	
	return modifiers

func calculate_percentage_modifiers(backstory_chain: Array) -> Dictionary:
	"""Calculate combined percentage modifiers from backstory elements"""
	var modifiers = {}
	
	for element in backstory_chain:
		for modifier in element.percentage_modifiers:
			var current = modifiers.get(modifier, 0.0)
			modifiers[modifier] = current + element.percentage_modifiers[modifier]
	
	return modifiers

func calculate_special_modifiers(backstory_chain: Array) -> Dictionary:
	"""Calculate combined special modifiers from backstory elements"""
	var modifiers = {}
	
	for element in backstory_chain:
		for modifier in element.special_modifiers:
			modifiers[modifier] = element.special_modifiers[modifier]
	
	return modifiers

func generate_character_set(classes: Array[String]) -> Array[GeneratedCharacter]:
	"""Generate a set of characters for the given classes"""
	var characters: Array[GeneratedCharacter] = []
	
	for character_class in classes:
		var character = generate_character(character_class)
		characters.append(character)
	
	return characters

func get_base_character_stats(character_class: String) -> Dictionary:
	"""Get base stats for a character class"""
	match character_class:
		"Bushranger":
			return {"max_health": 55, "max_sanity": 90, "max_energy": 3, "starting_gold": 10}
		"Prospector":
			return {"max_health": 45, "max_sanity": 95, "max_energy": 3, "starting_gold": 15}
		"Tracker":
			return {"max_health": 50, "max_sanity": 105, "max_energy": 3, "starting_gold": 8}
		"Publican":
			return {"max_health": 60, "max_sanity": 85, "max_energy": 3, "starting_gold": 20}
		_:
			return {"max_health": 50, "max_sanity": 100, "max_energy": 3, "starting_gold": 10}

func generate_simple_name(character_class: String) -> String:
	var names = ["Jack", "Mary", "William", "Sarah", "Thomas", "Elizabeth", "James", "Margaret", "John", "Catherine"]
	return names[SeedManager.get_character_random_int(0, names.size() - 1)]

func generate_simple_nickname() -> String:
	var nicknames = ["The Bold", "Lucky", "Ironhand", "Quickdraw", "Goldseeker", "Stormcrow", "Dusty", "Fierce", "Steady", "Wildfire"]
	return nicknames[SeedManager.get_character_random_int(0, nicknames.size() - 1)]

func load_random_starting_curio() -> Resource:
	var curios = [
		"res://data/curios/starting/lucky_nugget.tres",
		"res://data/curios/starting/thick_leather.tres", 
		"res://data/curios/starting/old_compass.tres",
		"res://data/curios/starting/worn_boots.tres"
	]
	var curio_path = curios[SeedManager.get_character_random_int(0, curios.size() - 1)]
	return load(curio_path)
