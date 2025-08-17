extends CardEffect
class_name ConditionalDamage

const EFFECT_NAME := "Conditional Damage"

# Conditional Damage - Deal damage with bonus based on a condition
@export var base_damage: int = 6
@export var bonus_damage: int = 3
@export var condition_type: String = "player_gold"  # player_gold, player_health, enemy_health, etc.
@export var condition_value: int = 20  # Threshold for condition (e.g., 20+ gold)
@export var condition_operator: String = ">="  # >=, <=, ==, !=, >, <

func _init() -> void:
	pass

func apply_effect(duel_manager: Node, card_data: Resource, results: Dictionary) -> void:
	var total_damage = base_damage
	var condition_met = false
	
	# Check condition based on type
	if duel_manager:
		match condition_type:
			"player_gold":
				if duel_manager.has_method("get_player_gold"):
					var gold = duel_manager.get_player_gold()
					condition_met = _check_condition(gold, condition_value, condition_operator)
			"player_health":
				if duel_manager.has_method("get_player_health"):
					var health = duel_manager.get_player_health()
					condition_met = _check_condition(health, condition_value, condition_operator)
			"enemy_health":
				if duel_manager.has_method("get_enemy_health"):
					var health = duel_manager.get_enemy_health()
					condition_met = _check_condition(health, condition_value, condition_operator)
	
	if condition_met:
		total_damage += bonus_damage
		print("Condition met! Bonus damage applied.")
		
		# Add notification for the bonus
		if "notifications" in results:
			results.notifications.append("Bonus! +%d damage" % bonus_damage)
		else:
			results.notifications = ["Bonus! +%d damage" % bonus_damage]
	
	# Add damage to results
	if not results.has("damage"):
		results.damage = 0
	results.damage += total_damage
	
	print("Applied %s effect from %s: %d damage" % [get_effect_name(), card_data.card_name, total_damage])

func _check_condition(value: int, threshold: int, operator: String) -> bool:
	match operator:
		">=":
			return value >= threshold
		"<=":
			return value <= threshold
		"==":
			return value == threshold
		"!=":
			return value != threshold
		">":
			return value > threshold
		"<":
			return value < threshold
		_:
			return false

func get_formatted_description() -> String:
	var condition_text: String
	
	match condition_type:
		"player_gold":
			match condition_operator:
				">=":
					condition_text = "If you have %d+ Gold" % condition_value
				">":
					condition_text = "If you have more than %d Gold" % condition_value
				_:
					condition_text = "If Gold %s %d" % [condition_operator, condition_value]
		"player_health":
			match condition_operator:
				"<=":
					condition_text = "If Health %d or less" % condition_value
				">=":
					condition_text = "If Health %d or more" % condition_value
				_:
					condition_text = "If Health %s %d" % [condition_operator, condition_value]
		"enemy_health":
			match condition_operator:
				"<=":
					condition_text = "If enemy Health %d or less" % condition_value
				">=":
					condition_text = "If enemy Health %d or more" % condition_value
				_:
					condition_text = "If enemy Health %s %d" % [condition_operator, condition_value]
		_:
			condition_text = "If condition met"
	
	return "Deal %d damage. %s, deal %d additional damage" % [base_damage, condition_text, bonus_damage]

func get_effect_name() -> String:
	return EFFECT_NAME