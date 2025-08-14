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
	# Legacy method - call with basic data
	_apply_hold_bonus_logic(card_data.card_name, 0, results)

func apply_effect_with_instance(_duel_manager: Node, card_instance: CardInstance, results: Dictionary) -> void:
	# New method that uses actual turns held from CardInstance
	_apply_hold_bonus_logic(card_instance.get_card_name(), card_instance.turns_held, results)

func _apply_hold_bonus_logic(card_name: String, turns_held: int, results: Dictionary) -> void:
	# Only apply bonuses if the hold requirement is met
	if turns_held >= turns_required:
		# Apply the actual bonuses to results
		if bonus_damage > 0:
			results.damage = results.get("damage", 0) + bonus_damage
		
		if bonus_defense > 0:
			results.defense = results.get("defense", 0) + bonus_defense
		
		if bonus_healing > 0:
			results.healing = results.get("healing", 0) + bonus_healing
		
		if bonus_energy > 0:
			results.energy = results.get("energy", 0) + bonus_energy
		
		GLog.info("Applied Hold bonus to %s: held %d/%d turns" % [card_name, turns_held, turns_required])
	else:
		GLog.debug("Hold bonus not active for %s: held %d/%d turns" % [card_name, turns_held, turns_required])
	
	# Also add hold bonus data for UI/display purposes
	if not results.has("hold_bonus"):
		results.hold_bonus = []
	
	results.hold_bonus.append({
		"turns_required": turns_required,
		"turns_held": turns_held,
		"bonus_active": turns_held >= turns_required,
		"bonus_damage": bonus_damage,
		"bonus_defense": bonus_defense,
		"bonus_healing": bonus_healing,
		"bonus_energy": bonus_energy,
		"card_type_filter": card_type_filter
	})

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