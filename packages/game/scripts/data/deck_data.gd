extends Resource
class_name DeckData

const DEBUG_ENABLED: bool = true

# Deck metadata
@export var deck_name: String = ""
@export var description: String = ""
@export var deck_theme: String = ""  # "aggressive", "defensive", "cunning", "balanced", etc.
@export var difficulty_level: int = 1  # 1-5 scale for AI difficulty tuning

# Card composition
@export var card_paths: Array[String] = []
@export var min_deck_size: int = 8
@export var max_deck_size: int = 20

# Deck strategy hints for AI
@export var preferred_strategy: String = "balanced"  # "aggressive", "control", "combo", "tempo"
@export var priority_card_types: Array[String] = []  # Types this deck prioritizes playing

func _init(name: String = "", theme: String = "balanced") -> void:
	if DEBUG_ENABLED:
		GLog.debug("Initializing DeckData: name='%s', theme='%s'" % [name, theme])
	deck_name = name
	deck_theme = theme
	if DEBUG_ENABLED:
		GLog.debug("DeckData initialized")

# Convert this deck to a CardPile resource
func to_card_pile() -> CardPile:
	if DEBUG_ENABLED:
		GLog.debug("Converting DeckData '%s' to CardPile" % deck_name)
	var pile = CardPile.new("deck")
	
	var loaded_count = 0
	for path in card_paths:
		var card_data: CardData = load(path) as CardData
		if card_data:
			# Create CardInstance via compatibility helper
			pile.add_card_data(card_data)
			loaded_count += 1
			if DEBUG_ENABLED:
				GLog.trace("Loaded card %d/%d: '%s'" % [loaded_count, card_paths.size(), card_data.card_name])
		else:
			GLog.error("Failed to load card from path: %s" % path)
	
	if DEBUG_ENABLED:
		GLog.debug("DeckData converted: %d/%d cards loaded successfully" % [loaded_count, card_paths.size()])
	return pile

# Get total card count in this deck
func get_card_count() -> int:
	var count = card_paths.size()
	if DEBUG_ENABLED:
		GLog.trace("get_card_count() for '%s': %d cards" % [deck_name, count])
	return count

# Validate that all card paths exist and are valid
func validate_deck() -> Dictionary:
	if DEBUG_ENABLED:
		GLog.debug("Validating deck '%s'" % deck_name)
	var result = {
		"valid": true,
		"card_count": card_paths.size(),
		"missing_cards": [],
		"invalid_cards": [],
		"size_valid": true,
		"warnings": []
	}
	
	# Check deck size constraints
	if card_paths.size() < min_deck_size:
		result.valid = false
		result.size_valid = false
		result.warnings.append("Deck too small: %d cards (min %d)" % [card_paths.size(), min_deck_size])
	elif card_paths.size() > max_deck_size:
		result.valid = false
		result.size_valid = false
		result.warnings.append("Deck too large: %d cards (max %d)" % [card_paths.size(), max_deck_size])
	
	# Validate each card path
	var valid_cards = 0
	for i in range(card_paths.size()):
		var path = card_paths[i]
		if not ResourceLoader.exists(path):
			result.valid = false
			result.missing_cards.append({"index": i, "path": path})
			if DEBUG_ENABLED:
				GLog.warn("Missing card resource: %s" % path)
		else:
			var card_data = load(path) as CardData
			if not card_data:
				result.valid = false
				result.invalid_cards.append({"index": i, "path": path})
				if DEBUG_ENABLED:
					GLog.warn("Invalid card resource: %s" % path)
			else:
				valid_cards += 1
	
	if DEBUG_ENABLED:
		GLog.debug("Deck validation complete: %s (%d/%d cards valid)" % ["VALID" if result.valid else "INVALID", valid_cards, card_paths.size()])
	return result

# Add a card to this deck by path
func add_card_by_path(card_path: String) -> bool:
	if DEBUG_ENABLED:
		GLog.debug("Adding card by path to '%s': %s" % [deck_name, card_path])
	
	if not ResourceLoader.exists(card_path):
		GLog.error("Card resource does not exist: %s" % card_path)
		return false
	
	if card_paths.size() >= max_deck_size:
		GLog.warn("Deck at maximum size (%d), cannot add card" % max_deck_size)
		return false
	
	card_paths.append(card_path)
	if DEBUG_ENABLED:
		GLog.debug("Card added successfully. New deck size: %d" % card_paths.size())
	return true

# Remove a card from this deck by path
func remove_card_by_path(card_path: String) -> bool:
	if DEBUG_ENABLED:
		GLog.debug("Removing card by path from '%s': %s" % [deck_name, card_path])
	
	var index = card_paths.find(card_path)
	if index >= 0:
		card_paths.remove_at(index)
		if DEBUG_ENABLED:
			GLog.debug("Card removed successfully. New deck size: %d" % card_paths.size())
		return true
	else:
		if DEBUG_ENABLED:
			GLog.debug("Card not found in deck")
		return false

# Get card type distribution for analysis
func get_type_distribution() -> Dictionary:
	if DEBUG_ENABLED:
		GLog.debug("Analyzing type distribution for '%s'" % deck_name)
	var distribution = {}
	
	for path in card_paths:
		var card_data: CardData = load(path) as CardData
		if card_data:
			var card_type = card_data.card_type
			distribution[card_type] = distribution.get(card_type, 0) + 1
	
	if DEBUG_ENABLED:
		GLog.debug("Type distribution: %s" % str(distribution))
	return distribution

# Get energy cost distribution for analysis
func get_cost_distribution() -> Dictionary:
	if DEBUG_ENABLED:
		GLog.debug("Analyzing cost distribution for '%s'" % deck_name)
	var distribution = {}
	
	for path in card_paths:
		var card_data: CardData = load(path) as CardData
		if card_data:
			var cost = card_data.energy_cost
			distribution[cost] = distribution.get(cost, 0) + 1
	
	if DEBUG_ENABLED:
		GLog.debug("Cost distribution: %s" % str(distribution))
	return distribution

# Create a copy of this deck with shuffled card order
func create_shuffled_copy() -> DeckData:
	if DEBUG_ENABLED:
		GLog.debug("Creating shuffled copy of '%s'" % deck_name)
	var copy = DeckData.new(deck_name + " (Shuffled)", deck_theme)
	copy.description = description
	copy.difficulty_level = difficulty_level
	copy.min_deck_size = min_deck_size
	copy.max_deck_size = max_deck_size
	copy.preferred_strategy = preferred_strategy
	copy.priority_card_types = priority_card_types.duplicate()
	
	# Shuffle the card paths
	copy.card_paths = card_paths.duplicate()
	copy.card_paths.shuffle()
	
	if DEBUG_ENABLED:
		GLog.debug("Shuffled copy created")
	return copy

# Debug method to print deck contents
func print_deck_info() -> void:
	GLog.info("=== Deck: %s ===" % deck_name)
	GLog.info("Theme: %s, Strategy: %s, Difficulty: %d" % [deck_theme, preferred_strategy, difficulty_level])
	GLog.info("Description: %s" % description)
	GLog.info("Cards (%d):" % card_paths.size())
	
	for i in range(card_paths.size()):
		var path = card_paths[i]
		var card_data: CardData = load(path) as CardData
		if card_data:
			GLog.info("  %d. %s (%s, %d energy)" % [i + 1, card_data.card_name, card_data.card_type, card_data.energy_cost])
		else:
			GLog.info("  %d. [INVALID] %s" % [i + 1, path])
	
	GLog.info("================")
