extends Node



static func get_card_color(card_type: String) -> Color:
	match card_type:
		"Gold":
			return Color(0.831, 0.686, 0.216)
		"Grit":
			return Color(0.545, 0.271, 0.075)
		"Grog":
			return Color(0.722, 0.525, 0.043)
		"Gamble":
			return Color(0.133, 0.545, 0.133)
		_:
			return Color.WHITE

static func get_card_symbol(card_type: String) -> String:
	match card_type:
		"Gold":
			return "🔫"
		"Grit":
			return "🛡"
		"Grog":
			return "🍺"
		"Gamble":
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
