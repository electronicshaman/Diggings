extends CardEffect
class_name ConditionalDefense

const EFFECT_NAME := "Conditional Defense"

@export var base_defense: int = 6
@export var bonus_defense: int = 2
@export var health_threshold: float = 0.5  # 50% health

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_defense = base_defense
	
	# Check player health percentage
	if duel_manager and duel_manager.has_method("get_player_health_percentage"):
		var health_percentage = duel_manager.get_player_health_percentage()
		
		if health_percentage <= health_threshold:
			total_defense += bonus_defense
			print("Outlaw's desperation! Low health bonus applied.")
			
			# Add notification for the bonus
			if "notifications" in results:
				results.notifications.append("Desperate Defense! +%d bonus Block" % bonus_defense)
			else:
				results.notifications = ["Desperate Defense! +%d bonus Block" % bonus_defense]
	
	# Add defense to results
	results.defense += total_defense
	print("Applied %s effect from %s (+%d defense, total: %d)" % [get_effect_name(), card_data.card_name, total_defense, results.defense])

func get_formatted_description() -> String:
	return "Gain %d Block. If health below %d%%, gain +%d Block." % [base_defense, int(health_threshold * 100), bonus_defense]

func get_effect_name() -> String:
	return EFFECT_NAME