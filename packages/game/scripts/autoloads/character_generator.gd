extends Node

# CharacterGenerator - Handles procedural character generation using seed-based randomization

const DEBUG_ENABLED: bool = true

var backstory_pools: Dictionary = {}
var name_pools: Dictionary = {}
var generation_rules: Dictionary = {}

func _ready():
	load_name_pools()
	load_generation_rules()
	load_backstory_pools()

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

func load_backstory_pools():
	"""Load all backstory element resources from their directories"""
	backstory_pools = {
		"origins": [],
		"tragedies": [],
		"motivations": [],
		"quirks": []
	}
	
	# Load each category of backstory elements
	_load_backstory_category("origins", "res://data/character_generation/backstory_resources/origins/")
	_load_backstory_category("tragedies", "res://data/character_generation/backstory_resources/tragedies/")
	_load_backstory_category("motivations", "res://data/character_generation/backstory_resources/motivations/")
	_load_backstory_category("quirks", "res://data/character_generation/backstory_resources/quirks/")
	
	GLog.info("Loaded backstory pools - Origins: %d, Tragedies: %d, Motivations: %d, Quirks: %d" % [
		backstory_pools.origins.size(),
		backstory_pools.tragedies.size(), 
		backstory_pools.motivations.size(),
		backstory_pools.quirks.size()
	])

func _load_backstory_category(category_name: String, directory_path: String):
	"""Load all .tres files from a backstory category directory"""
	var dir = DirAccess.open(directory_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource_path = directory_path + file_name
				var element = load(resource_path) as BackstoryElement
				if element:
					backstory_pools[category_name].append(element)
					GLog.debug("Loaded backstory element: " + element.element_id + " (" + category_name + ")")
				else:
					GLog.error("Failed to load backstory element: " + resource_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		GLog.error("Failed to open backstory directory: " + directory_path)

func generate_character(character_class: String) -> GeneratedCharacter:
	"""Generate a character for the given class using current seed"""
	var character = GeneratedCharacter.new()
	character.character_class = character_class
	
	# Generate backstory chain first
	var backstory_chain = generate_backstory_chain(character_class)
	
	# Assign backstory elements to character
	for element in backstory_chain:
		match element.element_type:
			"origin":
				character.origin = element
				character.origin_id = element.element_id
			"tragedy":
				character.tragedy = element
				character.tragedy_id = element.element_id
			"motivation":
				character.motivation = element
				character.motivation_id = element.element_id
			"quirk":
				character.quirk = element
				character.quirk_id = element.element_id
	
	# Generate names based on backstory and class
	var first_name = generate_first_name(character_class, backstory_chain)
	var surname = generate_surname(character_class)
	character.nickname = generate_nickname(backstory_chain)
	character.full_name = first_name + (" " + surname if surname != "" else "")
	character.formatted_name = character.full_name + (" '" + character.nickname + "'" if character.nickname != "" else "")
	
	# Apply base stats for class
	var base_stats = get_base_character_stats(character_class)
	character.base_health = base_stats.get("base_health", 50)
	character.base_sanity = base_stats.get("base_sanity", 100)
	character.base_energy = base_stats.get("base_energy", 3)
	character.starting_gold = base_stats.get("starting_gold", 10)
	character.starting_corruption = 0
	
	# Apply backstory modifiers
	var stat_mods = calculate_stat_modifiers(backstory_chain)
	var percent_mods = calculate_percentage_modifiers(backstory_chain)
	var special_mods = calculate_special_modifiers(backstory_chain)
	
	# Apply stat modifiers
	for stat in stat_mods:
		match stat:
			"base_health":
				character.base_health += stat_mods[stat]
			"base_sanity":
				character.base_sanity += stat_mods[stat]
			"base_energy":
				character.base_energy += stat_mods[stat]
			"starting_gold":
				character.starting_gold += stat_mods[stat]
			"starting_corruption":
				character.starting_corruption += stat_mods[stat]
	
	# Store modifiers in character
	character.stat_modifiers = stat_mods
	character.percentage_modifiers = percent_mods
	character.special_modifiers = special_mods
	
	# Collect gameplay rules from all backstory elements
	var all_rules: Array[String] = []
	for element in backstory_chain:
		all_rules.append_array(element.gameplay_rules)
	character.gameplay_rules = all_rules
	
	# Select starting curio based on backstory
	character.starting_curio = select_starting_curio(character_class, backstory_chain)
	character.starting_curio_id = _get_curio_id_from_resource(character.starting_curio)
	
	# Generate rich backstory summary
	character.backstory_summary = character.generate_backstory_summary()
	
	# Check for objectives from backstory elements
	for element in backstory_chain:
		if element.adds_objective:
			character.has_special_objective = true
			character.objective_type = element.objective_type
			character.objective_value = element.objective_value
			character.objective_reward = element.objective_reward
			character.objective_description = element.description
			break
	
	# Add some random variation within bounds
	character.base_health += SeedManager.get_character_random_int(-3, 5)
	character.base_sanity += SeedManager.get_character_random_int(-5, 5)
	character.starting_gold += SeedManager.get_character_random_int(-2, 5)
	
	# Ensure minimum values
	character.base_health = max(character.base_health, 25)
	character.base_sanity = max(character.base_sanity, 50)
	character.starting_gold = max(character.starting_gold, 0)
	
	GLog.info("Generated character: " + character.formatted_name + " the " + character_class)
	GLog.debug("Backstory chain length: " + str(backstory_chain.size()))
	
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
	if not class_names.has("first_names"):
		return "Unknown"
		
	var first_names = class_names["first_names"]
	
	# Determine cultural background from backstory
	var culture_key = "english"  # Default culture
	
	for element in backstory_chain:
		if element.element_id == "aboriginal_guide":
			# For tracker class, check if we have aboriginal names
			if character_class.to_lower() == "tracker" and first_names.has("aboriginal"):
				culture_key = "aboriginal"
			elif first_names.has("mixed"):
				culture_key = "mixed"
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
	
	# Check for class-specific culture preferences
	if character_class.to_lower() == "tracker":
		# Tracker has special name categories
		if first_names.has("frontier"):
			culture_key = "frontier"
		elif first_names.has("aboriginal"):
			culture_key = "aboriginal"
	elif character_class.to_lower() == "publican":
		# Publican might use working_class names
		if first_names.has("working_class"):
			culture_key = "working_class"
	elif character_class.to_lower() == "bushranger":
		# Bushranger might use australian_born names
		if first_names.has("australian_born"):
			culture_key = "australian_born"
	elif character_class.to_lower() == "prospector":
		# Prospector has many cultural options, keep backstory-determined culture
		pass
	
	# Select from appropriate cultural pool
	if first_names.has(culture_key) and not first_names[culture_key].is_empty():
		var names = first_names[culture_key]
		return names[SeedManager.get_character_random_int(0, names.size() - 1)]
	elif first_names.has("english") and not first_names["english"].is_empty():
		var names = first_names["english"]
		return names[SeedManager.get_character_random_int(0, names.size() - 1)]
	
	return "Unknown"

func generate_surname(character_class: String) -> String:
	"""Generate surname based on character class"""
	if not name_pools.has(character_class.to_lower()):
		return ""
	
	var class_names = name_pools[character_class.to_lower()]
	if not class_names.has("surnames") or class_names["surnames"].is_empty():
		return ""
	
	var surnames = class_names["surnames"]
	return surnames[SeedManager.get_character_random_int(0, surnames.size() - 1)]

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
	"""Get base stats for a character class from the character resource"""
	var character_path = "res://data/characters/" + character_class.to_lower() + ".tres"
	
	if ResourceLoader.exists(character_path):
		var character_resource = load(character_path) as CharacterClass
		if character_resource:
			return character_resource.get_starting_stats()
	
	GLog.warn("Failed to load character resource for %s, using fallback stats" % character_class)
	# Fallback stats if resource loading fails
	return {"base_health": 50, "base_sanity": 100, "base_energy": 3, "starting_gold": 10}

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

func _get_curio_id_from_resource(curio_resource: Resource) -> String:
	"""Extract curio ID from resource path"""
	if not curio_resource:
		return ""
	
	var resource_path = curio_resource.resource_path
	if resource_path == "":
		return ""
	
	# Extract filename without extension from path like "res://data/curios/starting/lucky_nugget.tres"
	var filename = resource_path.get_file().get_basename()
	return filename
