extends CardEffect
class_name EnemyMissingHealthDamage

const EFFECT_NAME := "Enemy Missing Health Damage"

# Enemy Missing Health Damage - Deal damage equal to enemy's wounds
# "The deeper the wound, the deadlier the strike"

@export var damage_multiplier: float = 1.0  # Multiplier for missing health (usually 1.0)
@export var minimum_damage: int = 0         # Minimum damage even at full health
@export var maximum_damage: int = 999       # Cap to prevent absurd values


func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add enemy missing health damage to results
	if not results.has("enemy_missing_health_damage"):
		results.enemy_missing_health_damage = []
	
	results.enemy_missing_health_damage.append({
		"damage_multiplier": damage_multiplier,
		"minimum_damage": minimum_damage,
		"maximum_damage": maximum_damage
	})
	
	print("Applied %s effect from %s (multiplier: %.1fx)" % [get_effect_name(), card_data.card_name, damage_multiplier])

func get_formatted_description() -> String:
	var base_text: String = "Deal damage equal to enemy's missing health"
	
	if damage_multiplier != 1.0:
		base_text = "Deal damage equal to %.1fx enemy's missing health" % damage_multiplier
	
	if minimum_damage > 0:
		base_text += " (minimum %d)" % minimum_damage
	
	return base_text

func get_effect_name() -> String:
	return EFFECT_NAME

# Static helper function for calculating damage
static func calculate_enemy_missing_health_damage(enemy: EnemyState, params: Dictionary) -> int:
	if not enemy or not enemy.is_alive():
		return 0
	
	var multiplier: float = params.get("damage_multiplier", 1.0)
	var min_damage: int = params.get("minimum_damage", 0)
	var max_damage: int = params.get("maximum_damage", 999)
	
	# Calculate missing health
	var missing_health: int = enemy.max_health - enemy.current_health
	var calculated_damage: int = int(missing_health * multiplier)
	
	# Apply minimum and maximum bounds
	calculated_damage = max(min_damage, calculated_damage)
	calculated_damage = min(max_damage, calculated_damage)
	
	return calculated_damage