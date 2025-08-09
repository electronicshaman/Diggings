extends CardEffect
class_name MultiHitDamage

@export var damage_per_hit: int = 3
@export var hit_count: int = 3
@export var ignores_defense: bool = false

func _init() -> void:
	effect_name = "Multi-Hit Damage"
	description = "Deal %d damage %d times" % [damage_per_hit, hit_count]

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_damage = damage_per_hit * hit_count
	
	# Add damage to results (total damage for all hits)
	results.damage += total_damage
	
	# Store hit information for animation purposes
	if not "multi_hits" in results:
		results.multi_hits = []
	
	results.multi_hits.append({
		"damage_per_hit": damage_per_hit,
		"hit_count": hit_count,
		"total": total_damage
	})
	
	# Set ignore defense flag if applicable
	if ignores_defense:
		results.ignores_defense = true
	
	var defense_text: String = " (ignores defense)" if ignores_defense else ""
	print("Applied %s effect from %s (%d damage x %d hits = %d total%s)" % [
		effect_name, card_data.card_name, damage_per_hit, hit_count, total_damage, defense_text
	])
	
	# Add notification for multi-hit
	if "notifications" in results:
		results.notifications.append("Rapid fire! %d hits!" % hit_count)
	else:
		results.notifications = ["Rapid fire! %d hits!" % hit_count]

func get_formatted_description() -> String:
	var base_text: String = "Deal %d damage %d times" % [damage_per_hit, hit_count]
	if ignores_defense:
		base_text += " (ignores defense)"
	return base_text