extends CardEffect
class_name CardPeek

const EFFECT_NAME := "Card Peek"

# Card Peek Effect - Look at top cards of deck and optionally draw one
# Used for Prospector's Instinct and similar information advantage cards

@export var peek_count: int = 3  # Number of cards to look at
@export var draw_count: int = 1  # Number of cards to draw from those peeked
@export var exhaust_chance: float = 0.5  # Chance the card exhausts after use (0.5 = 50% chance to not exhaust)
@export var reorder: bool = false  # Whether player can reorder the cards

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add card peek to results
	if not results.has("card_peek"):
		results.card_peek = []
	
	results.card_peek.append({
		"peek_count": peek_count,
		"draw_count": draw_count,
		"exhaust_chance": exhaust_chance,
		"reorder": reorder
	})
	
	print("Applied %s effect from %s (peek %d, draw %d)" % [
		get_effect_name(), 
		card_data.card_name, 
		peek_count,
		draw_count
	])

func get_formatted_description() -> String:
	var base_desc: String
	
	if draw_count > 0:
		if draw_count == 1:
			base_desc = "Look at top %d cards, choose 1 to draw" % peek_count
		else:
			base_desc = "Look at top %d cards, choose %d to draw" % [peek_count, draw_count]
	else:
		base_desc = "Look at top %d cards" % peek_count
	
	if reorder:
		base_desc += " and reorder them"
	
	if exhaust_chance < 1.0 and exhaust_chance > 0.0:
		var keep_chance: int = int(exhaust_chance * 100)
		base_desc += ". %d%% chance to not exhaust" % keep_chance
	
	return base_desc

func get_effect_name() -> String:
	return EFFECT_NAME