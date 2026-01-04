extends Node

# Valid mechanical categories
const VALID_CARD_TYPES: Array[String] = ["Attack", "Skill", "Power", "Fortune"]

# Validation helper
static func is_valid_card_type(card_type: String) -> bool:
	return card_type in VALID_CARD_TYPES

# Theme-specific display name mapping
static func get_card_display_name(card_type: String, theme: String = "the_rush") -> String:
	if theme == "the_rush":
		match card_type:
			"Attack":
				return "Gold"
			"Skill":
				return "Grit"
			"Power":
				return "Grog"
			"Fortune":
				return "Gamble"
	return card_type  # Fallback to mechanical name



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

static func get_card_handling_display_name(handling: String) -> String:
	match handling:
		"Standard":
			return "Standard"
		"Equipped":
			return "Equipped"
		"Flash":
			return "Flash"
		"Keep":
			return "Keep"
		"Hold":
			return "Hold"
		"Oneshot":
			return "Oneshot"
		_:
			return handling

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
			return {
				"discards_after_use": true,
				"discards_end_of_turn": false,
				"starts_in_hand": false,
				"removed_after_use": false,
				"triggers_on_draw": false
			}
