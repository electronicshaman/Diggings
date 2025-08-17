extends CardEffect
class_name EnemyDebuff

const EFFECT_NAME := "Enemy Debuff"

# Enemy Debuff Effect - Apply negative effects to enemy
# Theme-agnostic: weaken, distract, confuse, intimidate, etc.

@export var damage_reduction: int = 0        # Reduce enemy damage by this amount
@export var defense_reduction: int = 0       # Reduce enemy defense by this amount
@export var duration: int = 1                # How many turns the debuff lasts
@export var debuff_type: String = "weaken"   # Type of debuff for flavor

func _init() -> void:
	pass

func apply_effect(_duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	# Add enemy debuff to results
	if not results.has("enemy_debuff"):
		results.enemy_debuff = []
	
	results.enemy_debuff.append({
		"damage_reduction": damage_reduction,
		"defense_reduction": defense_reduction,
		"duration": duration,
		"debuff_type": debuff_type
	})
	
	print("Applied %s effect from %s (%s for %d turns)" % [get_effect_name(), card_data.card_name, debuff_type, duration])

func get_formatted_description() -> String:
	var effects: Array[String] = []
	
	if damage_reduction > 0:
		effects.append("deals -%d damage" % damage_reduction)
	if defense_reduction > 0:
		effects.append("gains -%d block" % defense_reduction)
	
	if effects.is_empty():
		return "DEBUFF: No effects configured"
	
	var effect_text = ", ".join(effects)
	var duration_text = ""
	if duration == 1:
		duration_text = "next turn"
	else:
		duration_text = "next %d turns" % duration
	
	return "Enemy %s for %s" % [effect_text, duration_text]

func get_effect_name() -> String:
	return EFFECT_NAME