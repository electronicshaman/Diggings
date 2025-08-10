extends CardEffect
class_name MissingHealthDamage

# Missing Health Damage - Power that feeds on suffering
# Two modes: accumulated wounds vs fresh blood

enum DamageMode {
	PERCENTAGE_BASED,  # Based on missing health percentage
	ACCUMULATION_BASED # Based on damage taken this duel
}

@export var damage_mode: DamageMode = DamageMode.PERCENTAGE_BASED
@export var damage_per_10_percent: int = 1    # For WOUNDED_FURY mode
@export var damage_per_5_taken: int = 1       # For ACCUMULATION_BASED mode
@export var minimum_damage: int = 0           # Minimum damage even at full health
@export var maximum_damage: int = 999         # Cap to prevent absurd values

func _init() -> void:
	effect_name = "Missing Health Damage"
	description = get_formatted_description()

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add missing health damage to results
	if not results.has("missing_health_damage"):
		results.missing_health_damage = []
	
	results.missing_health_damage.append({
		"mode": damage_mode,
		"damage_per_10_percent": damage_per_10_percent,
		"damage_per_5_taken": damage_per_5_taken,
		"minimum_damage": minimum_damage,
		"maximum_damage": maximum_damage
	})
	
	var card_resource: CardData = card_data as CardData
	print("Applied %s effect from %s (mode: %s)" % [effect_name, card_resource.card_name, DamageMode.keys()[damage_mode]])

func get_formatted_description() -> String:
	match damage_mode:
		DamageMode.PERCENTAGE_BASED:
			var desc: String = "Deal %d damage per 10%% health missing" % damage_per_10_percent
			if minimum_damage > 0:
				desc += " (minimum %d)" % minimum_damage
			return desc
		DamageMode.ACCUMULATION_BASED:
			var desc: String = "Deal %d damage per 5 damage taken this duel" % damage_per_5_taken
			if minimum_damage > 0:
				desc += " (minimum %d)" % minimum_damage
			return desc
		_:
			return "Deal damage based on wounds"

# Static helper function for calculating damage
static func calculate_missing_health_damage(player_data: PlayerData, params: Dictionary) -> int:
	var mode: DamageMode = params.get("mode", DamageMode.PERCENTAGE_BASED)
	var min_damage: int = params.get("minimum_damage", 0)
	var max_damage: int = params.get("maximum_damage", 999)
	var calculated_damage: int = 0
	
	match mode:
		DamageMode.PERCENTAGE_BASED:
			var dmg_per_10_percent: int = params.get("damage_per_10_percent", 1)
			var missing_percent: float = player_data.get_missing_health_percentage()
			var ten_percent_chunks: int = int(missing_percent * 10)  # Convert to chunks of 10%
			calculated_damage = ten_percent_chunks * dmg_per_10_percent
		DamageMode.ACCUMULATION_BASED:
			var dmg_per_5_taken: int = params.get("damage_per_5_taken", 1)
			var damage_taken: int = player_data.get_damage_taken_this_duel()
			var five_damage_chunks: int = roundi(damage_taken / 5.0)  # Convert to chunks of 5 damage
			calculated_damage = five_damage_chunks * dmg_per_5_taken
	
	# Apply minimum and maximum bounds
	calculated_damage = max(min_damage, calculated_damage)
	calculated_damage = min(max_damage, calculated_damage)
	
	return calculated_damage