extends CardEffect
class_name HoldBonus

const EFFECT_NAME := "Hold Bonus"

# Generic hold-based bonus effect - theme agnostic
# Cards get stronger when held in hand for X turns
# Can provide damage, defense, healing, or energy bonuses

@export var turns_required: int = 2          # How many turns to hold for bonus
@export var bonus_damage: int = 0            # Bonus damage when threshold met
@export var bonus_defense: int = 0           # Bonus block when threshold met  
@export var bonus_healing: int = 0           # Bonus healing when threshold met
@export var bonus_energy: int = 0            # Bonus energy when threshold met
@export var card_type_filter: String = ""    # If set, only affects this card type

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add hold bonus data to results for the combat system to process
	if not results.has("hold_bonus"):
		results.hold_bonus = []
	
	results.hold_bonus.append({
		"turns_required": turns_required,
		"bonus_damage": bonus_damage,
		"bonus_defense": bonus_defense,
		"bonus_healing": bonus_healing,
		"bonus_energy": bonus_energy,
		"card_type_filter": card_type_filter
	})
	
	print("Applied %s effect from %s (%d turns for bonuses)" % [get_effect_name(), card_data.card_name, turns_required])

func get_formatted_description() -> String:
	var bonuses: Array[String] = []
	
	if bonus_damage > 0:
		bonuses.append("+%d damage" % bonus_damage)
	if bonus_defense > 0:
		bonuses.append("+%d block" % bonus_defense)
	if bonus_healing > 0:
		bonuses.append("heal %d" % bonus_healing)
	if bonus_energy > 0:
		bonuses.append("+%d energy" % bonus_energy)
	
	if bonuses.is_empty():
		return "HOLD %d: No bonuses configured" % turns_required
	
	var bonus_text = ", ".join(bonuses)
	var filter_text = ""
	
	if card_type_filter != "":
		filter_text = " (%s cards only)" % card_type_filter
	
	return "HOLD %d: %s%s" % [turns_required, bonus_text, filter_text]

func get_effect_name() -> String:
	return EFFECT_NAME