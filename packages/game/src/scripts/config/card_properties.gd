@static_unload
class_name CardProperties
extends RefCounted
## Static utility class for card type and rarity properties.
##
## Provides validation and visual properties for:
## - Card types (Attack, Skill, Power, Fortune)
## - Card rarities (Common, Uncommon, Rare, Eldritch, etc.)
##
## For card handling behavior (Standard, Equipped, Flash, etc.),
## see CardHandling class.


#region Card Types

## Valid mechanical card categories.
const VALID_CARD_TYPES: Array[String] = [
	"Attack",
	"Skill",
	"Power",
	"Fortune"
]


## Returns true if the given card type is valid.
## @param card_type The card type string to validate.
## @return True if valid (Attack/Skill/Power/Fortune), false otherwise.
static func is_valid_card_type(card_type: String) -> bool:
	return card_type in VALID_CARD_TYPES


## Returns the color associated with a card type.
## @param card_type The card type (Attack, Skill, Power, Fortune).
## @return Color for the card type, defaults to WHITE for unknown types.
static func get_card_color(card_type: String) -> Color:
	match card_type:
		"Attack":
			return Color(0.831, 0.686, 0.216) # Gold
		"Skill":
			return Color(0.545, 0.271, 0.075) # Brown
		"Power":
			return Color(0.722, 0.525, 0.043) # Amber
		"Fortune":
			return Color(0.133, 0.545, 0.133) # Green
		_:
			return Color.WHITE


## Returns the emoji symbol associated with a card type.
## @param card_type The card type (Attack, Skill, Power, Fortune).
## @return Emoji string for the card type.
static func get_card_symbol(card_type: String) -> String:
	match card_type:
		"Attack":
			return "🔫"
		"Skill":
			return "🛡"
		"Power":
			return "🍺"
		"Fortune":
			return "🎲"
		_:
			return "?"

#endregion


#region Rarities

## Valid rarity levels for cards.
const VALID_CARD_RARITIES: Array[String] = [
	"Common",
	"Uncommon",
	"Rare",
	"Eldritch"
]

## Valid rarity levels for curios.
const VALID_CURIO_RARITIES: Array[String] = [
	"Common",
	"Rare",
	"Legendary",
	"Corrupted"
]

## Valid rarity levels for encounters.
const VALID_ENCOUNTER_RARITIES: Array[String] = [
	"Common",
	"Rare",
	"Legendary",
	"Story"
]


## Returns true if the given rarity is valid for cards.
## @param rarity The rarity string to validate.
## @return True if valid, false otherwise.
static func is_valid_card_rarity(rarity: String) -> bool:
	return rarity in VALID_CARD_RARITIES


## Returns the color associated with a rarity level.
## @param rarity The rarity (Common, Uncommon, Rare, Legendary, Eldritch, Corrupted, Story).
## @return Color for the rarity, defaults to WHITE for unknown rarities.
static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"Common":
			return Color.GRAY
		"Uncommon":
			return Color.LIME
		"Rare":
			return Color.CYAN
		"Legendary":
			return Color.GOLD
		"Eldritch":
			return Color.DARK_VIOLET
		"Corrupted":
			return Color.PURPLE
		"Story":
			return Color.PURPLE
		_:
			return Color.WHITE

#endregion
