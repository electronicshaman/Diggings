@static_unload
class_name CardHandling
extends RefCounted
## Static utility class for card handling behavior definitions.
##
## Card handling determines how a card behaves after being played:
## - Standard: Discards after use
## - Equipped: Starts in hand, discards after use
## - Flash: Triggers automatically when drawn
## - Hold: Stays in hand if not played (doesn't discard end of turn)
## - Repeat: Returns to hand after use (for repeatable cards like boomerangs)
## - Oneshot: Removed from deck after use (exhausted)
## - Recycle: Shuffles randomly back into deck after use
## - TopDeck: Returns to top of deck after use (draw next turn)
## - BottomDeck: Returns to bottom of deck after use
## - Exhaust: Removed from deck after use (same as Oneshot)


## Where the card goes after being played/resolved.
enum Destination {
	DISCARD, ## Default - goes to discard pile
	HAND, ## Stays in hand (Keep/Hold)
	EXHAUST, ## Removed from game entirely (Oneshot/Exhaust)
	DECK_SHUFFLE, ## Shuffled randomly into deck (Recycle)
	DECK_TOP, ## Returns to top of deck (TopDeck)
	DECK_BOTTOM, ## Returns to bottom of deck (BottomDeck)
}


## Configuration object for handling properties.
## Uses sensible defaults so only deviations need to be specified.
class HandlingProperties extends RefCounted:
	## Where the card goes after being played.
	var resolution_destination: Destination = Destination.DISCARD
	## Whether the card discards at end of turn (if still in hand).
	var discards_end_of_turn: bool = false
	## Whether the card starts in hand at beginning of combat.
	var starts_in_hand: bool = false
	## Whether the card auto-triggers when drawn.
	var triggers_on_draw: bool = false
	
	## Creates a HandlingProperties with default values.
	func _init() -> void:
		pass
	
	## Creates a HandlingProperties from a dictionary of overrides.
	## Only properties that differ from defaults need to be specified.
	## @param overrides Dictionary of property names to values.
	## @return A new HandlingProperties instance with the overrides applied.
	static func from_overrides(overrides: Dictionary) -> HandlingProperties:
		var props := HandlingProperties.new()
		for key in overrides:
			if key in props:
				props.set(key, overrides[key])
		return props
	
	# --- Convenience getters for common queries ---
	
	## Returns true if card goes to discard pile after use.
	func discards_after_use() -> bool:
		return resolution_destination == Destination.DISCARD
	
	## Returns true if card is removed from game after use.
	func removed_after_use() -> bool:
		return resolution_destination == Destination.EXHAUST
	
	## Returns true if card stays in hand after use.
	func stays_in_hand() -> bool:
		return resolution_destination == Destination.HAND
	
	## Returns true if card returns to deck after use.
	func returns_to_deck() -> bool:
		return resolution_destination in [
			Destination.DECK_SHUFFLE,
			Destination.DECK_TOP,
			Destination.DECK_BOTTOM,
		]


## Data-driven handling definitions.
## Each entry maps a handling type name to a dictionary of property overrides.
## Only properties that differ from defaults need to be specified.
const _HANDLING_DEFINITIONS: Dictionary = {
	"Standard": {},
	"Equipped": {
		"starts_in_hand": true,
	},
	"Flash": {
		"triggers_on_draw": true,
	},
	"Hold": {
		"discards_end_of_turn": false,
	},
	"Repeat": {
		"resolution_destination": Destination.HAND,
	},
	"Oneshot": {
		"resolution_destination": Destination.EXHAUST,
	},
	"Recycle": {
		"resolution_destination": Destination.DECK_SHUFFLE,
	},
	"TopDeck": {
		"resolution_destination": Destination.DECK_TOP,
	},
	"BottomDeck": {
		"resolution_destination": Destination.DECK_BOTTOM,
	},
	"Exhaust": {
		"resolution_destination": Destination.EXHAUST,
	},
}

## Valid card handling types (derived from definitions for single source of truth).
static var VALID_HANDLING_TYPES: Array[String]:
	get:
		var types: Array[String] = []
		for key in _HANDLING_DEFINITIONS.keys():
			types.append(key)
		return types


## Returns true if the given handling type is valid.
## @param handling The handling type string to validate.
## @return True if valid, false otherwise.
static func is_valid_handling(handling: String) -> bool:
	return handling in _HANDLING_DEFINITIONS


## Returns a configuration object defining the behavior of a card handling type.
## @param handling The handling type (Standard, Equipped, Flash, Keep, Hold, Oneshot, Recycle, TopDeck, BottomDeck, Exhaust).
## @return HandlingProperties object with the appropriate configuration.
static func get_handling_definition(handling: String) -> HandlingProperties:
	var overrides: Dictionary = _HANDLING_DEFINITIONS.get(handling, {})
	return HandlingProperties.from_overrides(overrides)
