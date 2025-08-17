extends CardEffect
class_name NextDuelBonus

const EFFECT_NAME := "Next Duel Bonus"

# Next Duel Bonus - Persistent rewards that carry to the next encounter
# "Victory's spoils echo into the next battle"

enum BonusType {
	CARD_DRAW,      # Extra cards at duel start
	HEALTH_BONUS,   # Extra health at duel start  
	ENERGY_BONUS,   # Extra energy at duel start
	DEFENSE_BONUS,    # Start with defense points
	FREE_CARDS,     # Next X cards cost 0 energy
	COST_REDUCTION  # First X cards cost -1 energy
}

@export var bonus_type: BonusType = BonusType.CARD_DRAW
@export var bonus_amount: int = 2


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add next duel bonus to results
	if not results.has("next_duel_bonus"):
		results.next_duel_bonus = []
	
	results.next_duel_bonus.append(get_bonus_data())
	
	print("Applied %s effect from %s (%s: %d)" % [get_effect_name(), card_data.card_name, BonusType.keys()[bonus_type], bonus_amount])

func get_formatted_description() -> String:
	match bonus_type:
		BonusType.CARD_DRAW:
			return "Next duel: Start with +%d cards" % bonus_amount
		BonusType.HEALTH_BONUS:
			return "Next duel: Start with +%d health" % bonus_amount
		BonusType.ENERGY_BONUS:
			return "Next duel: Start with +%d energy" % bonus_amount
		BonusType.DEFENSE_BONUS:
			return "Next duel: Start with %d defense" % bonus_amount
		BonusType.FREE_CARDS:
			return "Next duel: First %d cards cost 0 energy" % bonus_amount
		BonusType.COST_REDUCTION:
			return "Next duel: First %d cards cost -1 energy" % bonus_amount
		_:
			return "Next duel bonus"

func get_effect_name() -> String:
	return EFFECT_NAME

func get_bonus_data() -> Dictionary:
	"""Get the bonus data for storage in GameState"""
	return {
		"type": bonus_type,
		"amount": bonus_amount
	}