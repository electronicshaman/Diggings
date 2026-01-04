extends Resource
class_name CharacterClass

# Basic character information
@export_group("Character Identity")
@export var character_class_name: String = "Bushranger"
@export var description: String = "An outlaw of the Australian bush"
@export var difficulty_rating: int = 2  # 1=Easy, 2=Medium, 3=Hard, 4=Expert

# Starting statistics
@export_group("Starting Stats")
@export var base_health: int = 55
@export var base_sanity: int = 90
@export var base_energy: int = 3
@export var starting_gold: int = 10

# Starting deck composition
@export_group("Starting Deck")
@export var starting_deck_paths: Array[String] = []  # Paths to starting cards (legacy)
@export var starting_deck_resource: String = ""      # Path to DeckData resource (preferred)
@export var starting_deck_size: int = 15

# Character mechanics and abilities
@export_group("Class Mechanics")
@export var passive_abilities: Array[String] = []  # Names of passive abilities
@export var active_abilities: Array[String] = []   # Names of active abilities
@export var unique_resources: Array[String] = []   # e.g., ["Ammo"] for Bushranger

# Card accessibility rules
@export_group("Card Access")
@export var class_exclusive_cards: Array[String] = []  # Card names only this class can use
@export var preferred_card_types: Array[String] = []   # Theme types this class prefers
@export var forbidden_card_types: Array[String] = []   # Theme types this class cannot use

# Character progression
@export_group("Progression")
@export var unlocked_by_default: bool = true
@export var unlock_requirements: Array[String] = []  # Achievement names required
@export var unlock_description: String = ""

# Thematic elements
@export_group("Theme & Flavor")
@export var historical_context: String = ""
@export var motivation: String = ""
@export var signature_quotes: Array[String] = []

func get_display_name() -> String:
	return character_class_name

func get_starting_stats() -> Dictionary:
	return {
		"base_health": base_health,
		"base_sanity": base_sanity, 
		"base_energy": base_energy,
		"starting_gold": starting_gold
	}

func can_use_card(card_data: CardData) -> bool:
	"""Check if this character class can use a specific card"""
	if not card_data:
		return false
		
	# Check if card is forbidden for this class
	if card_data.card_type in forbidden_card_types:
		return false
		
	# Check if card has class affinity restrictions
	if card_data.has_method("get_class_affinity"):
		var affinity = card_data.get_class_affinity()
		if affinity.size() > 0 and not character_class_name in affinity:
			return false
	
	return true

func get_card_preference_weight(card_data: CardData) -> float:
	"""Return weight for card selection (higher = more likely to appear)"""
	if not can_use_card(card_data):
		return 0.0
		
	# Class exclusive cards have highest weight
	if card_data.card_name in class_exclusive_cards:
		return 3.0
		
	# Preferred types get bonus weight
	if card_data.card_type in preferred_card_types:
		return 2.0
	
	# Default neutral weight
	return 1.0

func has_ability(ability_name: String) -> bool:
	"""Check if character has a specific ability"""
	return ability_name in passive_abilities or ability_name in active_abilities

func get_all_abilities() -> Array[String]:
	"""Get combined list of all character abilities"""
	var all_abilities: Array[String] = []
	all_abilities.append_array(passive_abilities)
	all_abilities.append_array(active_abilities)
	return all_abilities

func load_starting_deck() -> Array[CardData]:
	"""Load starting deck cards from DeckData resource or legacy paths"""
	var deck: Array[CardData] = []
	
	# Prefer DeckData resource if available
	if starting_deck_resource != "" and ResourceLoader.exists(starting_deck_resource):
		var deck_data = load(starting_deck_resource) as DeckData
		if deck_data:
			GLog.debug("Loading starting deck from DeckData resource: %s" % starting_deck_resource)
			for card_path in deck_data.card_paths:
				if ResourceLoader.exists(card_path):
					var card_data = load(card_path) as CardData
					if card_data:
						deck.append(card_data)
					else:
						GLog.warn("Failed to load card from DeckData at path: " + card_path)
				else:
					GLog.warn("Card resource from DeckData not found: " + card_path)
		else:
			GLog.error("Failed to load DeckData resource: " + starting_deck_resource)
			# Fall back to legacy method
			return _load_legacy_deck()
	
	# Legacy fallback: load from starting_deck_paths
	elif starting_deck_paths.size() > 0:
		GLog.debug("Loading starting deck from legacy paths")
		return _load_legacy_deck()
	
	else:
		GLog.error("No starting deck configuration found for %s" % character_class_name)
	
	return deck

func _load_legacy_deck() -> Array[CardData]:
	"""Load starting deck from legacy starting_deck_paths array"""
	var deck: Array[CardData] = []
	
	for card_path in starting_deck_paths:
		if ResourceLoader.exists(card_path):
			var card_data = load(card_path) as CardData
			if card_data:
				deck.append(card_data)
			else:
				GLog.warn("Failed to load card at path: " + card_path)
		else:
			GLog.warn("Card resource not found: " + card_path)
	
	# Fill deck to required size by repeating cards
	if deck.size() > 0 and deck.size() < starting_deck_size:
		while deck.size() < starting_deck_size:
			deck.append(deck[deck.size() % starting_deck_paths.size()])
	
	return deck