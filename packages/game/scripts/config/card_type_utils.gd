class_name CardTypeUtils
extends RefCounted
## Static utility class for card type validation and visual properties.
## Replaces ThemeManager with direct mechanical card type handling.

# Valid mechanical card categories
const VALID_CARD_TYPES: Array[String] = ["Attack", "Skill", "Power", "Fortune"]

# Valid card handling types
const VALID_HANDLING_TYPES: Array[String] = ["Standard", "Equipped", "Flash", "Keep", "Hold", "Oneshot"]


## Returns true if the given card type is valid (Attack/Skill/Power/Fortune)
static func is_valid_card_type(card_type: String) -> bool:
	return card_type in VALID_CARD_TYPES


## Returns the color associated with a card type
static func get_card_color(card_type: String) -> Color:
	match card_type:
		"Attack":
			return Color(0.831, 0.686, 0.216)  # Gold
		"Skill":
			return Color(0.545, 0.271, 0.075)  # Brown
		"Power":
			return Color(0.722, 0.525, 0.043)  # Amber
		"Fortune":
			return Color(0.133, 0.545, 0.133)  # Green
		_:
			return Color.WHITE


## Returns the emoji symbol associated with a card type
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


## Returns a dictionary defining the behavior of a card handling type.
## Keys: discards_after_use, discards_end_of_turn, starts_in_hand, removed_after_use, triggers_on_draw
static func get_card_handling_definition(handling: String) -> Dictionary:
	match handling:
		"Standard":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
		"Equipped":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": true,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
		"Flash":
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": true
			}
		"Keep":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
		"Hold":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
		"Oneshot":
			return {
				"discards_after_use": false,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": true,
				"triggers_on_draw": false
			}
		_:
			# Default to Standard behavior for unknown handling types
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
