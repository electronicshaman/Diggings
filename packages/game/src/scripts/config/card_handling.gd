@static_unload
class_name CardHandling
extends RefCounted
## Static utility class for card handling behavior definitions.
##
## Card handling determines how a card behaves after being played:
## - Standard: Discards after use
## - Equipped: Starts in hand, discards after use
## - Flash: Triggers automatically when drawn
## - Keep: Stays in hand after use
## - Hold: Stays in hand, doesn't discard end of turn
## - Oneshot: Removed from deck after use (exhausted)
## - Recycle: Shuffles randomly back into deck after use
## - TopDeck: Returns to top of deck after use (draw next turn)
## - BottomDeck: Returns to bottom of deck after use

## Valid card handling types.
const VALID_HANDLING_TYPES: Array[String] = [
	"Standard",
	"Equipped",
	"Flash",
	"Keep",
	"Hold",
	"Oneshot",
	"Recycle",
	"TopDeck",
	"BottomDeck"
]

## Valid deck return positions.
const DECK_RETURN_NONE: String = "none"
const DECK_RETURN_SHUFFLE: String = "shuffle"
const DECK_RETURN_TOP: String = "top"
const DECK_RETURN_BOTTOM: String = "bottom"


## Returns true if the given handling type is valid.
## @param handling The handling type string to validate.
## @return True if valid, false otherwise.
static func is_valid_handling(handling: String) -> bool:
	return handling in VALID_HANDLING_TYPES


## Returns a dictionary defining the behavior of a card handling type.
## @param handling The handling type (Standard, Equipped, Flash, Keep, Hold, Oneshot, Recycle, TopDeck, BottomDeck).
## @return Dictionary with keys: discards_after_use, discards_end_of_turn,
##         starts_in_hand, removed_after_use, triggers_on_draw, deck_return_position.
static func get_handling_definition(handling: String) -> Dictionary:
	match handling:
		"Standard":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Equipped":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": true,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Flash":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": true,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Keep":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Hold":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Oneshot":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": true,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
		"Recycle":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_SHUFFLE
			}
		"TopDeck":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_TOP
			}
		"BottomDeck":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_BOTTOM
			}
		_:
			# Default to Standard behavior for unknown handling types
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false,
				"deck_return_position": DECK_RETURN_NONE
			}
