extends CardEffect
class_name LuckyStreak

# Lucky Streak - HOLD card that gives increasing luck bonuses for Power cards

@export var luck_bonus_per_power: float = 0.1  # Luck bonus per Power card played
@export var maximum_bonus: float = 0.5            # Cap to prevent absurd luck values
@export var card_type_trigger: String = "Power"  # Card type that triggers the bonus



func _init() -> void:
	effect_name = "Lucky Streak"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add lucky streak to results
	if not results.has("lucky_streak"):
		results.lucky_streak = []
	
	results.lucky_streak.append({
		"luck_bonus_per_power": luck_bonus_per_power,
		"maximum_bonus": maximum_bonus,
		"card_type_trigger": card_type_trigger
	})
	
	print("Applied %s effect from %s (%.1f per %s, max %.1f)" % [effect_name, card_data.card_name, luck_bonus_per_power, card_type_trigger, maximum_bonus])

func get_formatted_description() -> String:
	return "HOLD: Each %s played gives luck_modifier +%.1f (max +%.1f)" % [card_type_trigger, luck_bonus_per_power, maximum_bonus]